# Étape 6 — Monde : zones, niveaux, ennemis et boss

> Canon : [`00-lore.md`](00-lore.md) · Archétypes et mécaniques : [`03-combat.md`](03-combat.md) · Données des niveaux : `data/levels/zXX_lYY.json`

## 1. Structure d'une zone (10 niveaux)

| Niveau | Rôle |
|---|---|
| 1 à 4 | Introduction **progressive** de la mécanique de zone et des nouveaux ennemis |
| 5 | **Mini-boss** + temps fort narratif au milieu de l'acte |
| 6 à 9 | Variantes plus dures, nouveaux types de niveau, **choix narratif de l'acte** (niveau 9) |
| 10 | **Boss de zone** + choix majeur (un fil du destin) |

### 1.1 Types de niveau (aucun n'a de limite de temps)
| Type | Objectif |
|---|---|
| Assaut | Détruire le Nexus |
| Siège | Plusieurs Nexus et tours ; il faut tous les détruire |
| Purification | Purifier X portails corrompus pour rendre le Nexus vulnérable |
| Escorte | Protéger un PNJ ou un convoi qui avance jusqu'au Nexus |
| Vagues | Repousser N vagues, comptées en nombre et non en durée, puis vaincre le chef de vague |
| Boss | Voir §4 |

### 1.2 Modes et après-jeu
- **Défis par niveau** (débloqués avec 3 étoiles) : 3 contraintes au choix, par exemple sans bots, un seul élément, Barrière à 50 %. Récompense : Éclats d'Écho.
- **Héroïque** : une zone terminée peut se rejouer à +20 niveaux de difficulté, avec un meilleur loot.
- **Failles du Surge** (après le jeu) : étages générés à l'infini à partir d'éléments de toutes les zones. Classement Supabase, une saison par mois.
- **Variantes du destin** : chaque niveau peut avoir des variantes selon les fils du destin (alliés, ennemis, dialogues, boss). Détails à l'étape 7.

## 2. Zones : identité et mécanique

| # | Zone | Niv. | Dominante ennemie | Éléments | Mécanique de zone |
|---|---|---|---|---|---|
| 1 | Bois des Lucioles | 1–10 | Bêtes corrompues, fées sombres | Nature, Lumière | **Lucioles** : des orbes flottants donnent du mana quand des familiers les traversent |
| 2 | Collines d'Ambre | 10–20 | Humanoïdes (pillards, clans possédés) | Physique, Foudre | **Vent des steppes** : des rafales (annoncées par l'herbe qui ploie) poussent les unités sur le côté · des **pylônes d'ambre** chargent les portails Foudre |
| 3 | Marais Murmurants | 20–30 | Morts-vivants, bêtes des marais | Nature, Ombre | **Brume** : cache une partie de l'arène, la Lumière la dissipe · **mares de poison** qui ralentissent · Soigneurs nombreux |
| 4 | Pics Gelés | 30–40 | Élémentaires de givre, bêtes des montagnes | Givre, Physique | **Glace** : les unités glissent et gardent leur élan · **avalanches** annoncées · **Portes naines** : portails « Forge » qui donnent une armure aux unités |
| 5 | Désert de Verre | 40–50 | Créatures arcaniques, constructions animées | Feu, Lumière | **Cycle soleil/lune** : le jour, le Feu +25 % ; la nuit, le Givre +25 % · **mirages** : faux portails révélés de près · miroirs qui renvoient les projectiles |
| 6 | Forêt Cendrée | 50–60 | Dragons, démons de feu | Feu | **Incendies** : des couloirs de feu qui s'étendent avec le temps · des **dragons** survolent et mitraillent les lignes (annoncé) |
| 7 | Cité Engloutie | 60–70 | Créatures abyssales, reptiliens corrompus | Givre, Foudre | **Marées** : le niveau de l'eau monte et descend, les portails submergés sont désactivés · courants latéraux |
| 8 | Terres Brisées | 70–80 | Créatures arcaniques du chaos | Aléatoire | **Instabilité** : les portails changent de type toutes les 15 s (annoncé 2 s avant) · fragments d'arène qui bougent · anomalies de gravité |
| 9 | Royaume d'Ombre | 80–90 | Démons, morts-vivants d'élite | Ombre | **Ténèbres** : seuls les alentours des unités sont éclairés et les ennemis hors de la lumière sont invisibles ; la Lumière élargit le rayon · portails de Corruption fréquents |
| 10 | Cœur du Surge | 90–100 | Surge pur, échos de toutes les zones | Tous | **Distorsion temporelle** : des **fantômes de vos vagues précédentes** rejouent leur trajet (alliés) · tous les types de portail |

