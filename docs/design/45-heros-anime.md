# 45. Le héros en volume : animations, éclairage, équipement porté, carte

> Code : `scripts/gfx/hero_model.gd` (modèle en cubes, squelette, poses, éclairages, rendu), `scripts/gfx/hero_gear.gd` (équipement porté), `scripts/ui/hero_turntable.gd` (vue tournante animée), `scripts/ui/hero_card.gd` (carte à partager), `scripts/ui/creation_screen.gd`, `scripts/ui/equipment_screen.gd`.

Le héros (et Brann, Sylwen) est un petit modèle en cubes rendu en pixel art sous n'importe quel angle (voir [35](35-equipement-runes-forge.md)). Il s'anime désormais, s'éclaire selon la scène et porte son équipement réel.

## 1. Squelette et animations

Chaque cube appartient à une partie : buste, tête, bras gauche et droit, jambes, cape, dos (carquois, ailes, sac…), queue, et l'arme ou l'objet de chaque main. Chaque partie tourne autour de son articulation (hanches, cou, épaules, mains, haut de la cape) ; la tête, les bras et la cape suivent le buste, l'arme suit le bras. Brann, plus trapu, a ses propres articulations.

| Animation | Images | Ce qu'on voit |
|---|---|---|
| Repos | 4, en boucle | Respiration : épaules et tête descendent d'un pixel, la cape ondule |
| Marche | 8, en boucle | Jambes et bras en balancier opposé, rebond, cape qui flotte |
| Sort | 7 | Élan vers l'arrière, l'arme se lève et se tend vers l'avant, éclat lumineux, retour |
| Coup reçu | 5 | Flash blanc, recul du buste et de la tête, bras écartés, retour |
| Victoire | 7 | Appel, saut, arme brandie au-dessus de la tête, regard vers le ciel |
| Défaite | 7 | Il chancelle, met un genou à terre, s'appuie sur son arme, tête basse |

Toutes les animations marchent pour toutes les races, classes, armes et kits de curiosités, sans dessin image par image. Le rendu tourne chaque cube avec sa partie (8 points par cube tourné, 9 pour un cube seulement déplacé) puis applique le tampon de profondeur, les contours intérieurs et le contour sombre. L'image fait 36 × 44 pixels (de la marge pour un saut ou une arme brandie) ; au repos le héros occupe toujours 28 × 33. Les images sont gardées en cache par animation, image, angle et éclairage (une image coûte environ 3 ms).

**Vue tournante** : au repos, le héros respire. Le toucher sans glisser lui fait faire un geste (sort, puis victoire, à tour de rôle). Pendant qu'on le fait tourner, il garde son image. Une animation qui ne boucle pas reste un instant sur sa dernière image, puis il revient au repos.

## 2. Éclairage de scène

La lumière est un paramètre du rendu : direction, couleur et force de la lumière principale, teinte des ombres, teinte d'ensemble, liseré de contre-jour. Elle est attachée à la vue (elle suit la caméra) ou au monde (elle reste du côté de la source quand le héros tourne, comme un feu de camp). Les cubes lumineux (yeux, gemmes, orbes) n'en dépendent pas : ils ressortent la nuit.

