# Arcane Surge

Jeu de « foule contrôlée » en univers de fantasy magique : tu lances des flux d'invocations à travers des portails runiques pour détruire le Nexus ennemi, avec deux bots compagnons, des sorts, des classes et une histoire à choix.

- Design complet : [`docs/GDD.md`](docs/GDD.md) et [`docs/design/`](docs/design/)
- Maquettes de l'interface : [`docs/mockups/`](docs/mockups/)

## Jouer

**https://adamfast-tech.github.io/Arcane-Surge/** (navigateur, téléphone ou ordinateur).

- **Compte :** connexion avec ton **compte Académie** (même pseudo et même mot de passe), ou jeu sans compte, la progression restant alors sur l'appareil.
- **Création du personnage :** race (8, avec leurs stats et traits visibles), classe, silhouette, coiffe, visage et couleurs. Le portrait et le sprite de combat sont générés selon ces choix ; le Miroir de Havre-Aube permet de changer l'apparence ensuite. Chaque race a 2 passifs, un Don racial (bouton DON en combat, touche D) et un arbre d'héritage à l'Entraînement.
- **Classes (7 jouables) :** Mage, Archer, Épéiste, Clerc, Nécromancien, Chevalier, Berserker. Chacune a son invocation, son Champion, son Ultime, l'arme du héros et son propre arbre (2 branches, plus la Voie du Surge après l'acte 3, avec une Clé Aube ou Cendres ; Clés de voûte : Miracle, Légion, Inébranlable…).
- **Grimoires de classe :** chaque classe aura environ 60 techniques à acheter à la Bibliothèque, de Novice à Interdit, en 8 disciplines (une page du Tiroir). L'Archer a les siennes : tirs, volées, pièges, traque, bêtes, poisons, flèches élémentaires et astrales. Chacune a sa propre animation.
- **Salle de méditation (fin de l'acte 1) :** changer de voie (le héros et ses compagnons), 3 configurations enregistrées, réinitialisation, Harmonie contre la Corruption.
- **Compagnons :** niveau et XP propres (80 % en combat, 30 % à Havre-Aube), équipement depuis le Cercle, classe changeable.
- **Havre-Aube :** le hub, avec profil et progression, la carte des zones, l'équipement avec la Forge, l'Entraînement (arbre de compétences), la Bibliothèque (55 sorts élémentaires en 7 écoles et 7 rangs, de Novice à Interdit, achetés en or selon leur puissance ; choix des 7 sorts du deck), le Cercle (réglages des compagnons) et la Sauvegarde.
- **Zone 3, Marais Murmurants :** 10 niveaux (21 à 30) contre les morts du marais. Des bancs de brume cachent les ennemis, et la Lumière les dissipe. Les mares de poison rongent tes invocations : brûle-les ou gèle-les. On y affronte le Crocodile-liche, puis l'**Hydre des brumes**, dont les têtes repoussent si tu ne cautérises pas les plaies au Feu. L'acte 3 fait entrer Nyx, fée nécromancienne du Cercle des Cendres. Il révèle la vérité sur la Fracture et pose deux choix, sur l'adepte Corvin puis entre la Voie de l'Aube et celle des Cendres. Ce dernier ouvre la branche « Voie du Surge ».
- **Zone 4, Pics Gelés :** 10 niveaux (31 à 40) contre les bêtes des montagnes et les élémentaires de givre, que la Foudre bat. La glace fait glisser tout le monde et le Feu la fait fondre ; des avalanches annoncées ensevelissent amis et ennemis ; les Portes naines FORGE cuirassent tes invocations. On y affronte la Sentinelle runique puis le **Colosse runique** : seules les invocations du bon élément brisent ses runes corporelles, et une Ultime les brise toutes.
- **Préparation :** avant chaque combat, on choisit le Deck (7 sorts) ou le Tiroir. Dans le Tiroir, tous les sorts connus sont rangés par école : on maintient une école, on relâche sur un sort, puis on touche l'arène, ou on glisse le sort directement jusqu'à l'arène.
- **Arène destructible :** les sorts laissent braises, verglas, eau, miasme, cratères et failles. Les éléments réagissent entre eux (vapeur, gel, électrocution, incendie). Les piliers s'effondrent sur les ennemis, et le Mur de pierre bloque le passage.
- **Zone 1, Bois des Lucioles :** 10 niveaux, dont un mini-boss (le Grand Cerf), une escorte, un siège et le boss **la Sylvarche**.
- **Zone 2, Collines d'Ambre :** 10 niveaux (niveaux 11 à 20) contre les clans orcs possédés. On y trouve un mini-boss (Varg), une escorte de caravane, une purification, un siège et le boss **Gharok** avec ses Bannières de guerre. Le vent des steppes pousse les troupes et des pylônes d'ambre surchargent les portails. L'histoire de l'acte 2 mène à deux choix : le Traité d'Ambre (humains ou orcs) puis le sort de Gharok. Selon ces choix, Krag, son fils, rejoint le groupe : au Cercle, tu choisis alors 2 compagnons parmi 3.
- **Sorts :** 7 sorts animés (Boule de feu, Pluie de givre, Racines, Éclair en chaîne, Vortex d'ombre, Onde arcanique, Purifier), plus le Champion et l'Ultime (Météore arcanique).
- **Histoire :** prologue, dialogues avant et après chaque niveau avec portraits, choix qui changent la suite (les fées captives, le sort de la Sylvarche), loyauté de Brann et Sylwen, répliques des compagnons en combat.
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
