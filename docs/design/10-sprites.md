# Fiches sprites — personnages cohérents avec la direction artistique

> Planche des sprites actuels : [`docs/sprites/planche.png`](../sprites/planche.png) · Références agrandies (×8) : `docs/sprites/reference/<nom>.png` · Style : [`docs/art/style-reference-01.jpg`](../art/style-reference-01.jpg)

## 1. Règles communes (pour tous les sprites)

| Règle | Valeur |
|---|---|
| Style | Pixel-art 16 bits, dark fantasy, nuit au clair de lune (comme l'image de référence) |
| Vue | De 3/4, légèrement plongeante (environ 30°). **Alliés vus de dos** (ils avancent vers le Nexus), **ennemis vus de face** |
| Lumière | Lune en haut à droite : reflets froids bleu-lavande à droite, ombres violettes à gauche |
| Contour | 1 px sombre (`#120e1a`), sans anticrénelage ni dégradé lisse |
| Palette | 16 couleurs maximum par sprite, issues de la palette commune (§2) |
| Cadrage | Personnage entier, centré, **pieds sur le bord bas**, fond **transparent** |
| Interdits | Ombre au sol (le jeu l'ajoute), texte, décor, cadre |
| Images | 2 par personnage : `<nom>.png` (pas A) et `<nom>-2.png` (pas B, ou légère variation : cape, ailes, flamme) |
| Taille | La « toile » de chaque fiche, en pixels exacts. Le jeu met le sprite à sa hauteur en mètres, quelle que soit la résolution |
| Couleur d'élément | Pour les **invocations** (familier, fantassin, archer, golem, élite), dessiner en **gris neutre** les parties qui prennent la couleur de l'élément. Le jeu les recolore : noir → teinte foncée, gris moyen → couleur principale, blanc → reflet |

## 2. Palette commune

| Rôle | Couleurs |
|---|---|
| Contour, nuit | `#120e1a` `#1a1035` |
| Violets | `#3b2a6b` `#5a2a7a` `#8e62e0` `#b07cff` |
| Bleus nuit | `#1d2f5a` `#2f4f8f` |
| Magie | `#4fe3d2` (cyan) `#9ff0ff` (lueur) `#ffffff` (cœur) |
| Turquoise | `#1f5a66` `#2f8f9a` |
| Mousse, forêt | `#22301a` `#3f5a30` `#4f6b3a` `#7faa4a` |
| Pierre | `#5a5670` `#8a86a0` |
| Acier | `#7a849c` `#c8d0e0` |
| Bois, cuir | `#3a2e2a` `#6a4a2a` `#8a5a2b` |
| Or | `#d8b048` `#f2c46b` |
| Corruption | `#ff3a5a` (yeux) `#d93cf2` (magenta) |
| Os, peau | `#e8e4d8` `#f0d0b0` |

## 3. Méthode avec un générateur d'images

1. Coller le **prompt de style** (§4), puis la **description** du personnage (§5).
2. Joindre en référence `docs/art/style-reference-01.jpg` (pour le style) et `docs/sprites/reference/<nom>.png` (pour la silhouette et les proportions).
3. Générer et choisir une image. Demander ensuite la 2e image : *« same character, same palette, next walking frame (legs swapped) »*.
4. Réduire chaque image à la **taille de toile** en interpolation « plus proche voisin ». Nettoyer si besoin les pixels isolés et le fond, par exemple dans Aseprite, Pixelorama ou LibreSprite (les deux derniers sont gratuits).
5. Déposer les fichiers dans `assets/sprites/` et me prévenir : je les intègre et ajuste les tailles en jeu.

## 4. Prompt de style (à mettre en tête de chaque demande)

```
16-bit pixel art game sprite, dark fantasy, moonlit night palette (deep violet,
midnight blue, moss green) with cyan and violet magic glow, light from the upper
right, crisp 1-pixel dark outline, no anti-aliasing, limited 16-color palette,
full body, three-quarter top-down view, centered, feet on the bottom edge,
transparent background, no ground shadow, no text, single character
```

## 5. Fiches

### Héros (vus de dos)

| Fichier | Personnage | Toile | Hauteur en jeu | Description |
|---|---|---|---|---|
| `mage` | **Toi**, Mage elfe, Porteur d'Écho | 32×48 | 1,5 m | Capuche bleu nuit, robe turquoise à liserés runiques cyan, ceinture de cuir. Bras droit levé tenant un bâton noueux surmonté d'un orbe cyan lumineux. Cape qui flotte. Pas B : jambes alternées, cape qui ondule |
| `brann` | **Brann Forgecœur**, Nain chevalier | 32×40 | 1,25 m | Trapu. Casque d'acier à cornes, pointes de barbe rousse tressée visibles sur les côtés, cape rouge, grand bouclier rond en bois cerclé d'or porté dans le dos, bottes épaisses |
| `sylwen` | **Sylwen**, Elfe archère (Vigiles Sylvestres) | 28×46 | 1,45 m | Élancée. Capuche verte d'où dépassent des oreilles pointues, longue tresse blonde, carquois de cuir aux flèches à plumes blanches, arc long en bois dans la main gauche, tunique verte |

**Prompts (anglais, après le prompt de style)**
- `mage` : *a hooded elven mage seen from behind, deep blue hood, flowing teal robe with glowing cyan rune trim, brown leather belt, right arm raised holding a gnarled wooden staff topped with a glowing cyan orb, cape fluttering*
- `brann` : *a stout dwarf knight seen from behind, horned steel helmet, braided ginger beard tips showing at the sides, red cape, large round wooden shield with a gold rim strapped on his back, sturdy boots*
- `sylwen` : *a slender elf archer seen from behind, green hood with pointed ears poking out, long blonde braid, leather quiver with white-fletched arrows, wooden longbow in her left hand, green tunic and boots*

### Invocations (vues de dos ; zones à recolorer en gris neutre)

| Fichier | Unité | Toile | Hauteur | Description |
|---|---|---|---|---|
| `familiar` | Familier arcanique (Mage) | 16×20 | 0,64 m | Petit esprit encapuchonné et rond, noyau blanc lumineux dans le dos, petites jambes. Corps entier en gris neutre |
| `knight` | Fantassin (Brann) | 16×22 | 0,75 m | Petit soldat casqué, épaulières d'acier, tabard en gris neutre, petit bouclier de bois cerclé d'or au bras gauche |
| `archer` | Archer spectral (Sylwen) | 16×22 | 0,75 m | Archer à capuche vert pâle translucide, cape en gris neutre, arc tenu à droite |
| `skeleton` | Squelette relevé (Ombre) | 16×22 | 0,7 m | Squelette vu de dos, os ivoire, légère lueur violette (pas de recoloration) |
| `golem` | Golem élémentaire (Champion) | 32×32 | 1,0 m | Golem massif en pierre grise, bras épais ; fissures et noyau en gris neutre (deviennent lumineux selon l'élément) |
| `fusion` | Élite fusionnée | 24×24 | 0,66 m | Esprit-cristal en étoile à 4 branches, très lumineux, en gris neutre avec le centre blanc |

**Prompts**
- `familiar` : *a small round hooded magic spirit seen from behind, bright white core, tiny legs, drawn entirely in neutral greys*
- `knight` : *a small armored foot soldier seen from behind, steel helmet and pauldrons, neutral grey tabard, small wooden shield with gold rim on the left arm*
- `archer` : *a small spectral archer seen from behind, translucent pale green hood, neutral grey cloak, bow held in the right hand*
- `skeleton` : *a small risen skeleton seen from behind, ivory bones, faint violet glow*
- `golem` : *a hulking stone golem seen from behind, thick arms, grey stone body with cracks and a core drawn in neutral light greys*
- `fusion` : *a glowing four-pointed star crystal spirit, white center, neutral grey facets*

### Ennemis de la zone 1 (vus de face)

| Fichier | Ennemi | Toile | Hauteur | Description |
|---|---|---|---|---|
| `mushroom` | Champignon sauteur (sbire) | 20×18 | 0,58 m | Champignon corrompu au chapeau violet à pois lavande, pied crème, yeux rouges luisants, petits pieds |
| `rabbit` | Lapin-épine (coureur) | 20×18 | 0,62 m | Lapin gris-brun, épines pâles sur le dos, yeux rouges, oreilles dressées |
| `bear` | Ours-mousse (brute) | 36×30 | 0,9 m | Ours massif couvert de mousse et de lichen vert, yeux rouges, museau clair, griffes |
| `pixie` | Pixie sombre (tireur) | 20×16 | 0,52 m | Petite fée sombre, ailes violettes translucides, robe violette, yeux magenta luisants, flottante. Pas B : ailes baissées |
| `turtle` | Tortue-souche (porte-bouclier) | 28×18 | 0,58 m | Tortue dont la carapace est une souche d'arbre moussue, pattes vertes, yeux rouges |
| `wisp` | Feu-follet (lanceur) | 14×20 | 0,7 m | Flamme de lumière dorée avec deux petits yeux sombres. Pas B : flamme qui vacille |
| `dryad` | Dryade flétrie (soigneuse) | 22×36 | 1,05 m | Esprit-arbre élancé à l'écorce desséchée, bras-branches, yeux vert vif luisants, couronne de brindilles |

**Prompts**
- `mushroom` : *a corrupted mushroom creature facing the viewer, purple cap with lavender spots, cream stem, glowing red eyes, tiny feet*
- `rabbit` : *a thorny rabbit facing the viewer, grey-brown fur, pale thorns along its back, red eyes, ears up*
- `bear` : *a hulking bear covered in moss and green lichen facing the viewer, glowing red eyes, pale muzzle, claws*
- `pixie` : *a small dark fairy facing the viewer, translucent violet wings, violet dress, glowing magenta eyes, hovering*
- `turtle` : *a turtle whose shell is a mossy tree stump, facing the viewer, green legs, red eyes*
- `wisp` : *a will-o'-the-wisp facing the viewer, golden light flame with two small dark eyes, soft glow*
- `dryad` : *a withered tree spirit facing the viewer, slender dry bark body, branch arms, glowing bright green eyes, crown of twigs*

### Ennemis de la zone 2 · Collines d'Ambre (vus de face, plein jour)

Les sprites générés sont dans `scripts/gfx/sprite_atlas.gd`. Ils sont tous remplaçables par `assets/sprites/<nom>.png` et `<nom>-2.png`.

| Fichier | Ennemi | Toile | Hauteur | Description |
|---|---|---|---|---|
| `pillard` | Pillard (sbire) | 14×14 | 0,62 m | Humain des steppes, capuche de fourrure fauve, foulard rouge, dague |
| `wolf_rider` | Chevaucheur de loup (coureur) | 20×13 | 0,78 m | Gobelin vert sur un loup gris aux yeux rouges, lance |
| `ogre` | Ogre d'ambre (brute) | 20×15 | 1,05 m | Ogre massif à la peau ocre, épaulières d'ambre, pagne de cuir |
| `slinger` | Frondeur (tireur) | 14×14 | 0,6 m | Humain à capuche olive, fronde levée |
| `clan_guard` | Garde de clan (porte-bouclier) | 16×15 | 0,72 m | Orc casqué derrière un grand pavois de bois cerclé d'or |
| `storm_shaman` | Chaman d'orage (lanceur) | 16×15 | 0,85 m | Orc en peaux, coiffe d'os, yeux cyan, bâton surmonté d'un éclair |
| `bonesetter` | Rebouteux possédé (soigneur) | 16×15 | 0,8 m | Robe violette, yeux magenta, bâton d'os |
| `varg` | **Varg**, chef pillard (mini-boss) | 22×16 | 1,45 m | Casque à cornes, cape rouge, hache |
| `gharok` | **Gharok**, seigneur de guerre (boss) | 28×22 | 2,7 m | Orc géant possédé : casque d'acier à grandes cornes, yeux magenta, cuirasse, grande hache |
| `war_banner` | Bannière de guerre | 10×18 | 1,6 m | Étendard rouge et or sur une hampe plantée |
| `storm_totem` | Totem d'orage | 9×16 | 1,2 m | Totem de bois sculpté, couronne d'éclairs |
| `caravan` | Chariot de vivres (escorte) | 22×14 | 1,3 m | Chariot bâché crème, roues de bois |
| `pylon` | Pylône d'ambre (décor) | 9×15 | 1,6 m | Cristal d'ambre sur un socle de pierre |

## 6. Après livraison
- Je vérifie chaque sprite en jeu (taille, lisibilité, animation) et ajuste au besoin `HEIGHT_M` dans `scripts/gfx/sprite_atlas.gd`.
- Si un sprite généré est plus détaillé que sa toile, je peux augmenter la résolution de rendu de l'arène pour en profiter.
- Prochains sprites : boss Sylvarche, compagnons des actes suivants, icônes de sorts et d'objets.

## 7. Portraits de dialogue (étape 10.2)

Les portraits actuels sont générés par code (`scripts/gfx/portrait_art.gd`). Pour en remplacer un, déposer une image dans `assets/portraits/` :
- `<perso>-<expression>.png` pour une expression précise ;
- `<perso>.png` pour toutes les expressions de ce personnage.

| Règle | Valeur |
|---|---|
| Toile | **64×64**, fond transparent, buste de face (épaules en bas de l'image) |
| Lumière, contour, palette | Comme les sprites (§1 et §2) : lune en haut à droite, contour `#120e1a` de 1 px |
| Expressions | `neutre`, `joie`, `colere`, `triste`, `surpris` |
| Personnages | `porteur` (toi : capuche bleu nuit, visage dans l'ombre, regard cyan), `sylwen`, `brann`, `ancien` (Ancien Tobin, doyen de Lysbourg), `cerf` (Grand Cerf purifié, bois lumineux), `sylvarche` (visage d'écorce ; `joie` = purifiée), `fee`, `voix` (silhouette couronnée, regard violet) |

**Prompt** (après le prompt de style, en remplaçant « full body » par « bust portrait, facing the viewer, 64x64 ») :
- `sylwen` : *portrait of a young elf archer, green hood, long pointed ears, blonde braid over the right shoulder, green eyes, leather quiver strap*
- `brann` : *portrait of a stout dwarf knight, horned steel helmet, big braided ginger beard with gold rings, red cape, steel pauldrons*