## 3. Bestiaire par zone
Chaque archétype de l'étape 3 a son incarnation propre à la zone.

| Zone | Sbire | Coureur | Brute | Tireur | Porte-bouclier | Lanceur | Soigneur | Mini-boss |
|---|---|---|---|---|---|---|---|---|
| 1 | Champignon sauteur | Lapin-épine | Ours-mousse | Pixie sombre | Tortue-souche | Feu-follet | Dryade flétrie | **Grand Cerf corrompu** |
| 2 | Pillard | Chevaucheur de loup | Ogre d'ambre | Frondeur | Garde de clan | Chaman d'orage | Rebouteux possédé | **Varg, chef pillard** |
| 3 | Zombie des tourbières | Rat de peste | Abomination de vase | Crapaud cracheur | Squelette à pavois | Adepte renégat | Sorcière des brumes | **Crocodile-liche** |
| 4 | Gobelin des glaces | Loup blanc | Yéti | Kobold à stalactites | Golem de glace | Élémentaire de blizzard | Esprit d'aurore | **Sentinelle runique** (naine, corrompue) |
| 5 | Scarabée de verre | Chacal des sables | Golem de grès | Momie archère | Construct-miroir | Spectre du Collège | Prêtresse solaire | **Scorpion de cristal** |
| 6 | Diablotin de braise | Salamandre | Golem de magma | Wyverneau | Drakonide cuirassé | Cultiste du Wyrm | Phénix mineur | **Drake ancien** |
| 7 | Homme-poisson | Anguille-foudre | Crabe titan | Naga archère | Garde de corail | Mage des marées | Sirène | **Kraken juvénile** |
| 8 | Fragment errant | Lynx-chimère | Aberration | Œil du vide | Monolithe | Écho corrompu | Tisseur de réalité | **Gardien des Failles** |
| 9 | Ombre rampante | Chien des ténèbres | Chevalier noir | Banshee | Templier du Croissant | Sorcier éclipsé | Prêtre de la lune noire | **Le Héraut** (lieutenant de Morvaen) |
| 10 | Spectre du Surge | Fragment temporel | Colosse d'écho | Archiviste perdu | Gardien éclipsé | Écho de Morvaen | Cœur pulsant (structure) | **Galerie des Échos** (3 boss passés, en version écho) |

## 4. Boss
Chaque boss a 3 phases (à 100, 66 et 33 % de PV), avec un choix d'Écho entre chaque phase. Toutes ses attaques sont annoncées au moins 1,2 s à l'avance.

