# 49. La place d'Havre-Aube

> Code : `scripts/ui/havre_place.gd` (la place), `scripts/gfx/place_art.gd` (façades), `scripts/gfx/hero_model.gd` (`_aldric`, `_ossian`, `_aelis`, `_durgan`), `scripts/ui/hub_screen.gd`.

À Havre-Aube, sous le titre, une **rue du village** en pixel art, plus large que l'écran, remplace l'espace vide : le héros en volume s'y promène.

## 1. Les lieux

De gauche à droite : **Porte du monde** (arche runique, portail bleu qui tourbillonne → Carte du monde), **Ta maison** (chaumière, coffre devant la porte → Équipement), **Défis** (tableau d'affichage aux papiers épinglés, pastille rouge quand une récompense attend), **Forge** (pierre sombre, grande cheminée qui fume, porte rougeoyante, enclume en enseigne), **Armurerie** (colombages, vitrine avec épée et bouclier), **Bibliothèque** (haute façade grise, fenêtres en arc, livre ouvert), **Entraînement** (enclos, mannequin de paille, cible), **Le Cercle** (tente, rondins, feu de camp qui danse), **Méditation** (tour blanche à coupole et soleil d'or), **Tour des Échos** (flèche violette aux fenêtres lumineuses). Chaque lieu porte son nom en enseigne ; la Méditation et la Tour restent fermées avant la fin de l'acte 1 (toucher affiche pourquoi).

## 2. Les habitants, en volume

- **Durgan** devant la Forge, **Aldric** devant l'Armurerie (cheveux bouclés grisonnants, barbe courte, anneau d'or, chemise bordeaux, tablier, mètre de tailleur), **Ossian** devant la Bibliothèque (cheveux et longue barbe blancs, demi-lunes, robe verte, clé d'or, grand livre), **Sœur Aelis** devant la Méditation une fois l'acte 1 fini (voile blanc, diadème solaire, robe claire à étole dorée, bâton au soleil).
- Ils respirent, et **se tournent vers le héros** qui passe près d'eux.
- Les **deux compagnons du Cercle** se tiennent de part et d'autre du feu.

## 3. Se promener

- Toucher la **rue** : le héros y marche (de profil, animation de marche) ; la caméra le suit.
- Toucher un **lieu** ou son **gardien** : le héros marche jusqu'à la porte, puis la salle s'ouvre.
- Les tuiles sous la place restent là pour un accès direct.

## 4. L'heure

La place suit l'heure de Havre-Aube : ciel, collines et pavés de l'aube, du jour, du crépuscule ou de la nuit (étoiles qui scintillent) ; le soir et la nuit, façades assombries et fenêtres allumées ; les personnages sont éclairés à l'avenant.

## 5. Vérifications

`_quests_tower_place_ok` : la place est dans Havre-Aube avec ses marchands ; le héros marche jusqu'à l'Armurerie et l'ouvre ; toucher la rue le fait marcher.
