# Étape 3 — Système de combat

> Toutes les valeurs numériques sont des **valeurs de départ** : elles vivent dans des fichiers de données
> (`data/*.json`) pour être équilibrées sans toucher au code.

## 1. Arène

### 1.1 Espace logique
- Terrain logique 2D : **9 m de large × 16 m de long**. L'écoulement va du bas (joueur) vers le haut (ennemi).
- Rendu : caméra **2.5D isométrique / ¾** au-dessus de l'espace logique. La simulation reste en 2D pure.
- Disposition (de bas en haut) :

```
 ┌─────────────────────────┐  y=16  NEXUS ennemi (ou Boss)
 │   [Tour]  NEXUS  [Tour] │
 │  ▲ générateurs ennemis  │  zone ennemie
 │   ═══ portails ═══      │  y≈11
 │                         │  zone neutre (mêlée)
 │   ═══ portails ═══      │  y≈5
 │ ─────── BARRIÈRE ────── │  y=1   PV du joueur
 │  [Bot G] [JOUEUR] [Bot D]│  y=0   lanceurs
 └─────────────────────────┘
```

### 1.2 Orientation
- La logique est identique en **portrait** et en **paysage** : le flux va toujours du bas vers le haut.
- **Paysage** : l'arène reste centrée et des panneaux latéraux s'ajoutent :
  - gauche : état des bots et ordres ;
  - droite : sorts, Échos actifs, journal de combat ;
  - en haut à droite : mini-carte.
- **Portrait** : HUD compact. Les sorts sont en bas, la jauge Surge et les PV du Nexus en haut, les bots en médaillons.

## 2. Lanceurs

| Lanceur | Position | Déplacement |
|---|---|---|
| Joueur | Centre | Glisse horizontalement sur toute la largeur |
| Bot gauche | x ∈ [0 ; 4] | IA, limité à son tiers + 15 % de chevauchement |
| Bot droit | x ∈ [5 ; 9] | Idem |

Un mode **solo** (sans bots) est jouable et récompensé : **+25 % d'XP**, mais la difficulté est plus élevée.

### 2.1 Les trois ressources
| Ressource | Rôle | Valeurs de base |
|---|---|---|
| **Flux** | Tir continu tant que le doigt est posé, **gratuit** : le tir propre à la classe (troupes ou projectiles, voir [42-tirs-de-classe.md](42-tirs-de-classe.md)) | Cadence propre à chaque classe (0,15 à 0,8 s) ; accélérée par la Célérité et les améliorations |
| **Mana** | Sert à lancer les sorts actifs | Max 100, régénération 4/s |
| **Charge du Champion** | Se remplit pendant le tir, au rythme de 4 par seconde, quelle que soit la classe | 40 → 1 Champion |
| **Jauge Surge** | Se remplit grâce aux kills | 1 par kill, 5 par élite, 20 par mini-boss ; 100 = ultime |

## 3. Unités

### 3.1 Statistiques
`PV`, `ATQ`, `DÉF`, `VIT` (m/s), `rayon`, `élément`, `poids` (dégâts infligés à la Barrière ou au Nexus), `tags`.

### 3.2 Unités alliées
| Unité | PV | ATQ | DÉF | VIT | Poids | Note |
|---|---|---|---|---|---|---|
| Familier (de base, apparence selon la classe) | 10 | 10 | 0 | 2,5 | 1 | Échange 1 contre 1 avec un sbire |
| Champion (selon la classe) | 150 | 40 | 20 | 1,8 | 15 | Voir §8 |
| Élite fusionnée | ×10 du familier | ×10 | 5 | 2,2 | 10 | Voir §4.3 |

### 3.3 Résolution du contact
1. Un contact allié/ennemi déclenche un échange de coups **simultané**, à chaque tick de simulation.
2. Les unités dont les PV tombent à 0 ou moins meurent. Les deux camps peuvent mourir sur le même tick.
3. Une unité qui atteint le **Nexus** inflige `ATQ × multiplicateurs` puis disparaît.
4. Un ennemi qui atteint la **Barrière** lui retire autant de PV que son `poids`, puis disparaît.

