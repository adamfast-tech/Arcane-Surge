# Arcane Surge

Jeu de « foule contrôlée » en univers de fantasy magique : tu lances des flux d'invocations à travers des portails runiques pour détruire le Nexus ennemi, avec deux bots compagnons, des sorts, des classes et une histoire à choix.

- Design complet : [`docs/GDD.md`](docs/GDD.md) et [`docs/design/`](docs/design/)
- Maquettes de l'interface : [`docs/mockups/`](docs/mockups/)

## Jouer

**https://adamfast-tech.github.io/Arcane-Surge/** (navigateur, téléphone ou ordinateur).

- **Compte :** connexion avec ton **compte Académie** (même pseudo et même mot de passe), ou jeu sans compte, la progression restant alors sur l'appareil.
- **Création du personnage :** race (8, avec leurs stats et traits visibles), classe, silhouette, coiffe, visage et couleurs. Le portrait et le sprite de combat sont générés selon ces choix ; le Miroir de Havre-Aube permet de changer l'apparence ensuite. Chaque race a 2 passifs, un Don racial (bouton DON en combat, touche D) et un arbre d'héritage à l'Entraînement.
- **Classes (7 jouables) :** Mage, Archer, Épéiste, Clerc, Nécromancien, Chevalier, Berserker. Chacune a son propre tir normal (squelettes qui sortent de terre, lucioles, flèche qui transperce toute une ligne, onde d'épée en arc, rayon de lumière qui soigne la Barrière, bouclier à onde de choc, haches en éventail de plus en plus rapides quand la Barrière faiblit), qui traverse les portails comme les troupes ; au Cercle, chaque compagnon garde ses troupes ou prend le tir de sa classe, son Champion, son Ultime, l'arme du héros et son propre arbre (2 branches, plus la Voie du Surge après l'acte 3, avec une Clé Aube ou Cendres ; Clés de voûte : Miracle, Légion, Inébranlable…).
- **Grimoires de classe :** chaque classe a environ 60 techniques à acheter à la Bibliothèque, de Novice à Interdit, en 8 disciplines (une page du Tiroir). L'Archer a les siennes (tirs, volées, pièges, traque, bêtes, poisons, flèches élémentaires et astrales), l'Épéiste (tailles, estocs, danses, gardes, lames spectrales, lames de foudre, saignées, pluies d'acier) le Clerc (soins, châtiments, bénédictions, sanctuaires, purifications, anges, rayons, égides) le Nécromancien (os, morts-vivants, maléfices, fléaux, âmes, ténèbres, magie du sang, nécropoles) le Chevalier (boucliers, charges, étendards, forteresses, l'Ordre, justice, défis, serments) et le Berserker (haches, fureur, assauts, cris, totems, carnage, clan, séismes). Le grimoire du Mage, ce sont les 56 sorts élémentaires, ouverts à tous. Chacune a sa propre animation.
- **Options (clé à molette de Havre-Aube) :** ambiance des menus (sobre, ou enrichie : lumière, brume, lucioles ou braises selon la salle, panneaux en relief, titres dorés) ; Deck ou Tiroir ; écoles élémentaires pour toutes les voies, ou réservées au Mage (chaque voie n'emporte alors que son grimoire) ; 6 difficultés, de Facile à Impossible (ennemis plus lents ou plus rapides et plus ou moins dangereux, Nexus plus ou moins solide, XP et butin en proportion).
- **Salle de méditation (fin de l'acte 1) :** changer de voie (le héros et ses compagnons), 3 configurations enregistrées, réinitialisation, Harmonie contre la Corruption.
- **Compagnons :** niveau et XP propres (80 % en combat, 30 % à Havre-Aube), équipement depuis le Cercle, classe changeable.
- **Havre-Aube :** le hub, avec profil et progression, la carte des zones, l'équipement avec la Forge, l'Entraînement (arbre de compétences), la Bibliothèque (55 sorts élémentaires en 7 écoles et 7 rangs, de Novice à Interdit, achetés en or selon leur puissance ; choix des 7 sorts du deck), le Cercle (réglages des compagnons) et la Sauvegarde.
- **Zone 3, Marais Murmurants :** 10 niveaux (21 à 30) contre les morts du marais. Des bancs de brume cachent les ennemis, et la Lumière les dissipe. Les mares de poison rongent tes invocations : brûle-les ou gèle-les. On y affronte le Crocodile-liche, puis l'**Hydre des brumes**, dont les têtes repoussent si tu ne cautérises pas les plaies au Feu. L'acte 3 fait entrer Nyx, fée nécromancienne du Cercle des Cendres. Il révèle la vérité sur la Fracture et pose deux choix, sur l'adepte Corvin puis entre la Voie de l'Aube et celle des Cendres. Ce dernier ouvre la branche « Voie du Surge ».
- **Zone 4, Pics Gelés :** 10 niveaux (31 à 40) contre les bêtes des montagnes et les élémentaires de givre, que la Foudre bat. La glace fait glisser tout le monde et le Feu la fait fondre ; des avalanches annoncées ensevelissent amis et ennemis ; les Portes naines FORGE cuirassent tes invocations. On y affronte la Sentinelle runique puis le **Colosse runique** : seules les invocations du bon élément brisent ses runes corporelles, et une Ultime les brise toutes. L'acte 4 ramène Brann chez son clan, « le clan qui ferme » : Durgan lui confie la Clé-rune, Ysolde, héritière des Runistes, lit les Portes, et le spectre du Thane Orrin révèle pourquoi la forteresse a été scellée. Deux choix : réveiller les Portes (pour un Nain, ou avec Brann si sa loyauté le permet) ou les sceller, puis reprogrammer le Colosse ou forger l'Enclume-Cœur. Ils changent les combats des Pics et peuvent rendre à Brann l'honneur de son clan.
- **Zone 5, Désert de Verre :** 10 niveaux (41 à 50) contre les créatures de verre et les constructions animées du Collège oublié, surtout de Feu : le Givre les bat. Le soleil et la lune se relaient : le jour, le Feu brûle plus fort ; la nuit, le Givre mord plus fort. Certains portails sont des mirages qui se dissipent à l'approche, et les miroirs renvoient les tirs et projettent des rayons de soleil. On y affronte le Scarabée-soleil, puis le **Sphinx de verre** : entre ses phases, il pose une énigme du lore, et il faut envoyer ses invocations par le portail de la bonne réponse. Résoudre les deux énigmes donne la Couronne de l'Énigme. L'acte 5 fait entrer Thalren, mage du Collège Arcanique, dans les ruines du premier Collège, où un élève prodige a brisé le temps. Le Journal signé « M. » peut être lu (un Fragment de Morvaen, des énigmes plus faciles) ou brûlé (Thalren protège la Barrière), et le Sphinx vaincu demande « Qui es-tu ? » : révéler son Sceau ou mentir.
- **Zone 6, Forêt Cendrée :** 10 niveaux (51 à 60) contre les dragons et les démons de feu, que le Givre bat. Des incendies dévalent la forêt en couloirs vers la Barrière et brûlent tes invocations : le Givre les éteint ou les fait reculer. Des dragons annoncés par leur ombre mitraillent une rangée et y laissent des foyers ; les Golems de magma laissent une flaque de feu, les Cultistes du Wyrm des foyers, et les Phénix mineurs renaissent de leurs cendres sauf si le Givre les achève. On y affronte le Drake ancien, puis le **Wyrm de cendre** : en vol, seuls les tirs et les sorts l'atteignent, et ses œufs éclosent en Wyverneaux si on ne les brise pas. L'acte 6 fait entrer Ignara, mage draconique élevée à Braisemont, qui retrouve sa mère, la Mère-Dragon : pacte ou vol de l'Œuf de cendre. Le Wyrm pose sa Marque sur le compagnon le moins loyal : il le rejoint en plein combat. Brisé, il peut être épargné puis racheté dans la quête « Les Cendres du Pardon », dont il revient avec l'Héritage de cendre, ou laissé partir ; un sort l'achève.
- **Zone 7, Cité Engloutie :** 10 niveaux (61 à 70) contre les créatures abyssales, de Givre et de Foudre (la Foudre et la Nature les battent). La marée monte et noie les portails du premier rang, ralentit tes invocations et accélère les créatures de la mer ; des courants emportent les troupes d'un côté puis de l'autre. On y affronte le Kraken juvénile, puis le **Léviathan** : vagues qui repoussent, tentacules, portails avalés et tourbillon au centre. L'acte 7 fait entrer Ssareth, scribe reptilien des Archives du Temps : la cité garde chaque vie comme un fil de corail, et le fil noir de Morvaen révèle qu'il était un Porteur d'Écho, revenu 412 fois en arrière. Lire sa propre ligne donne les Prémonitions (le type des conséquences de chaque choix) ; libérer le Léviathan rallie les Archivistes, le tuer donne le Trident des Archives.
- **Préparation :** avant chaque combat, on choisit le Deck (7 sorts) ou le Tiroir. Dans le Tiroir, tous les sorts connus sont rangés par école : on maintient une école, on relâche sur un sort, puis on touche l'arène, ou on glisse le sort directement jusqu'à l'arène. Pour une mission déjà réussie, on choisit aussi de revoir ou de passer ses cinématiques (choix mémorisé).
- **Arène destructible :** les sorts laissent braises, verglas, eau, miasme, cratères et failles. Les éléments réagissent entre eux (vapeur, gel, électrocution, incendie). Les piliers s'effondrent sur les ennemis, et le Mur de pierre bloque le passage.
- **Arbres de compétences :** chaque classe a 3 branches de 7 paliers et 64 compétences (448 au total), dessinées comme un arbre de RPG : médaillons reliés par des chemins qui s'illuminent, passifs, nouveaux sorts, évolutions de l'Ultime et du Champion, et Clés de voûte, dont des Clés à double tranchant. Une compétence s'ouvre avec assez de points dans la branche et un rang dans une compétence reliée au-dessus.
- **Équipement et Forge :** 260 objets répartis en 7 panoplies de zone de 36 pièces (bâtons, arcs, rapières, fléaux, glaives, cimeterres, faux, crânes, cors, chapeaux pointus, heaumes, brigandines, brassards, talismans, sabliers…), plus 6 légendaires uniques dont 2 à arracher aux boss, chacun avec son icône en pixel-art, et cinq raretés jusqu'à Mythique. 16 runes (Kaor, Pyr, Isa, Lux, Nox, Wyrd, Mult…) de niveau I à V se gagnent en combat et se gravent sur l'équipement : la même rune agit autrement sur une arme, une armure, un bijou ou un charme. La Forge de Durgan grave et retire les runes, fusionne 3 runes identiques et 3 objets de même rareté (un objet fusionné peut refusionner ; 3 légendaires donnent un Mythique).
- **Armurerie d'Aldric :** de l'équipement à acheter à l'or, renouvelé toutes les 5 h, avec une vitrine qui tombe 1 fois sur 6 en Épique ou Légendaire et 1 fois sur 8 en Mythique ; et 8 kits de curiosités (mitron, corsaire et son perroquet, tête de citrouille, chevalier de carton, apiculteur, prince grenouille, roi sporelin, voyageur stellaire) portés par-dessus l'équipement, avec un bonus à 2 pièces et un bonus de kit complet ([`docs/design/44-armurerie-cosmetiques.md`](docs/design/44-armurerie-cosmetiques.md)).
- **Zone 1, Bois des Lucioles :** 10 niveaux, dont un mini-boss (le Grand Cerf), une escorte, un siège et le boss **la Sylvarche**.
- **Zone 2, Collines d'Ambre :** 10 niveaux (niveaux 11 à 20) contre les clans orcs possédés. On y trouve un mini-boss (Varg), une escorte de caravane, une purification, un siège et le boss **Gharok** avec ses Bannières de guerre. Le vent des steppes pousse les troupes et des pylônes d'ambre surchargent les portails. L'histoire de l'acte 2 mène à deux choix : le Traité d'Ambre (humains ou orcs) puis le sort de Gharok. Selon ces choix, Krag, son fils, rejoint le groupe : au Cercle, tu choisis alors 2 compagnons parmi 3.
- **Sorts :** 7 sorts animés (Boule de feu, Pluie de givre, Racines, Éclair en chaîne, Vortex d'ombre, Onde arcanique, Purifier), plus le Champion et l'Ultime (Météore arcanique).
- **Son :** musiques composées (thème de Havre-Aube, carte, combat de chaque zone, boss, cinématiques), un son propre à chaque sort, cris des boss, voix des personnages pendant les cinématiques ; volumes réglables dans les Options. Tout est fabriqué par les outils de `tools/audio/` ([`docs/design/43-audio.md`](docs/design/43-audio.md)).
- **Histoire :** prologue, dialogues avant et après chaque niveau avec portraits qui parlent et clignent, mis en scène comme de petites cinématiques (grands bustes animés, créatures en présence, cercles runiques, éclairs, failles et rayons en pixel-art, bulles d'émotion, étalonnage, carton-titre ; un décor par lieu et des effets propres à chaque scène pour le prologue et les zones 1 à 7, créatures et chefs en pied, dont la Mère-Dragon et le Wyrm ailes déployées et le Léviathan), choix qui changent la suite (les fées captives, le sort de la Sylvarche), loyauté de Brann et Sylwen, répliques des compagnons en combat.
- **Progression :** XP, niveaux, or, butin par étoile, équipement à améliorer.
- **Accès direct à un niveau :** `…/Arcane-Surge/?level=z01_l10` (ajouter `&solo=1` pour jouer sans bots).
- **Aperçu d'une scène :** `…/Arcane-Surge/?scene=z01_l10_outro`.

### Commandes
| Action | Tactile | PC |
|---|---|---|
| Lancer le Flux | Maintenir sur l'arène | Clic gauche maintenu (`F` : tir automatique) |
| Viser | Glisser | Souris ou `A` / `D` |
| Sort | Toucher le sort puis l'arène | `1`–`7` (lancé au curseur) |
| Champion | Bouton | `E` |
| Ultime | Bouton puis l'arène | `Espace` |
| Ordre aux bots | Toucher le bot | `Q` / `R` |
| Pause | Bouton `II` | `Échap` |
| Dialogue : suite / historique / passer | Toucher l'écran, boutons | `Espace` / `H` / `Échap` |

![Prototype en portrait](docs/art/prototype-portrait.png)

L'interface s'adapte : **portrait** sur téléphone, **paysage** (panneaux latéraux) sur tablette et ordinateur.

## Développement

Moteur : **Godot 4.7.2** (GDScript, rendu Compatibility pour le web).

```bash
godot --headless --import --path .                       # import (première fois)
godot --path .                                           # lancer le jeu
godot --headless --path . --script res://tools/sim_cli.gd -- --level=z01_l08 --runs=20   # équilibrage
godot --headless --path . --script res://tools/ui_smoke.gd                              # test des écrans
godot --headless --path . --export-release "Web" build/web/index.html                   # export web
```

| Dossier | Contenu |
|---|---|
| `scripts/battle/` | Simulation du combat (`sim.gd`, pas fixe 30 Hz, déterministe), IA des bots, rendu de l'arène, HUD |
| `scripts/battle/arena_3d.gd` | Rendu 2,5D : scène 3D pixelisée, caméra inclinée, décor de ruines, brume, lumières |
| `scripts/gfx/` | Pixel-art généré par code (atlas de sprites, textures du décor, toile de fond, portraits, illustrations) |
| `data/` | Unités, sorts, Échos, groupe du joueur, niveaux, dialogues (JSON, modifiables sans toucher au code) |
| `scripts/core/` | Profil et progression (`profile.gd`), histoire (`story.gd`, `dialogues.gd`), compte et sauvegarde en ligne (`cloud.gd`), thème |
| `scripts/ui/` | Écrans : connexion, Havre-Aube, carte, équipement et Forge, dialogues |
| `tools/` | Simulateur d'équilibrage et test de fumée (sans affichage) |

### Remplacer les sprites
Les sprites actuels sont générés par code. Pour en remplacer un, déposer `assets/sprites/<nom>.png`, et en option `<nom>-2.png` pour la 2e image d'animation, avec un fond transparent.
- La taille en jeu est fixée en mètres : n'importe quelle résolution convient.
- Les fiches de chaque personnage (vue, taille de toile, palette, prompts prêts à l'emploi) sont dans [`docs/design/10-sprites.md`](docs/design/10-sprites.md).
- La planche des sprites actuels est [`docs/sprites/planche.png`](docs/sprites/planche.png).
- Les portraits de dialogue (64×64) se remplacent de la même façon dans `assets/portraits/` (fiche : [`10-sprites.md`](docs/design/10-sprites.md) §7).

## Mise en ligne (GitHub Pages)

Le workflow `.github/workflows/web.yml` importe le projet, lance les tests et exporte la version web. À chaque push sur la branche par défaut, il déploie le résultat sur GitHub Pages (source « GitHub Actions ») et en garde une copie sur la branche `gh-pages`.

## Licences

Polices *Jersey 10 / 15* et *Pixelify Sans* : SIL Open Font License 1.1 (`assets/fonts/OFL-*.txt`).
