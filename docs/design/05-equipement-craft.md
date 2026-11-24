# Étape 5 — Équipement, runes, fabrication et loot

> Mise en œuvre de l'étape 13.8 (catalogue de 94 objets, 16 runes, Forge : gravure et fusions) : voir [`35-equipement-runes-forge.md`](35-equipement-runes-forge.md).

> Canon : [`00-lore.md`](00-lore.md) · Valeurs en data : `data/items/*.json`, `runes.json`, `runewords.json`, `recipes.json`, `loot_tables.json`

## 1. Raretés

| Rareté | Couleur | Budget de stats | Affixes | Emplacements de runes | Amélioration max | Particularité |
|---|---|---|---|---|---|---|
| Commun | Gris | ×1,0 | 0 | 0–1 | +5 | — |
| Rare | Bleu | ×1,25 | 1 | 1 | +10 | — |
| Épique | Violet | ×1,55 | 2 | 2 | +15 | — |
| Légendaire | Or | ×1,9 | 3 + 1 effet unique | 3 | +20 | Nom et histoire tirés du lore |
| Mythique | Rouge | ×2,3 | 3 + effet unique | 4 | +25 | Fait partie d'un **ensemble** (bonus à 2 et 4 pièces) |
| Arcanique | Irisé | ×2,8 | 4 + effet unique | 5 | +30 | **Éveil** (§6) ; **2 équipés au maximum** |

**Stat de base d'un objet** = `base_type × M(iLvl) × budget_rareté`.
- `iLvl` est le niveau de la zone où l'objet est tombé.
- `M` est le multiplicateur de difficulté défini à l'étape 3.

## 2. Emplacements (le joueur et chaque bot)

| Groupe | Emplacements |
|---|---|
| Armes | Arme principale · Main secondaire |
| Armure | Tête · Armure · Gants · Bottes |
| Bijoux | Médaillon · Anneau ×2 · Charme (effet actif léger) |
| Autres | 3 emplacements de potions (Laboratoire) · 1 Familier (Ménagerie) |

### 2.1 Armes par classe
**L'élément natif de l'arme devient l'élément par défaut des familiers**, avant même de passer un portail. C'est le lien direct entre l'équipement et le combat.

| Classe | Arme principale | Main secondaire |
|---|---|---|
| Archer | Arc court, arc long, arbalète | Carquois |
| Épéiste | Épée, rapière, lame courbe | Dague |
| Mage | Bâton (2 mains) ou baguette | Orbe |
| Clerc | Masse, sceptre | Bouclier ou relique |
| Nécromancien | Faux (2 mains) ou dague rituelle | Grimoire ou crâne |
| Chevalier | Épée longue, lance | Bouclier |
| Berserker | Hache, marteau (2 mains, ou une arme dans chaque main) | Hache de lancer |

### 2.2 Affixes
Les affixes sont tirés au hasard selon le type d'objet. Liste :
- les 5 stats (POU, VIG, ESP, CÉL, DES) ;
- % de cadence, % de critique, % de dégâts d'un élément, % de soins, régénération de mana ;
- PV de Barrière, réduction des recharges ;
- chance que les portails « Nombre » donnent +1 ;
- % de dégâts contre une catégorie d'ennemis ;
- gain de Surge.

## 3. Salles

### 3.1 Gardiens et déblocage
Chaque salle a un **gardien** relié au lore et se débloque selon l'histoire.

