# 46. La Forge animée : les gestes de Durgan

> Code : `scripts/ui/forge_scene.gd` (la scène), `scripts/gfx/hero_model.gd` (`_durgan`, `from_icon`, `anvil`, `bench`, `frame_pose`, `project`), `scripts/ui/forge_screen.gd` (déclenchement), sons dans `tools/audio/sfx_bank.py` (section « forge de Durgan »).

Fusionner trois objets ou graver une rune ne se contente plus d'un message : Durgan le fait sous nos yeux, en volume (pixel art rendu en 3D, comme le héros, voir [45](45-heros-anime.md)), par-dessus l'écran de la Forge. Toucher l'écran passe la scène et montre tout de suite le résultat ; à la fin, toucher ramène à la Forge.

## 1. Durgan en volume

Vieux nain forgeron d'après son portrait : crâne chauve noirci de suie, oreilles, nez épais, sourcils broussailleux, grande barbe grise tressée de deux anneaux de fer, moustache, tunique brune, tablier de cuir à sangles et poche aux outils, manches retroussées sur des avant-bras nus, brassard de cuir, mains noircies, marteau de forge (manche de bois, tête d'acier) dans la main droite. Ses **lunettes de forge** (verres bleutés cerclés de laiton, pont et branches de cuir, sangle autour du crâne) sont une partie à part, construite sur ses yeux et qui bascule autour du centre de la tête : relevées, elles reposent sur le haut du front, la sangle passe sur la nuque, et l'on voit ses petits yeux sombres sous ses sourcils ; rabattues, elles couvrent ses yeux.

Poses de forge (`ForgeScene.dpose`) : repos, main aux lunettes, tendre la main vers l'établi (une pose par objet), soulever, poser sur l'enclume, lever le marteau, frapper, rebond, montrer (bras levé), graver (deux temps : coup de marteau sur le burin), triomphe (marteau brandi). D'une pose à l'autre, une image intermédiaire adoucit le geste.

**Les objets sont les vrais** : chaque objet et chaque rune sont mis en volume d'après leur icône en pixel art (chaque pixel devient une petite colonne de cubes), donc la rune gravée est celle qu'on a choisie (famille, couleur, glyphe, niveau) et les objets fusionnés sont les trois qu'on a posés. L'enclume (pied, table, bigorne, talon) et l'établi de bois sont aussi en cubes. Les positions se calculent sur le modèle : l'établi est là où la main gauche de Durgan se tend, l'enclume sous la tête de son marteau quand il frappe, et un objet tenu suit exactement sa main.

Éclairage « Forge » : lumière orangée du foyer sur le côté, ombres violacées, liseré de braise ; derrière, l'atelier de la Forge assombri et la lueur du foyer qui palpite.

## 2. Fusion (environ 9 s)

1. Durgan, de trois quarts devant son enclume ; les trois objets attendent sur l'établi.
2. Il **enfile ses lunettes** : sa main gauche les saisit sur le haut de son front, les fait basculer vers l'avant, elles se posent sur ses yeux avec un claquement, et il baisse la tête pour les ajuster.
3. Il prend le **premier objet** sur l'établi, le soulève et le **pose sur l'enclume** (choc, poussière) ; puis le deuxième, puis le troisième, côte à côte.
4. Il lève son marteau (souffle) et **frappe trois fois** : chaque coup sonne l'acier, fait jaillir une gerbe d'étincelles et une onde de choc, secoue l'image et fait luire un peu plus les objets.
5. Les objets se mettent à **tourner en volume**, montent en spirale au-dessus de l'enclume et se rejoignent (bourdon qui monte).
6. **Éclair blanc** : l'objet né de la fusion apparaît, grand, au-dessus de Durgan, tournant sur lui-même, auréolé de rayons à la couleur de sa rareté ; Durgan brandit son marteau. Son nom et sa rareté s'affichent (accord scintillant).

## 3. Gravure (environ 7 s)

1. Durgan, **de face**, derrière son enclume ; l'objet et la rune choisie attendent sur l'établi.
2. Il prend l'objet et le pose sur l'enclume, devant lui.
3. Il prend **la rune** et la montre : elle s'éveille à la couleur de sa famille (souffle magique, cloches).
4. Il la pose sur l'objet et la **grave à petits coups de marteau** sur le burin (quatre coups, étincelles à la couleur de la rune, la pointe qui trace).
5. La rune se fond dans l'objet : **son glyphe s'allume** dessus, onde de lumière ; l'objet s'élève au-dessus de Durgan, le glyphe brillant au centre. « Pyr III gravée », sur quel objet, et son effet.

## 4. Sons

`forge_goggles` (lunettes rabattues), `forge_pick` (objet pris), `forge_place` (posé sur l'enclume), `forge_whoosh` (marteau levé), `forge_strike` (coup sur l'enclume, étincelles), `forge_fuse` (la fusion), `forge_reveal` (l'objet apparaît), `engrave_tap` (coup sur le burin), `engrave_scratch` (le tracé), `rune_glow` (la rune s'éveille), `rune_set` (la rune scellée). Fabriqués par `tools/audio/sfx_bank.py --only forge_` (et `engrave_`, `rune_`).

## 5. Fluidité

Les poses de Durgan sont préparées pendant le plan d'ouverture (trois par image) ; les objets en rotation sont rendus à la demande (trois images neuves par image d'écran au plus, sinon l'image précédente reste).

## 6. Vérifications

`tools/ui_smoke.gd` (`_forge_scene_ok`) : Durgan se rend, ses lunettes changent l'image, son marteau s'abat ; une rune mise en volume n'est pas vide ; la fusion et la gravure se jouent jusqu'au bout (l'objet né de la fusion apparaît ; le glyphe s'allume sur l'objet) ; passer la scène montre le résultat ; le bouton FUSIONNER et la gravure de la Forge lancent la scène, avec la rune choisie.

Aperçus : `?room=forge&fx=fusion`, `?room=forge&fx=gravure` ; `&fxspeed=0.25` les joue au ralenti.