| Éclairage | Effet |
|---|---|
| Jour | Lumière blanche en haut à gauche (le rendu d'origine) |
| Aube | Lumière rose-or, ombres violettes, contre-jour doré |
| Crépuscule | Lumière orangée de l'autre côté, teinte rose |
| Nuit | Clair de lune bleu venu d'en haut, ensemble bleuté, contre-jour froid |
| Feu de camp | Lumière orange basse, fixée dans le monde ; ombres très sombres, contre-jour chaud |
| Lave | Lumière rouge venue d'en bas |
| Abysses | Lumière turquoise, teinte marine, contre-jour clair |
| Lanterne | Lumière chaude d'intérieur |

Où : l'Équipement suit l'heure de Havre-Aube (aube, jour, crépuscule, nuit), ou l'éclairage choisi dans « Lumière » (gardé dans la sauvegarde) ; l'essayage de l'Armurerie est éclairé à la lanterne ; la carte du héros prend l'éclairage de sa zone.

## 3. L'équipement porté sur le héros

Chaque objet porté se voit, d'après son type, sa matière, sa teinte, sa gemme et sa rareté (`art` dans `data/items.json`). La tenue garde la couleur choisie à la création ; l'armure s'y ajoute.

- **Armure** : robe (écharpe en travers de la poitrine, bande brodée), tunique (tabard bordé devant et derrière), manteau (mantelet de fourrure, pan dans le dos), brigandine (cuir clouté, épaulières), cuirasse (plastron à arête, dossière, épaulières de métal), mailles (damier de mailles). À partir d'Épique, l'ourlet et les liserés prennent la couleur de la rareté ; ceux d'une Mythique luisent.
- **Tête** : heaume (coque, fente des yeux, nasal ; cornes pour les heaumes cornus ou de drake, sinon crête), capuche (à la teinte de l'objet), chapeau pointu (bord, cône qui part en arrière, gemme), couronne (pointes, gemme au front), bandeau (pans noués derrière), masque (yeux qui luisent), coiffe rayée (némès). Le casque se masque dans l'Équipement (« Casque visible / masqué »), l'objet restant équipé.
- **Mains et pieds** : gants, gantelets, brassards, bandes ; bottes, grèves, sandales.
- **Arme** (main droite) : bâton, baguette, sceptre, arc (avec carquois dans le dos), arbalète, épée, rapière, cimeterre, dague, hache, marteau, masse, fléau, faux, glaive, lance. Une arme légendaire a sa gemme lumineuse ; une mythique, aussi le fil de sa lame.
- **Main gauche** : bouclier (bordure à la couleur de la rareté), carquois, livre, orbe flottante, lanterne, crâne, cor, miroir, enclume.
- **Bijoux** : médaillon sur la poitrine, charme à la ceinture (gemme lumineuse à partir d'Épique). Les anneaux, trop petits, ne se dessinent pas.

Les curiosités (voir [44](44-armurerie-cosmetiques.md)) passent par-dessus : une tenue cosmétique remplace l'armure, un couvre-chef cosmétique le casque, une arme cosmétique l'arme. Sans arme équipée, le héros garde l'arme de sa classe.

## 4. Création du personnage

L'aperçu montre le héros en volume, qui tourne et respire, sur un socle de lumière : chaque choix (race, classe, silhouette, coiffe, visage, peau, cheveux, yeux, tenue) s'y voit aussitôt, sous tous les angles, et l'angle est gardé d'un choix à l'autre. Choisir une classe lui fait lancer un sort avec l'arme de cette classe. À la création, il porte l'arme et la tenue de sa classe ; au Miroir de Havre-Aube, son équipement et ses cosmétiques.

## 5. Équipement : poses et lumière

Sous les emplacements d'apparence, « Poses » fait jouer Marche, Sort, Coup reçu, Victoire et Défaite ; « Lumière » choisit l'éclairage (Havre-Aube suit l'heure du jour). « Carte du héros » ouvre la carte à partager.

## 6. Carte du héros

Une image de 1080 × 1350 (format portrait des réseaux) :

- en fond, le décor d'une zone déjà atteinte (au choix), assombri vers le haut et le bas ;
- un cadre doré, « ARCANE SURGE » et le nom de la zone ;
- le héros en grand dans la pose choisie (Victoire, Sort ou Repos), avec son équipement et ses cosmétiques, sous l'éclairage de la zone (nuit au Bois des Lucioles, crépuscule aux Collines d'Ambre, aube aux Pics Gelés, lave à la Forêt Cendrée, abysses à la Cité Engloutie…), sur un socle de lumière de cette couleur ;
- son nom, sa race, sa classe et son niveau, sa Puissance, les icônes de ses objets portés bordées de leur rareté, et son kit de curiosités complet s'il en porte un.

« Enregistrer l'image » la télécharge en PNG sur le web (ou l'enregistre dans le dossier du jeu ailleurs).

## 7. Vérifications

`tools/ui_smoke.gd` (`_hero_rig_ok`) : chaque animation du héros, de Brann et de Sylwen se rend et bouge ; la victoire brandit l'arme au-dessus de la tête ; chaque éclairage change le rendu ; chacun des 232 objets (hors anneaux) change l'allure du héros, de face ou de dos ; l'allure de l'équipement porté et le casque masqué ; un geste revient au repos ; l'Équipement a ses poses, ses lumières, le casque et la carte ; la création a son héros qui tourne ; la carte se construit.

Aperçus : `?room=equipment&gear=1` (équipement varié), `&card=1` (carte du héros), `&cos=corsaire`.
