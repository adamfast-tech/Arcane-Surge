# Cinématiques des dialogues (étape 18.1, version 2)

> Mise en scène des scènes de dialogue : décor animé, personnages en grands bustes qui parlent et réagissent, créatures en présence, effets, étalonnage. Format des scènes : [`07-narration.md`](07-narration.md) §6.2. Code : `scripts/ui/cine_stage.gd` (scène), `scripts/ui/cine_fx.gd` (calques d'effets), `shaders/cine_figure.gdshader`, `scripts/ui/dialogue_screen.gd` (déroulé), `PortraitArt.frame` (portraits animés).

Le chantier avance niveau par niveau. **Version 2 du moteur** (bustes, calques d'effets, étalonnage, carton-titre). **Mis en scène en détail : le prologue et toute la zone 1.** Le reste de la zone 1 garde ses premières indications, traduites par le nouveau moteur ; les zones 2 à 7 profitent de tout ce qui est automatique.

## Ce qui se joue sans indication

| Élément | Comportement |
|---|---|
| Ouverture | Bandes cinéma, sortie du noir. Avant une intro de niveau ou le prologue : **carton-titre** (numéro et nom du niveau, trait doré qui s'étire) ; la première réplique attend 2,2 s, un toucher l'abrège |
| Caméra | Lent travelling (le décor s'approche de 4 à 10 % et dérive) ; à chaque changement de décor, fondu enchaîné et nouveau départ |
| Ambiance | Selon le décor (`CineStage.PLATE_MOOD`) : lucioles et brume, poussière arcanique, braises, neige, sable, bulles ; **feuilles qui tombent** devant la scène en forêt et à Lysbourg |
| Personnages | **Grands bustes** (portraits 64×64 agrandis d'un facteur entier). **Deux au plus à l'écran** : celui qui parle et celui à qui il répond, un de chaque côté (le héros à gauche de préférence) ; quand un troisième parle, le plus ancien sort. Pendant le carton-titre, plan d'ensemble sans personnages : ils entrent ensuite. Ils entrent en glissant (léger rebond), respirent, parlent (bouche animée), clignent. Celui qui parle s'avance dans la lumière ; les autres reculent dans l'ombre, un peu ternis. Le panneau de texte ne garde que le nom |
| Humeur | Au changement d'humeur d'un personnage : **bulle d'émotion** posée sur sa tête et entraînée par elle (« ! » au-dessus, veine de colère au coin du crâne qui palpite, goutte sur la tempe qui glisse, note près du visage) et geste : saut avec écrasement, tremblement et pas en avant avec liseré rouge, petits bonds, affaissement et couleurs passées |
| Présence | Créatures et esprits, au centre, dans leur **aura**. **En pied** quand leur corps est dessiné (`FigureArt`, zone 1 : le Grand Cerf, la Sylvarche, la fée, Morvaen, la Voix, la Lanterne) : ils se tiennent **debout dans le décor**, les pieds au sol derrière le panneau et les bustes (le premier plan cache le bas du corps), la tête toujours dans le cadre ; seuls ceux qui volent (la fée) planent. Leur taille suit la scène (le Cerf est immense, la fée minuscule). Les autres (zones 2 à 7, pour l'instant) gardent un grand portrait qui flotte. Les sujets de scène connus (`stag`, `sylvarche`, `pixie`) prennent leur portrait ; les autres gardent leur sprite. Quand un esprit parle sans être le sujet, il apparaît en présence |

## Décors et personnages en pied (zone 1)

**Un décor par lieu** (`StoryArt._forest` et ses variantes) : Lysbourg (1-1), **le sentier des lucioles** (1-2 : chemin de terre qui serpente, bordé de pierres, lucioles), **la clairière brisée** (1-3 : souches éclatées, tronc couché, branches cassées), **le roncier** (1-4 : ronces maudites, deux pierres runiques), **la clairière aux fougères** (1-5 : rai de lune au milieu, grandes fougères), **le cercle des fées** (1-6 : anneau de champignons lumineux), le pont (1-7), la Tour du Croissant, la Source (1-8), le Cœur de la Forêt (1-9), la Sylvarche (1-10), la forêt guérie. Les clairières laissent le centre libre pour la créature.

**Personnages en pied** (`scripts/gfx/figure_art.gd`) : chacun est dessiné **d'un seul tenant**, avec son anatomie (volumes ombrés en ellipses, membres modelés en cylindres qui s'affinent, contour sombre, reflet de lune) — pas un portrait recollé sur un corps.

| Personnage | Dessin |
|---|---|
| Grand Cerf | De trois quarts, tête vers nous : ramure de lumière, cou puissant, jabot clair, corps et croupe, cuisses, pattes fines aux genoux marqués, sabots ; traînées violettes quand il est corrompu |
| Sylvarche | Couronne en grappes (violette, verte une fois purifiée), branches maîtresses, tronc noueux qui s'évase, visage creusé dans l'écorce (orbites, regard, bouche creuse), racines |
| Fée | Ailes nervurées, robe en corolle, bras et jambes fines, visage qui parle et cligne ; elle vole |
| Morvaen | Capuche profonde au regard turquoise, robe à plis et pan clair, ceinture d'or, une main sur le bâton à l'orbe |
| La Voix | Ombre couronnée au regard violet, robe qui se dissout vers le sol en volutes |
| Lanterne de l'Aube | Accrochée à sa perche plantée dans le sol |

Placement : la tête au centre de l'écran (le corps peut déborder du cadre), les pieds au sol derrière le panneau et les bustes.

## Indications (données)

Facultatives, sur une réplique (`cam`, `fx`, `act`, `grade`, `emote`) ou dans l'en-tête d'une scène (`cast`, `grade`, `cam`). `cam` et `fx` acceptent une valeur ou une liste.

| Clé | Valeurs |
|---|---|
| `cam` | `push` (la caméra avance), `pull` (recule), `focus:<repère>` (s'approche d'un personnage ou du sujet), `kick` (à-coup amorti par un ressort), `tremble` (rare), `pan_left`, `pan_right`, `pan_up`, `reset`. Anciens noms acceptés : `zoom`, `zoom_out`, `punch`, `shake` |
| `fx` | `effet[@repère][:RRGGBB]`. **Effets propres à une scène** (jamais repris des sorts) : `seal` (le Sceau d'Écho se grave et laisse des échos), `spiral` (sortilège de Morvaen : cadran à rebours), `flux` (Surge canalisé : rubans convergents), `gate` (porte runique), `arrow` (flèche de semonce), `swarm` (lucioles), `clang` (choc de bouclier), `steam` (vapeur de colère), `thorns` (ronces des fées), `glitter` (poussière de fée), `hooves` (martèlement de sabots au loin), `drip` (lumière qui ruisselle), `ferns` (fougères qui volent), `lanes` (couloirs de charge), `timestop` (le temps se fige : bandes de distorsion, onde lente), `flicker` (flamme fragile), `wind` (coup de vent), `eyes` (yeux dans les fourrés), `veins` (veines de corruption sur le sol), `fountain` (jet d'eau), `heartbeat` (battement de cœur), `willo` (feux-follets), `cage` (cage de ronces, jusqu'à `shatter` qui la brise), `roots` (racines qui se tordent), `splinters` (éclats d'écorce), `renewal` (la forêt renaît). Lumière : `bloom` (halo), `ring` (onde), `shock` (onde au sol et poussière), `rays` (rayons tournants), `bolt` (éclair), `beam` (colonne de lumière), `crack` (faille qui se déchire dans le ciel), `slash` (entaille), `charge` (particules aspirées vers le repère), `burst` (gerbe d'étincelles). Matière : `wisps` (volutes qui montent), `dust`, `embers`, `leaves`. Écran : `fade` (sortie du noir), `white` (éclair blanc et halo). Anciens noms : `flash`, `lightning`, `sparkles` |
| Repères | un personnage (sa tête), `subject`, `center`, `sky`, `ground`, `left`, `right` ; par défaut, celui qui agit sur la réplique, sinon le sujet, sinon le centre |
| `act` | `{"qui": "action"}`. Bustes : `jump`, `hop`, `shake`, `hurt` (recul, éclat), `attack` (fente vers la créature avec traînée, entaille et étincelles ; sans créature, un pas décidé en avant), `glow` (éclat, liseré, particules), `cast` (comme `glow`, avec le Surge canalisé), `echo` (échos du temps : le personnage se dédouble en fantômes), `droop`, `kneel`, `fall`, `step`, `turn`, `rise` (annule une posture), `enter`, `exit`. Sujet (`subject`) : `roar`, `hit`, `glow`, `fall`, `rise`, `appear`, `fade` (se dissout en particules) |
| `grade` | Étalonnage du décor et des personnages, en fondu : `night`, `violet`, `warm`, `dawn`, `cold`, `red`, `green`, `dark`, `gold`, `none` |
| `emote` | `{"qui": "!"}` : `!`, `?`, `anger`, `drop`, `note`, `dots` |
| `title` | Carton-titre au milieu d'une scène (fin d'acte) : `"Acte 1 · L'Éveil"` |
| `cast` | Personnages présents dès le début de la scène : `["porteur", "sylwen"]` ou `[{"id": "brann", "side": "left", "hidden": true}]` |
| `subject` | Hors indications : `"portrait:<id>"` montre n'importe quel portrait en présence (ex. `portrait:morvaen`, silhouette teintée par `subject_tint`) |

Exemple (1-5, le Sceau) :

```json
{"act": {"porteur": "cast"}, "fx": ["beam@porteur:9ff0ff", "white"], "cam": "focus:porteur", "who": "narrateur", "text": "Une lumière brûle ta paume…"}
```

## Technique

- Les effets sont dessinés dans trois `SubViewport` de basse résolution (un pixel d'effet = 3 ou 4 pixels d'écran, comme le décor), agrandis sans lissage : `back` (derrière les bustes), `front` (devant : feuilles, bulles), `light` (additif : lueurs, rayons, cercles, éclairs). `CineFx` délègue le dessin à `CineStage.draw_layer`.
- Bustes et présence passent par `shaders/cine_figure.gdshader` : éclat coloré, ombre, couleurs passées, liseré de lumière sur le contour.
- La caméra déplace le décor (profondeur 1), la présence (0,7) et les bustes (0,25). L'à-coup est un ressort amorti, intégré en petits pas (une image lente ne le fait pas diverger).
- L'étalonnage teinte le décor, les bustes, la présence et le calque `back` ; un calque à fusion multiplicative noircissait tout en WebGL.

## Zone 1

| Scène | Mise en scène |
|---|---|
| Prologue | Morvaen en silhouette devant la Fracture, un cercle runique se trace et aspire la lumière ; la trame se déchire (éclair blanc, faille dans le ciel, onde au sol) et Morvaen se dissout ; volutes et rayons du Surge ; le Nexus aspire l'énergie (étalonnage rouge) ; le héros apparaît dans son cercle ; Lysbourg endormi (nuit), puis un éclair violet |
| 1-1 | Carton-titre ; ciel violet, éclair, l'Ancien sursaute ; volutes vers le pont ; le héros canalise (cercle, particules aspirées, caméra sur lui) ; cercle doré des portes runiques ; « Va ! » : le héros s'élance. Fin : rayons dorés, puis la forêt violette au loin, puis l'aube |
| 1-2 | Flèche de semonce de Sylwen, plantée aux pieds du héros (« ! ») ; l'essaim des lucioles ; fin : volutes violettes, Sylwen hésite (« … ») |
| 1-3 | Brann entre d'un coup de bouclier (choc métallique) ; goutte de sueur quand Sylwen parle de ses ronflements, vapeur de colère, notes amusées de Sylwen ; fin : poussière retombée, ronces maudites qui poussent du sol |
| 1-4 | La fée en présence, entourée de poussière scintillante ; une porte maudite envahie de ronces ; Brann pris dans les ronces ; le martèlement du Grand Cerf (le sol bat, la poussière saute) |
| 1-6 | Les fées sombres s'organisent ; le héros se prépare |
| 1-5 | Le Grand Cerf jaillit des fougères (feuilles qui volent), la lumière violette ruisselle de ses bois ; il baisse la tête et rugit, les **couloirs rouges** de sa charge clignotent au sol. Fin : la corruption s'échappe, il se relève ; **le Sceau** : colonne de lumière, le Sceau se grave sur la main du héros (cercle traversé d'une ligne) et laisse des échos ; « les échos du temps » : le héros se dédouble en fantômes qui glissent de part et d'autre |
| 1-6 (fin) | Le monde se fige (éclair blanc), la Voix fait trembler l'image |
| 1-7 | La flamme de la Lanterne vacille (halo, étincelles) ; un coup de vent la fait ployer ; des yeux rouges s'allument dans les fourrés (embuscade). Fin : la flamme avale le Nexus (halo et rayons dorés) ; la Tour du Croissant au loin, lumière froide, la caméra recule |
| 1-8 | Des veines violettes rampent sur le sol de la Source scellée ; Brann « tape ». Fin : **la Source rejaillit** (jet d'eau claire qui retombe en gouttes, onde), les lucioles reviennent en essaim, lumière d'aube |
| 1-9 | Le Cœur de la Forêt bat (double battement, la lumière enfle) ; des feux-follets dérivent ; la Sylvarche s'éveille (battement rouge, veines). Fin : les fées en **cage de ronces**, leur lumière goutte et s'épuise ; libérées, la cage vole en éclats dans une poussière de lumière ; abandonnées, Brann file et la fée s'affaisse |
| 1-10 | La Sylvarche se dresse en présence, ses racines se tordent au premier plan, son écorce suinte de violet ; son cœur souffre (battement rouge) ; les fées libérées reviennent en essaim. Fin : elle ploie (éclats d'écorce, poussière) ; **purifiée**, le Sceau se grave sur son écorce, lumière verte, la forêt renaît (feuilles et lueurs qui montent, lucioles, aube) ; **abattue**, Brann frappe (choc, éclats), Sylwen s'en va seule. Carton « Acte 1 · L'Éveil » |

## Revoir ou passer (missions déjà réussies)

- Une scène déjà vue ne se rejoue pas d'elle-même. Pour une mission déjà réussie qui a une intro ou une fin, l'écran de **préparation** (sous le choix Deck ou Tiroir) propose **Passer** (par défaut : droit au combat) ou **Revoir** (l'intro avant le combat, la fin après la victoire).
- Le choix est mémorisé dans le profil (`replay_scenes`) et vaut pour toutes les missions déjà réussies.
- Une scène revue (`DialogueScreen.replay`) suit les choix déjà faits sans les redemander et ne rejoue aucun effet (drapeaux, loyauté, objets).
- Une mission jamais réussie n'affiche pas ce choix : ses scènes non vues se jouent toujours.

## Outils

- Les indications de chaque zone sont listées dans `tools/cine/cues_zNN.py` et posées par `python3 tools/cine_cues.py data/dialogues/fr/zNN.json tools/cine/cues_zNN.py`, dans le texte du fichier de dialogues, sans changer sa mise en forme : chaque réplique visée voit ses anciennes indications remplacées, et relancer le script ne change rien.
- `tools/ui_smoke.gd` (`_cine_ok`) contrôle le vocabulaire des indications de toutes les zones (`CineStage.check_cues`), les images de bouche et de clignement de 5 portraits, puis joue le prologue et la zone 1 réplique par réplique (jamais plus de 2 personnages à l'écran).
- `tools/ui_smoke.gd` (`_replay_scenes_ok`) contrôle que le choix n'apparaît qu'une fois la mission réussie, que « Passer » mène au combat et que « Revoir » rejoue l'intro sans redemander le choix ni en rejouer les effets.
- Aperçu web : `?scene=prologue`, `?scene=z01_l01_intro`, `?scene=z01_l05_outro`. `&cdbg=back,front,light,figs` masque des calques (débogage).

## Suite

Zone 2, niveau par niveau, avec des effets écrits pour chaque scène (éclairs de l'orage des Collines, les clans orcs, Krag…), puis les zones 3 à 7.