| # | Boss | Faiblesse | Mécanique unique | Phases (résumé) | Moment de lore / choix |
|---|---|---|---|---|---|
| 1 | **Sylvarche corrompue** | Feu | **Fleurs-sèves** : 3 fleurs soignent le boss, c'est la leçon sur l'anti-soin | P1 balayage de racines + Champignons · P2 portails de ronces (Entrave) + bouclier d'écorce (le Feu le brise) · P3 Floraison sombre (les fleurs se régénèrent) | L'arbre gardien des elfes. **Choix** : le purifier ou l'abattre (fil *Sylvarche*, change la loyauté de Sylwen) |
| 2 | **Gharok, seigneur de guerre possédé** | Nature | **Bannières de guerre** : en détruire 3 retire son armure | P1 charges en ligne + Cri (renforce les ennemis) · P2 ancrage d'un lanceur + totems d'orage · P3 l'esprit du Surge sort du corps | **Choix** : exorciser Gharok (alliance avec les orcs, Krag rejoint le joueur) ou l'achever |
| 3 | **Hydre des brumes** | Feu | **Têtes multiples** : 3 têtes ciblables ; une tête tranchée repousse en double si elle n'est pas brûlée dans les 5 s | P1 morsures + brume · P2 souffle de venin sur une ligne · P3 inondation empoisonnée (mares sur toute l'arène) | Révélation du Cercle sur la Fracture. **Choix Aube/Cendres** : branche 3 et variante de sa Clé de voûte |
| 4 | **Colosse runique** | Foudre | **Runes corporelles** : chaque rune exposée n'est blessée que par des unités ayant traversé un portail du même élément | P1 coups de poing + avalanches · P2 les runes tournent (bouclier) · P3 il corrompt les Portes runiques | Ysolde reprogramme le Colosse : runes IV–V et mots runiques débloqués |
| 5 | **Sphinx de verre** | Ombre | **Énigmes** : entre les phases, une énigme du lore et 3 portails ; la bonne réponse rend le boss vulnérable, une mauvaise le renforce | P1 rayons réfléchis · P2 mirages (faux portails) · P3 combat sur le cycle jour/nuit accéléré | Premières traces de Morvaen au Collège |
| 6 | **Wyrm de cendre** | Givre | **Vol** : en l'air, il ne peut être touché que par les projectiles et les sorts ; il se pose ensuite | P1 souffle au sol · P2 mitraillage aérien en ligne · P3 éclosion d'œufs (Wyverneaux) | **Trahison** : un compagnon dont la loyauté est sous 25 **rejoint le boss** comme lanceur ennemi en P3 |
| 7 | **Léviathan** | Nature | **Marées** : à marée haute, il avale des portails ; des tentacules saisissent des lignes d'unités | P1 vagues déferlantes · P2 tentacules · P3 tourbillon central (aspire les unités) | Les Archives : Morvaen était un Porteur d'Écho |
| 8 | **Chimère du Surge** | Change avec l'aspect actif | **Aspects** : la faiblesse change toutes les 20 s, signalée par la tête qui brille (lion = Feu, bouc = Givre, serpent = Ombre) | P1 un aspect à la fois · P2 deux aspects · P3 les 3 aspects + portails instables | Les lignes temporelles se mélangent : apparition d'Échos d'alliés morts dans d'autres versions de l'histoire |
| 9 | **Le Reflet** | Celle du build du joueur | **Miroir** : le boss est une **copie du joueur** (classe, race, deck, ultime) ; l'arène est symétrique, l'ennemi a ses propres portails et familiers, et les bots affrontent leurs reflets | P1 duel de Flux · P2 il copie le dernier Écho choisi · P3 il utilise l'ultime du joueur | Son apparence et sa puissance dépendent de la **Corruption** du joueur |
| 10 | **Morvaen, le Roi Éclipsé** | Selon la voie (Aube : Ombre · Cendres : Lumière) | **Rembobinage** : une fois par phase, il revient 10 s en arrière et récupère des PV ; le joueur peut le contrer avec **Ancre temporelle** (bouton du Sceau d'Écho, débloqué pour ce combat) | **4 phases** · P1 il choisit aussi des Échos · P2 Rembobinage · P3 Fracture : l'arène se divise en 3 lignes temporelles, un lanceur par ligne · P4 dépend de la fin visée | Fins : Purification / Domination / Sacrifice / la Boucle. Combat de 8 à 10 min ou plus |

## 5. Zone 1 en détail (cible du prototype)

| Niv. | Nom | Type | Nouveauté | Lore |
|---|---|---|---|---|
| 1-1 | Premières lueurs | Assaut (tutoriel, solo) | Flux, déplacement, portail `+5` | Le Surge frappe le village de **Lysbourg** |
| 1-2 | Le Sentier des Lucioles | Assaut | Portail `×2`, Lucioles (mana) | **Sylwen** rejoint le joueur (bot droit) |
| 1-3 | La Clairière brisée | Assaut | 1er sort actif, Coureurs | **Brann** rejoint le joueur (bot gauche) |
| 1-4 | Les Ronces | Assaut | Portails négatifs, sort Purifier, **ordres aux bots** | Les fées sombres sèment les ronces |
| 1-5 | Le Grand Cerf | **Mini-boss** | Jauge Surge, Ultime, Champion | Le joueur reçoit le **Sceau d'Écho** |
| 1-6 | Écho des Fées | Assaut | **Échos** (choix pendant la partie), Tireurs | Le 1er usage du Sceau trouble le joueur |
| 1-7 | Le Pont des Ruines | **Escorte** | Protéger la Lanterne de l'Aube portée par des villageois | Au loin, on aperçoit la **Tour du Croissant** |
| 1-8 | La Source flétrie | **Purification** | La Dryade soigne le Nexus : anti-soin, ciblage des Soigneurs | Corruption des Veines |
| 1-9 | Le Cœur de la Forêt | **Siège** (2 Nexus + tours) | Lanceurs ennemis (Feu-follet) | **Choix** : libérer les fées captives ou poursuivre la Sylvarche (fil *Fées*) |
| 1-10 | La Sylvarche | **Boss** | Mécanique des Fleurs-sèves | **Choix** : purifier ou abattre |

## 6. Direction artistique par zone

**Fil rouge visuel** : la **Tour du Croissant** se voit à l'horizon dans chaque zone, et elle se rapproche d'une zone à l'autre. L'image de référence (`docs/art/style-reference-01.jpg`) correspond à l'arrivée dans la zone 9.

| Zone | Palette | Lumière | Décor typique | Musique |
|---|---|---|---|---|
| 1 | Verts tendres, or chaud, rose fleur (`#8FD16A` `#F2C46B` `#F5A3C7` `#2E5D3A`) | Aube dorée | Champignons géants, lucioles, ruines fleuries | Flûte, harpe, cordes légères |
| 2 | Ambre, ocre, bleu ciel (`#E8A33D` `#C2703A` `#7FB8E6` `#5B4632`) | Plein midi | Steppes, moulins, campements de clans | Percussions tribales, vièle |
| 3 | Vert-gris, violet pâle, brume (`#6E7F6A` `#9C8AB4` `#C9D1C4` `#2F3A33`) | Crépuscule | Saules, pilotis, lanternes | Ambiance, chœurs murmurés |
| 4 | Blanc, bleu glacier, cyan aurore (`#EAF4FB` `#7FB7E0` `#4FE3D2` `#23395B`) | Nuit, aurore boréale | Forteresse naine, runes lumineuses | Cuivres graves, chœurs nains |
| 5 | Or, turquoise, verre blanc (`#E6C15A` `#3FC1C9` `#F4F1E8` `#8A5A2B`) | Soleil et nuit étoilée | Dunes de verre, ruines du Collège | Oud, percussions |
| 6 | Cendre, braise, rouge (`#2B2626` `#FF7A2F` `#C7372F` `#5E4B43`) | Ciel embrasé | Arbres calcinés, nids de dragons | Orchestre épique, tambours |
| 7 | Bleu abyssal, bioluminescence, nacre (`#0E2A47` `#36E0C8` `#E7DCEB` `#1D5C7A`) | Reflets de lumière sous l'eau | Temples engloutis, archives de corail | Synthés aquatiques, harpe |
| 8 | Magenta, cyan, noir (`#D93CF2` `#38E8FF` `#120E1C` `#6B5CFF`) | Ciel fracturé | Îles flottantes, géométrie impossible | Électronique déstructurée, sons inversés |
| 9 | Violet nuit, bleu profond, argent lunaire (`#3B2A6B` `#1E2E5C` `#C8D2F0` `#6FD3FF`) | Pleine lune | Ruines envahies de végétation, Tour du Croissant (image de référence) | Chœurs sombres, orgue |
| 10 | Blanc irisé, noir absolu, prismatique (`#FFFFFF` `#05040A` `#B9A8FF` `#7CFFE1`) | Hors du temps | Fragments de toutes les zones | Variation du thème principal mêlant toutes les mélodies |

**Musique** : chaque thème de zone contient le **leitmotiv principal** d'Arcane Surge, ce qui assure la continuité sonore.

**Lisibilité** : la palette du décor reste désaturée par rapport aux unités, aux portails et aux sorts (règle du GDD §13).

## 7. Format des données d'un niveau (aperçu)

```json
{
  "id": "z01_l08",
  "name": "La Source flétrie",
  "type": "purification",
  "zone": 1, "level": 8,
  "nexus": { "hp_mult": 1.0, "healers": true },
  "towers": [{ "x": 2.0, "y": 14.5 }, { "x": 7.0, "y": 14.5 }],
  "portals": [
    { "x": 4.5, "y": 5.0, "type": "mult", "value": 2, "motion": "slide", "range": 2.5 },
    { "x": 2.0, "y": 11.0, "type": "corrupted", "purify_required": true }
  ],
  "hazards": ["fireflies"],
  "waves": { "budget_base": 20, "budget_per_level": 6, "pool": ["mushroom", "thorn_rabbit", "withered_dryad"] },
  "dialogue": { "intro": "z01_l08_intro", "outro": "z01_l08_outro" },
  "variants": [{ "if_flag": "fairies_freed", "add_allies": ["fairy_helper"] }]
}
```