## 4. Portails runiques

### 4.1 Règles
- Chaque unité ne traverse **qu'une fois** un même portail. Elle garde la liste des identifiants déjà traversés, et ses clones en héritent, ce qui empêche les boucles infinies.
- Un portail peut être **fixe**, **mobile** (il glisse de gauche à droite) ou **temporaire** (il apparaît pendant N secondes).
- On peut empiler plusieurs portails en rangée verticale pour enchaîner les effets.

### 4.2 Catalogue
| Famille | Portail | Effet |
|---|---|---|
| Nombre | `+5`, `+10` | Ajoute N unités derrière le portail, puis se recharge 1,5 s |
| Nombre | `×2`, `×3` (rare) | Clone chaque unité |
| Élément | Feu / Givre / Foudre / Nature / Lumière / Ombre | Donne cet élément à l'unité (remplace le précédent) |
| Renfort | Puissance | +50 % ATQ |
| Renfort | Géant | +100 % PV, taille ×1,3, −20 % VIT |
| Renfort | Hâte | +40 % VIT |
| Renfort | Égide | Bouclier de 10 PV |
| Négatif (posé par l'ennemi) | `−5`, `÷2` | `−N` absorbe N unités puis se recharge 4 s · `÷N` détruit une unité sur N |
| Négatif | Corruption | 20 % des unités qui passent deviennent ennemies |
| Négatif | Entrave | −50 % VIT pendant 3 s |

Les portails négatifs se **purifient** avec un sort de type Portail (§7) ou un élément Lumière.

### 4.3 Plafond d'unités et Fusion arcanique
- Plafonds à l'écran : **300 unités alliées**, **200 ennemies**, **400 projectiles**.
- Au-delà du plafond, **10 familiers fusionnent en 1 élite fusionnée**, avec un effet visuel de vortex.
- Ce mécanisme garde les performances stables et rend un bon jeu toujours payant.

## 5. Dégâts

### 5.1 Formule
```
DÉF_eff  = max(0, DÉF × (1 − pénétration))
Dégâts   = ATQ × (1 + Σbonus%) × mult_élément × mult_crit × 100 / (100 + DÉF_eff)
mult_crit: ×1,5 si critique (chance de base 5 %)
```

### 5.2 Affinités élémentaires
Cycle principal : **Feu → Nature → Foudre → Givre → Feu** (chaque élément bat le suivant).
- Contre l'élément qu'il bat : ×1,5. Contre l'élément qui le bat : ×0,75.
- **Lumière ⇄ Ombre** : ×1,5 dans les deux sens.
- **Physique** : ×1 contre tout. Certains ennemis blindés résistent au physique (×0,5).

### 5.3 Effets d'état
| Élément | Effet | Valeur de base |
|---|---|---|
| Feu | Brûlure | 3 % des PV max/s pendant 3 s |
| Givre | Ralentissement −15 % par cumul ; à 3 cumuls, gel total 1,5 s | |
| Foudre | Chaîne | Rebondit sur 2 cibles proches à 50 % des dégâts |
| Nature | Poison | 2 % des PV max/s, cumulable 5 fois |
| Lumière | Rayonnement | Soigne les alliés proches à hauteur de 5 % des dégâts infligés |
| Ombre | Drain | Vol de vie 10 % ; un ennemi tué a 5 % de chance de revenir en squelette allié |

## 6. Ennemis en combat

### 6.1 Structures
| Structure | Rôle |
|---|---|
| **Nexus** | Objectif : le détruire = victoire. Pulsation défensive toutes les 2,5 s contre les unités qui l'assiègent |
| **Tour de garde** | Tire sur les unités proches ; la détruire donne un bonus de Surge |
| **Générateur** | Produit les vagues ; le détruire réduit la pression ennemie |

### 6.2 Archétypes d'ennemis
Archétypes communs à toutes les catégories (bêtes, morts-vivants…) ; seuls l'apparence et l'élément changent.

| Archétype | Coût budget | Profil |
|---|---|---|
| Sbire | 1 | Stats de base (PV 10, ATQ 10) |
| Coureur | 2 | VIT ×1,8, PV ×0,6 |
| Brute | 5 | PV ×6, ATQ ×2, poids 5 |
| Tireur | 3 | Attaque à distance (portée 3 m) |
| Porte-bouclier | 4 | Bloque 80 % des dégâts venant de face |
| Lanceur de sorts | 6 | Attaque de zone et pose des portails négatifs |
| Soigneur | 5 | Soigne les unités ennemies et le **Nexus ennemi** |
| Élite | ×3 coût | Stats ×3 + 1 affixe |

**Affixes d'élite** :
- Blindé : DÉF +50.
- Rapide.
- Vampirique.
- Explosif : dégâts de zone à sa mort.
- Invocateur : produit 3 sbires.
- Réfléchissant : renvoie 20 % des dégâts.
- Élémentaire : immunisé à un élément.

### 6.3 Vagues
- **Budget de vague** = `20 + 6 × niveau_local`, dépensé selon la composition propre à chaque zone.
- Une vague toutes les 8 à 12 s, avec des pics de pression scriptés par niveau.

## 7. Sorts actifs

### 7.1 Deck
- **4 emplacements**, choisis avant la partie dans la Bibliothèque. Le Chevalier et l'Épéiste peuvent en équiper 3 + 1 « Technique ».
- Chaque sort a un coût en mana (20 à 60) et un temps de recharge (6 à 30 s).
- Ciblage : on touche le sort puis la zone visée, ou on glisse-relâche depuis le bouton. Sur PC : touches `1`–`4` + souris.

### 7.2 Catégories
| Catégorie | Exemples |
|---|---|
| Offensif | Boule de feu (zone), Lance de foudre (ligne), Pluie de givre (zone + ralentissement) |
| Contrôle | Racines (immobilise 2 s), Vortex (aspire les ennemis), Silence (bloque les lanceurs ennemis) |
| Soutien | Bénédiction (+30 % ATQ des alliés 5 s), Soin de Barrière (+15 PV), Égide de masse |
| Invocation | Meute de loups (6 unités rapides), Golem (1 tank), Essaim de lucioles |
| **Portail** (mécanique propre au jeu) | Purifier (rend un portail positif), Créer un portail ×2 (8 s), Déplacer un portail, Surcharger (+1 au multiplicateur pendant 6 s) |

### 7.3 Échos (choix pendant la partie)
- Les Échos se déclenchent à **66 % et 33 % des PV du Nexus**, et à chaque phase de boss.
- Le jeu passe au ralenti et propose **3 Échos au hasard**. Le joueur en choisit 1, actif jusqu'à la fin de la partie.
- La rareté des Échos proposés dépend de la zone.

| Exemple d'Écho | Effet |
|---|---|
| Résonance | Tous les portails « Nombre » donnent +1 |
| Cendres vives | Les unités de Feu explosent à leur mort |
| Flux torrentiel | Cadence +25 % |
| Pacte d'ombre | Mana −50 % de coût, mais la Barrière perd 1 PV par sort lancé |
| Écho jumeau | Le prochain Champion apparaît en double |
| Bastion | +30 PV de Barrière |

## 8. Classes en combat

| Classe | Passif | Champion | Ultime Surge |
|---|---|---|---|
| Archer | 15 % des unités tirent une flèche à 3 m | Sentinelle sylvestre (tir sur 3 cibles) | **Pluie d'étoiles** : barrage sur toute l'arène, 3 s |
| Épéiste | Critiques +10 % | Maître-lame (tourbillon) | **Mille lames** : unités +100 % VIT et ATQ, 6 s |
| Mage | Effets élémentaires +25 % | Golem élémentaire (élément du dernier portail traversé) | **Météore arcanique** : grosse zone + brûlure |
| Clerc | Unités régénèrent 2 % de leurs PV/s | Ange gardien (aura de soin) | **Sanctuaire** : Barrière invulnérable 5 s + soin 30 % |
| Nécromancien | 10 % des ennemis tués reviennent en squelettes alliés | Chevalier-liche (chaque kill relève un allié) | **Armée des morts** : tout ennemi tué pendant 8 s se relève allié |
| Chevalier | Unités DÉF +20 % | Paladin colosse (provoque les ennemis, PV ×8) | **Mur de boucliers** : bloque la largeur de l'arène 6 s et repousse |
| Berserker | ATQ +1 % pour 1 % de PV de Barrière manquants (max 50 %) | Titan furieux (grandit à chaque kill) | **Rage sanguinaire** : ATQ ×2, vol de vie 20 %, 6 s |

Les races ajoutent des modificateurs (étape 4).

## 9. Bots (IA)

### 9.1 Décision (IA par utilité, réévaluée toutes les 0,25 à 0,6 s selon le niveau du bot)
Le bot donne un score à chaque position X possible et vise la meilleure :
```
score(x) = w_portail × valeur_portails(x)
         + w_défense × menace_ennemie(x)        // densité ennemie près de la Barrière
         + w_nexus   × accès_nexus(x)
         − w_conflit × chevauchement_joueur(x)  // évite de doubler le joueur
```

### 9.2 Personnalités (préréglages des poids)
| Personnalité | Comportement |
|---|---|
| Équilibré | Poids moyens |
| Agressif | Privilégie le Nexus et les multiplicateurs |
| Défensif | Protège la Barrière et garde le mana pour soigner ou contrôler |
| Opportuniste | Cherche les portails ×N et les Échos de synergie |

### 9.3 Sorts des bots
Règles conditionnelles, configurables plus tard dans l'interface :
- Soin si la Barrière est sous 50 %.
- Sort de zone si plus de 8 ennemis se trouvent dans un rayon de 2 m.
- Purification si un portail négatif est sur sa trajectoire.
- Ultime dès que la jauge est pleine, en même temps que le pic de vague.

### 9.4 Ordres du joueur
Le joueur touche le médaillon d'un bot pour lui donner un ordre :
- **Focus Nexus** : attaque le Nexus.
- **Défends** : protège la Barrière.
- **Suis-moi** : vise la même position X que le joueur (décalée).
- **Libre** : le bot décide seul.

### 9.5 Progression des bots
Plus le bot monte de niveau, plus il réagit vite (de 0,6 à 0,2 s) et vise juste (erreur de ±1,2 m à ±0,2 m). Ses stats viennent de son propre équipement.

## 10. Conditions de fin

| Issue | Condition |
|---|---|
| Victoire | Nexus (ou boss) détruit |
| Défaite | Barrière à 0 PV (100 PV de base, améliorable) |
| Abandon | Bouton pause → Quitter (aucune récompense) |

### 10.1 Soins des Nexus
Les deux camps peuvent soigner leur cœur. L'efficacité dépend du **lanceur**.
- **Barrière (Nexus allié)** : soignée par les sorts de soin du joueur ou des bots, le Clerc et certaines races (Fée).
  - `Soin = puissance_soin_lanceur × mult_classe × (1 + bonus%)`.
  - `mult_classe` : Clerc ×1,5, Chevalier et Nécromancien ×0,75 (soin par sacrifice d'unités), autres ×1.
- **Nexus ennemi** : soigné par les Soigneurs ennemis (§6.2) et certains boss.
  - Les Soigneurs deviennent des cibles prioritaires, et les bots les visent en priorité.
- **Flétrissure (anti-soin)** : effet Ombre, le Nécromancien et certains sorts. Réduit de 50 % les soins reçus pendant 5 s. Elle s'applique aussi au Nexus ennemi.
- Sans limite de temps, une partie peut durer longtemps si l'ennemi soigne plus vite qu'on ne frappe. Le joueur dispose de trois contre-mesures : la Flétrissure, le focus des Soigneurs et les Échos.

**Étoiles** :
- ★ victoire ;
- ★★ victoire avec la Barrière au-dessus de 50 % ;
- ★★★ victoire avec la Barrière au-dessus de 50 % et un temps inférieur au temps de référence.

## 11. Durée et difficulté

### 11.1 Calibrage de la durée
- **Temps de référence** : 2 min 30 pour un niveau standard, 5 min 30 pour un boss de zone, 8 à 10 min pour un boss extrême.
- PV du Nexus = `DPS_attendu × temps_de_référence`, avec `DPS_attendu` calculé pour la **puissance recommandée** du niveau.
- Exemple, niveau 1 : 4 unités/s × multiplicateur moyen 2,5 × 50 % de survie × 10 ATQ = 50 DPS → **Nexus de 7 500 PV**.
- **Aucune limite de temps** et **aucune défaite liée au temps**. Une partie dure jusqu'à la victoire ou jusqu'à la chute de la Barrière.
- Les étoiles (§10) restent la seule récompense de la vitesse.

### 11.2 Montée en difficulté
```
M(L) = 1,045^(L−1)          // multiplicateur des stats ennemies, L = niveau global 1–100 (≈ ×78 au niveau 100)
Boss de zone     : PV ×6,  stats ×1,3
Mini-boss        : PV ×3,  stats ×1,15
Puissance recommandée(L) = 100 × M(L)
```
Écart avec la puissance du joueur :
- sous 80 % de la puissance recommandée : avertissement ;
- au-dessus de 120 % : bonus de vitesse de partie, mais pas de loot supplémentaire, pour éviter le farm abusif.

## 12. Boss

- **3 phases**, à 100 %, 66 % et 33 % de PV. Chaque changement de phase déclenche un choix d'Écho.
- Toutes les attaques de zone sont **annoncées au moins 1,2 s à l'avance** par un signal visuel.
- Répertoire de mécaniques (chaque boss en combine 3 ou 4) :
  - Balayage de ligne (le joueur esquive en se déplaçant).
  - Bouclier élémentaire (il faut l'élément opposé pour le briser).
  - Corruption de portails.
  - Invocation de vague d'élites.
  - Ancrage : un lanceur est immobilisé 3 s.
  - Phase de bascule : l'arène se retourne et les portails changent de côté.

## 13. Contrôles

| Action | Tactile | PC |
|---|---|---|
| Se déplacer | Glisser horizontalement | Souris X ou `A`/`D` |
| Flux | Maintenir le doigt (tir automatique possible en accessibilité) | Clic gauche maintenu |
| Sort | Toucher le bouton puis la zone | `1`–`4` |
| Champion | Bouton | `E` |
| Ultime | Bouton (quand la jauge est pleine) | `Espace` |
| Ordre aux bots | Toucher le médaillon | `Q` / `R` |

## 14. Architecture technique du combat

- **Simulation à pas fixe de 30 Hz**, rendu interpolé à 60 fps.
- **Graine aléatoire fixée** au lancement de la partie : rejouable, et prépare une validation anti-triche côté serveur.
- Les unités sont stockées comme **données** (tableaux), pas comme nœuds Godot. Le rendu passe par `MultiMeshInstance2D`, une grille spatiale gère les collisions, et les objets sont réutilisés (pooling).
- Budget de performance : plafonds §4.3, particules GPU, ombres pré-calculées.
- **Cible web d'abord** : export Godot 4.3+ **web mono-thread**, sans SharedArrayBuffer, donc compatible avec **GitHub Pages**. L'export natif iOS/Android viendra plus tard.
- Un **simulateur sans affichage** servira à équilibrer : il joue 1 000 parties automatiques par niveau pour mesurer la durée moyenne et le taux de victoire.