| Salle | Gardien | Déblocage |
|---|---|---|
| **Forge** | Durgan Enclume (nain, descendant des Runistes) | Début de l'acte 1 |
| **Salle d'entraînement** | Sergent Hargo (humain, Bastion d'Argent) | Début de l'acte 1 |
| **Bibliothèque** | Ossian (humain, archiviste) | Début de l'acte 1 |
| **Laboratoire** | Mirelle Fiolebrume (fée alchimiste) | Fin de l'acte 1 |
| **Sanctum arcanique** | Thalren (mage du Collège Arcanique) | Fin de l'acte 1 |
| **Salle de méditation** | Sœur Aelis (Ordre de l'Aube) | Fin de l'acte 1 |
| **Atelier runique** | Ysolde (elfe, héritière des Runistes) | Fin de l'acte 1 pour les runes I–III ; **acte 4** pour les runes IV–V et les mots runiques |
| **Ménagerie** | Kaela (orque pisteuse) | Acte 2 |
| **Observatoire** | Séléné (gardienne du savoir sur le Sceau d'Écho) | Fin de l'acte 2, après le 1er grand choix |
| **Salle de rituel** | La Veuve Cendrée (Cercle des Cendres) | Acte 3 |

### 3.2 Salles d'équipement
| Salle | Fonctions |
|---|---|
| **Forge** | Fabriquer armes et armures (§5.1) · **améliorer** (+N, sans risque d'échec : +4 % de base par niveau, +5 % en bonus à chaque palier de 5) · **reforger** un affixe (le coût augmente à chaque fois) · **démanteler** (rend matériaux et Poussière d'arcane) · **transmuter** (3 objets de même rareté → 1 objet de rareté supérieure ; jusqu'à Légendaire seulement) |
| **Sanctum arcanique** | Armes magiques avancées (bâtons, orbes, grimoires) · **infusion** (change l'élément natif d'une arme) · **Ascension** (objet Légendaire + Fragment mythique → Mythique) · **Éveil** des objets Arcaniques |
| **Laboratoire** | Potions et bonus temporaires (§3.4) · recherche de recettes payée en matériaux, **sans minuteur** |
| **Atelier runique** | Fabrication, fusion, gravure et extraction de runes · registre des mots runiques découverts (§4) |
| **Ménagerie** | Familiers : œufs lâchés par les boss, nourrissage et montée de niveau. Un familier donne 1 passif et 1 petit effet actif. Exemples : Renardeau lumineux, Wyrmelet, Golem de poche, Hibou astral, Salamandre |

### 3.3 Salles de capacités
Chaque sort a une **affinité**. Elle indique la salle où le sort franchit ses paliers, aux niveaux 3, 6 et 9.

| Salle | Affinité | Fonctions |
|---|---|---|
| **Salle d'entraînement** | Élémentaire et martiale | Tester sorts et configurations sur des mannequins et des scénarios · un peu d'XP (plafonnée par jour) · tutoriel de chaque classe |
| **Salle de rituel** | Sombre (Ombre, sacrifice, malédiction) | Améliorations puissantes avec un **prix** : sacrifier des objets ou accepter un malus sur la partie suivante. Chaque rituel augmente la **Corruption**, un fil du destin qui pousse l'histoire vers la voie des Cendres |
| **Salle de méditation** | Stable (Lumière, soin, bouclier, renforcement) | Améliorations sûres · **réinitialisation des arbres** · **Harmonie** : fait baisser la Corruption |
| **Bibliothèque** | Toutes | Apprendre des sorts grâce aux parchemins · gérer le deck de 4 sorts · **Grimoire de création** (§5.2) · **Codex** : bestiaire, histoire, pierres gravées (indices de mots runiques) |
| **Observatoire** | Surge et Portail | Modifier les Ultimes · codex des Échos (débloquer de nouveaux Échos) · **Carte des fils du destin** : arbre des choix passés, d'où se lance **« Changer le futur »** |

- **Niveaux de sort** : de 1 à 10. Un sort gagne de l'XP quand on l'utilise, en partie comme à l'entraînement.
- **Évolutions** : aux niveaux 5 et 10, on choisit une évolution parmi 2. Exemple : Boule de feu → *Pluie de feu* ou *Boule géante*.

### 3.4 Potions (Laboratoire)
3 emplacements par partie. Une potion se boit pendant la partie ou s'active automatiquement au départ, selon son type.

| Potion | Effet |
|---|---|
| Potion de mana | +50 mana immédiatement |
| Élixir de cadence | Flux +30 % pendant 20 s |
| Fiole de Barrière | +20 PV de Barrière |
| Flacon élémentaire | Élément choisi sur tous les familiers pendant 30 s |
| Huile de traque | +20 % de dégâts contre une catégorie d'ennemis pendant toute la partie (s'active au départ) |
| Tonique de savoir | +25 % d'XP sur la partie (s'active au départ) |

Il existe 3 qualités de potion : Mineure, Majeure, Suprême. Leurs ingrédients viennent de zones différentes.

## 4. Runes

### 4.1 Familles
Les runes vont du **tier I au tier V**. Fusionner 3 runes identiques donne 1 rune du tier au-dessus. Une même rune a un effet différent selon l'objet sur lequel on la grave.

| Rune | Sur une arme | Sur une armure ou un bouclier | Sur un bijou |
|---|---|---|---|
| **Kaor** (Puissance) | +ATQ % | +POU | +dégâts des sorts % |
| **Vigr** (Vigueur) | +PV des unités % | +PV de Barrière | +VIG |
| **Ilm** (Esprit) | +dégâts des sorts % | +régénération de mana | +mana max |
| **Sael** (Célérité) | +cadence % | +vitesse des unités | −recharges % |
| **Wyrd** (Destin) | +critique % | +esquive des unités | +chance de loot rare |
| **Pyr / Isa / Thun / Ver / Lux / Nox** (Feu, Givre, Foudre, Nature, Lumière, Ombre) | Ajoute des dégâts de l'élément | Résistance à l'élément | Effet d'état de l'élément +% |
| **Mor** (Vie) | Vol de vie | Régénération des unités | Soins +% |
| **Gard** (Garde) | Bouclier sur les familiers | DÉF +% | Bouclier de Barrière au départ |
| **Mult** (Multiplicité) | Chance de portail +1 | Chance de clone gratuit | Gain de Surge +% |

- **Gravure** : coûte de l'or.
- **Extraction** : gratuite si l'on détruit la rune, ou payée en Poudre runique si l'on veut la conserver.

### 4.2 Mots runiques
Certaines runes, gravées **dans un ordre précis** sur un objet qui a **exactement** le bon nombre d'emplacements, débloquent un effet spécial.
- Les recettes sont **cachées**. On les découvre grâce aux pierres gravées dans les niveaux, au Codex et aux dialogues.
- Une fois découvertes, elles apparaissent dans le registre de l'Atelier.

| Mot runique | Objet | Séquence | Effet |
|---|---|---|---|
| Tempête ardente | Arme (3) | Pyr · Thun · Kaor | Chaque brûlure déclenche une chaîne de foudre |
| Moisson | Arme (3) | Nox · Mor · Nox | Chaque kill soigne la Barrière de 0,2 PV |
| Vent du temps | Anneau (2) | Sael · Wyrd | Recharges −15 % |
| Aube éternelle | Armure (3) | Lux · Gard · Ilm | La Barrière régénère 0,5 PV/s |
| Glacier | Bouclier (4) | Isa · Isa · Gard · Vigr | Le 1er ennemi touché de chaque vague est gelé |
| Racines du monde | Armure (4) | Ver · Mor · Vigr · Ver | Familiers +25 % de PV, empoisonnent au contact |
| Fil du destin | Charme (3) | Wyrd · Mult · Wyrd | 10 % de chance qu'un portail Nombre double son effet |
| Équilibre de l'Écho | Arcanique (5) | Lux · Nox · Lux · Nox · Wyrd | Les Échos proposent 4 choix au lieu de 3 |

## 5. Création libre

### 5.1 Armes et armures (Forge, Sanctum)
`Plan` + `Matériau` + `Catalyseur` + `Essence` (facultative)

| Composant | Rôle | Exemples |
|---|---|---|
| Plan | Type d'objet | Plan d'arc long, de bouclier… (trouvés en loot ou achetés) |
| Matériau | Stats de base, **élément natif**, apparence | Fer (physique) · Bois-lune (Lumière) · Obsidienne (Feu) · Givrargent (Givre) · Os-de-liche (Ombre) · Ambre-foudre (Foudre) · Écaille de dragon (Feu, résistant) · Cristal de Surge (aléatoire, puissant) |
| Catalyseur | Rareté minimale et nombre d'affixes | Poussière → Commun · Éclat → Rare · Cœur → Épique · **Relique de boss** → Légendaire |
| Essence | Garantit 1 affixe au choix | Essence de Puissance, d'Esprit… |

- On peut nommer l'objet et choisir sa teinte (cosmétique).
- **Mythique** : obtenu en loot, ou par Ascension. L'**Arcanique** ne s'obtient qu'en loot.

### 5.2 Sorts (Grimoire de création, Bibliothèque)
`Élément` + `Forme` + jusqu'à 2 `Modificateurs` (3 avec un grimoire Légendaire). Les composants sont des **glyphes** qu'on débloque grâce au loot et à l'histoire.

| Forme | Mana de base | Recharge de base |
|---|---|---|
| Projectile | 20 | 6 s |
| Ligne | 25 | 8 s |
| Chaîne | 25 | 8 s |
| Zone | 30 | 10 s |
| Mur | 30 | 14 s |
| Aura (durée) | 35 | 18 s |
| Portail | 35 | 15 s |
| Invocation | 40 | 20 s |

| Modificateur | Effet | Multiplicateur de coût |
|---|---|---|
| Multiple | +1 projectile ou cible | ×1,3 |
| Amplifié | +40 % de dégâts | ×1,4 |
| Persistant | +100 % de durée | ×1,3 |
| Vaste | +50 % de rayon | ×1,35 |
| Rapide | −30 % de recharge | ×1,25 |
| Écho | Se relance à 50 % de puissance après 1 s | ×1,5 |
| Vampirique | Vol de vie de 15 % | ×1,3 |
| Purifiant | Purifie les portails négatifs touchés | ×1,2 |

- `Mana = mana_forme × Π multiplicateurs`. Le **plafond de Complexité** (la somme des multiplicateurs) augmente avec l'Esprit et le niveau.
- Les dégâts suivent la formule de l'étape 3. L'élément ajoute son effet d'état.
- Un sort créé se monte de niveau comme les autres. Son nom est généré automatiquement et modifiable, sa couleur est personnalisable.

## 6. Éveil (objets Arcaniques)
- L'objet accumule de la **Résonance** à chaque partie jouée avec lui.
- Aux paliers 1, 2 et 3, il révèle un effet caché.
- **Lore** : ces objets sont imprégnés du Surge et « se souviennent » de leur porteur.

## 7. Monnaies et matériaux

| Ressource | Source | Usage |
|---|---|---|
| **Or** | Parties, ventes | Amélioration, gravure, réinitialisation, inventaire |
| **Poussière d'arcane** | Démantèlement | Fabrication, reforge |
| **Matériaux de zone** | Ennemis et coffres de la zone | Fabrication, potions |
| **Essences élémentaires** (7) | Élites, boss, démantèlement | Paliers de sorts, infusion |
| **Éclats d'Écho** | Boss, 3 étoiles, succès | Observatoire, Éveil |
| **Gemmes astrales** (premium, plus tard) | Achat, et un peu en jeu (succès) | **Cosmétiques uniquement** : apparences, couleurs de sorts, familiers cosmétiques, cadres. **Rien qui donne un avantage en jeu** |

### 7.1 Matériaux et légendaire de boss par zone

| Zone | Matériaux | Légendaire de boss (exemple) |
|---|---|---|
| 1 Bois des Lucioles | Bois-lune, Luciole séchée | Bâton de la Première Sève |
| 2 Collines d'Ambre | Ambre-foudre, Cuir de steppe | Hache du Serment Brisé |
| 3 Marais Murmurants | Mousse-poison, Os-de-liche | Fiole des Trois Venins (charme) |
| 4 Pics Gelés | Givrargent, Pierre runique | Enclume-Cœur (bouclier) |
| 5 Désert de Verre | Verre-soleil, Sable d'or | Couronne de l'Énigme (tête) |
| 6 Forêt Cendrée | Obsidienne, Écaille de dragon | Écaille-Mère (armure) |
| 7 Cité Engloutie | Nacre abyssale, Encre d'archive | Trident des Archives |
| 8 Terres Brisées | Cristal de Surge, Éclat de réalité | Anneau des Mille Voies |
| 9 Royaume d'Ombre | Argent-lune, Voile d'ombre | Miroir du Porteur (médaillon) |
| 10 Cœur du Surge | Cœur de Surge | **Le Sceau Éclipsé** (Arcanique) |

### 7.2 Ensembles Mythiques (exemples)
Chaque Ordre et chaque compagnon a sa panoplie :
- **Panoplie du Bastion d'Argent** : 2 pièces → DÉF des unités +20 % ; 4 pièces → le Mur de boucliers dure 2 s de plus.
- **Atours du Cercle des Cendres** : 2 pièces → Flétrissure +2 s ; 4 pièces → chaque squelette relevé donne 1 de Surge.

## 8. Loot

### 8.1 Sources
- **Ennemis** : faible chance de drop. Les **élites** ont une chance plus élevée.
- **Mini-boss** : 1 objet Rare ou mieux, garanti.
- **Boss** : 1 objet Épique ou mieux garanti à partir de la zone 2, et une chance d'obtenir son légendaire.
- **Coffres de fin de niveau** : 1 par étoile obtenue.
- **Quêtes de lore, succès, défis.**

### 8.2 Probabilités de rareté par zone (%)

| Zone | Commun | Rare | Épique | Légendaire | Mythique | Arcanique |
|---|---|---|---|---|---|---|
| 1 | 70 | 25 | 5 | 0 | 0 | 0 |
| 2 | 60 | 30 | 9 | 1 | 0 | 0 |
| 3 | 52 | 32 | 13 | 3 | 0 | 0 |
| 4 | 45 | 33 | 16 | 5,5 | 0,5 | 0 |
| 5 | 40 | 34 | 18 | 7 | 1 | 0 |
| 6 | 35 | 35 | 20 | 8,5 | 1,5 | 0 |
| 7 | 30 | 35 | 23 | 9,5 | 2,4 | 0,1 |
| 8 | 26 | 35 | 25 | 10,5 | 3,3 | 0,2 |
| 9 | 23 | 35 | 26 | 11,5 | 4,2 | 0,3 |
| 10 | 20 | 35 | 28 | 12 | 4,5 | 0,5 |

### 8.3 Modificateurs de loot
- **Destin** : chaque point de DES augmente de 0,2 % la probabilité des raretés Épique et au-dessus, en proportion.
- **3 étoiles** : +15 % de chance de rareté sur les coffres.
- **Garantie anti-malchance** (à partir de la zone 3) : 40 objets sans Légendaire → le suivant est garanti Légendaire.
- **Doublons de légendaires uniques** : démantelés en Éclats d'Écho.

### 8.4 Inventaire
- 150 places au départ, agrandissables **avec de l'or** (jamais avec des gemmes).
- Démantèlement automatique configurable par rareté.
- Inventaire partagé entre le joueur et les bots.

## 9. Publicités récompensées (toujours facultatives)

| Offre | Limite |
|---|---|
| Doubler l'or et les matériaux en fin de partie | 1 par partie, 5 par jour |
| Coffre bonus quotidien | 1 par jour |
| Relance de Barrière (+30 %) pendant la partie | 1 par partie, proposée seulement à la défaite |

Aucune pub n'est imposée ni ne s'affiche sans action du joueur. Toutes les offres se désactivent dans les options.
