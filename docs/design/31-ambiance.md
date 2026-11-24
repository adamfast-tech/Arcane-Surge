# Ambiance des menus (étape 13.7)

> Code :
> - `scripts/ui/ambience.gd` ;
> - `shaders/ui_ambience.gdshader`, `ui_vignette.gdshader`, `ui_title_shine.gdshader` ;
> - `RuneBox.rich` ;
> - `UiTheme.backdrop` (paramètre `mood`), `UiTheme.title`, `UiTheme.section` ;
> - `Profile.ambience_on`.

Les menus gardent la même mise en page : mêmes écrans, mêmes boutons, mêmes textes. L'option **Ambiance des menus : Enrichie** (Options, clé à molette ; activée par défaut) leur ajoute de la vie. Le combat ne change pas. **Sobre** rend les menus d'origine.

## Ce qui change

| Élément | Effet |
|---|---|
| Illustration de fond | Elle « respire » : zoom de 4 à 7 % et dérive de quelques pixels, très lents. |
| Lumière (shader) | Des rayons partent d'une source hors champ, en haut, et ondulent ; ils éclairent l'illustration et s'éteignent avant les panneaux. Une brume lumineuse dérive au pied de l'illustration. |
| Particules | Elles dépendent de la salle et flottent surtout dans l'illustration. |
| Vignette | Les bords s'assombrissent pour recentrer le regard. |
| Panneaux (`RuneBox`) | Fond en dégradé (éclairé d'en haut), reflet sous l'arête, double liseré, rivets aux biseaux. Le bouton principal (Continuer) a un halo doré. |
| Titres | Halo, contour sombre, et un reflet doré qui traverse lentement le texte (shader). |
| Sections | Un losange devant, un filet qui s'efface derrière. |
| Écrans | Chaque écran apparaît en fondu (0,25 s). |

## Ajouts (deuxième passe)

| Élément | Effet |
|---|---|
| **Havre-Aube à l'heure réelle** | Selon l'heure de l'appareil, Havre-Aube passe par 4 moments : l'aube (5 h à 8 h : rosée, lucioles), le plein jour (8 h à 17 h : illustration éclaircie, grands rayons, pollen doré), le crépuscule (17 h à 21 h : teinte orangée) et la nuit (21 h à 5 h : teinte bleutée, lucioles nombreuses). Le sous-titre le dit (« Refuge des Canalisateurs · au crépuscule »). |
| **Icônes des tuiles** | À la couleur de leur salle, sur un halo qui palpite : Carte en sarcelle, Équipement en orange, Entraînement en or, Bibliothèque en violet, Cercle en vert, Méditation en lune. |
| **Butin de fin de combat** | Les objets apparaissent un par un, chacun sur un faisceau de lumière à la couleur de sa rareté. Le faisceau est plus haut pour un objet rare, épique ou légendaire, qui jaillit en plus dans une gerbe d'étincelles. |
| **Carte du monde** | Une ambiance propre à chaque zone : lucioles et brume (zone 1), poussière dorée des steppes (2), brume épaisse du marais (3), neige qui tombe (4). Un chemin lumineux relie les niveaux : en or s'il est parcouru, en sarcelle vers le prochain niveau, éteint vers un niveau verrouillé. Une brume dérive sur les niveaux verrouillés. |
| **Éclat au toucher** | Option séparée, désactivée par défaut : une gerbe d'étincelles là où l'on touche, dans les menus (jamais en combat). |

## Ambiances et décors par salle

Chaque salle a son décor de fond (`RoomArt`, scripts/gfx/room_art.gd) :
- une scène en pixel-art, générée par code à la taille de l'écran (environ 3 à 4 px d'écran par pixel), agrandie au plus proche voisin ;
- le sujet est au centre, les côtés se remplissent selon la largeur (portrait ou paysage) ;
- l'illustration d'accueil (title.jpg) reste pour l'écran de connexion, le chargement et Havre-Aube.

| Salle | Décor | Ambiance | Particules |
|---|---|---|---|
| Havre-Aube | Illustration d'accueil, à l'heure réelle | Aube, jour, crépuscule ou nuit | Lucioles, pollen |
| Forge | Grand foyer et sa hotte, soufflet, outils pendus, établi aux runes flottantes, enclume et lame rougeoyante, baquet de trempe | Forge (orange) | Braises qui montent |
| Équipement | Armurerie : armure sur son mannequin devant une bannière, tapis rouge, torches, râteliers d'armes, boucliers et coffres | Forge | Braises |
| Entraînement | Grand arbre dont les nœuds dorés sont reliés comme un arbre de compétences, mannequins, cible et râtelier au crépuscule | Or | Poussière dorée |
| Salle de méditation | Lac sous la lune, plateforme au cercle lumineux et cristal flottant, lanternes de pierre, saule, bougies flottantes | Lune (argent et violet) | Éclats de lune |
| Bibliothèque | Murs d'étagères, fenêtre en arc sous la lune, échelle, pupitre au grimoire lumineux, livres volants, chandeliers | Arcane (violet) | Poussière arcanique |
| Le Cercle | Clairière de nuit, feu de camp, pierres levées gravées, tentes, guirlande de lanternes, bancs de rondins | Feu de camp | Braises |
| Sauvegardes | Archives voûtées : cristaux de mémoire sur leurs socles, grand cristal central | Arcane | Poussière arcanique |
| Options | Atelier : engrenages de laiton, sphère armillaire, fioles, chandelles | Or | Poussière dorée |
| Création | Cercle de pierres levées sur un plateau, cercle d'invocation, colonne de lumière, aurore | Lune | Éclats de lune |
| Préparation | Tente de commandement : table de guerre avec carte et pions, lanterne, bannières, ouverture sur le crépuscule | Feu de camp | Braises |
| Carte | Le paysage de la zone affichée (forêt, steppes, marais, pics, dunes), qui change avec l'onglet | Une par zone | Selon la zone |

`tools/room_sheet.gd` produit la planche de tous les décors (`--land` pour le paysage).

## Coût

- Un shader plein écran léger (bruit à 4 octaves), un second pour la vignette, et 26 à 90 particules sur le processeur selon la taille de l'écran.
- Un décor se génère en 10 à 60 ms à l'ouverture de la salle, puis reste en cache.
- L'option **Sobre** rend les menus d'origine, pour les vieux téléphones.

## Aperçu

Paramètres d'adresse :
- `&fx=1` active l'ambiance sans toucher à la sauvegarde ;
- `&hour=22` montre Havre-Aube à une autre heure ;
- `?room=map` ouvre la carte (et `forge`, `equipment`, `skills`, `library`, `meditation`, `circle`, `options`) ;
- `?level=z01_l03&solo=1&win=1` donne une victoire immédiate (écran de fin et butin).
