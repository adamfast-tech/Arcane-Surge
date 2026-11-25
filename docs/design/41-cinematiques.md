# Cinématiques des dialogues (étape 18.1, version 2)

> Mise en scène des scènes de dialogue : décor animé, personnages en grands bustes qui parlent et réagissent, créatures en présence, effets, étalonnage. Format des scènes : [`07-narration.md`](07-narration.md) §6.2. Code : `scripts/ui/cine_stage.gd` (scène), `scripts/ui/cine_fx.gd` (calques d'effets), `shaders/cine_figure.gdshader`, `scripts/ui/dialogue_screen.gd` (déroulé), `PortraitArt.frame` (portraits animés).

Le chantier avance zone par zone. **Version 2 du moteur** (bustes, calques d'effets, étalonnage, carton-titre). **Mis en scène en détail : le prologue, la zone 1 et la zone 2** (cinématiques et combats). Les zones 3 à 7 profitent de tout ce qui est automatique.

## Ce qui se joue sans indication

| Élément | Comportement |
|---|---|
| Ouverture | Bandes cinéma, sortie du noir. Avant une intro de niveau ou le prologue : **carton-titre** (numéro et nom du niveau, trait doré qui s'étire) ; la première réplique attend 2,2 s, un toucher l'abrège |
| Caméra | Lent travelling (le décor s'approche de 4 à 10 % et dérive) ; à chaque changement de décor, fondu enchaîné et nouveau départ |
| Ambiance | Selon le décor (`CineStage.PLATE_MOOD`) : lucioles et brume, poussière arcanique, braises, neige, sable, bulles ; **feuilles qui tombent** devant la scène en forêt et à Lysbourg |
| Personnages | **Grands bustes** (portraits 64×64 agrandis d'un facteur entier). **Deux au plus à l'écran** : celui qui parle et celui à qui il répond, un de chaque côté (le héros à gauche de préférence) ; quand un troisième parle, le plus ancien sort. Pendant le carton-titre, plan d'ensemble sans personnages : ils entrent ensuite. Ils entrent en glissant (léger rebond), respirent, parlent (bouche animée), clignent. Celui qui parle s'avance dans la lumière ; les autres reculent dans l'ombre, un peu ternis. Le panneau de texte ne garde que le nom |
| Humeur | Au changement d'humeur d'un personnage : **bulle d'émotion** posée sur sa tête et entraînée par elle (« ! » au-dessus, veine de colère au coin du crâne qui palpite, goutte sur la tempe qui glisse, note près du visage) et geste : saut avec écrasement, tremblement et pas en avant avec liseré rouge, petits bonds, affaissement et couleurs passées |
| Présence | Créatures et esprits, au centre, dans leur **aura**. **En pied** quand leur corps est dessiné (`FigureArt`, zone 1 : le Grand Cerf, la Sylvarche, la fée, Morvaen, la Voix, la Lanterne) : ils se tiennent **debout dans le décor**, les pieds au sol derrière le panneau et les bustes (le premier plan cache le bas du corps), la tête toujours dans le cadre ; seuls ceux qui volent (la fée) planent. Leur taille suit la scène (le Cerf est immense, la fée minuscule). Les autres (zones 3 à 7, pour l'instant) gardent un grand portrait qui flotte. Les sujets de scène connus (`stag`, `sylvarche`, `pixie`, `varg`, `gharok`) prennent leur portrait ou leur corps ; les autres gardent leur sprite de combat, **debout au sol** (pillards, gardes, chamans…), sans flotter. Quand un esprit parle sans être le sujet, il apparaît en présence |

## Décors et personnages en pied (zone 1)

**Un décor par lieu** (`StoryArt._forest` et ses variantes) : Lysbourg (1-1), **le sentier des lucioles** (1-2 : chemin de terre qui serpente, bordé de pierres, lucioles), **la clairière brisée** (1-3 : souches éclatées, tronc couché, branches cassées), **le roncier** (1-4 : ronces maudites, deux pierres runiques), **la clairière aux fougères** (1-5 : rai de lune au milieu, grandes fougères), **le cercle des fées** (1-6 : anneau de champignons lumineux), le pont (1-7), la Tour du Croissant, la Source (1-8), le Cœur de la Forêt (1-9), la Sylvarche (1-10), la forêt guérie. Les clairières laissent le centre libre pour la créature.

**Personnages en pied** (`scripts/gfx/figure_art.gd`) : **le haut reste leur portrait, tel quel** (mêmes traits, bouche, expressions) ; le bas le prolonge à partir de sa dernière ligne de pixels (chaque colonne garde sa couleur et son motif, un peu plus sombre vers le bas), sans coupure, puis prend sa forme.

| Personnage | Le bas du corps |
|---|---|
| Grand Cerf | Image peinte (`assets/figures/cerf.png`, fournie) : la tête du portrait et le corps entier de face, poitrail, pattes, sabots |
| Sylvarche | Le tronc descend, s'évase et plonge ses racines dans le sol ; les fissures (Surge violet, sève dorée une fois purifiée) continuent |
| Fée | La robe s'évase en corolle à l'ourlet ondulé, puis deux jambes fines ; elle vole |
| Morvaen | La robe tombe jusqu'au sol avec ses plis, les pieds dépassent de l'ourlet |
| La Voix | La robe d'ombre tombe et se dissout vers le sol |
| Lanterne de l'Aube | Accrochée à sa perche plantée dans le sol |
| Varg (zone 2) | Torse dans la tunique rouge du portrait, bras qui pendent (manches, mains nues), ceinture à boucle d'or, braies, bottes, sabre au fourreau |
| Gharok (zone 2) | Torse cuirassé sous les épaulières, bras d'orc massifs aux brassards de fer, hache de guerre en main, ceinture au crâne, pagne de fourrure rouge, jambes veinées de Surge |

Varg et Gharok parlent **en présence** (pas de buste), comme le Grand Cerf. Le torse sous un portrait est plus étroit que ses épaules (`FigureArt._torso`) : chaque colonne garde la couleur de la colonne au-dessus, avec de l'ombre sur les flancs ; les bras sont dessinés de part et d'autre.

Placement : la tête au centre de l'écran (le corps peut déborder du cadre), les pieds au sol derrière le panneau et les bustes.

## Combats de la zone 1 : un lieu par niveau

Chaque niveau se joue dans le lieu de ses cinématiques (`WorldArt.LEVEL_SCENE`, `WorldArt.scene`). Hors du pont (1-7), l'arène est **au sol de la forêt** : plus de chaussée au-dessus du vide, l'herbe arrive au niveau du chemin, la brume reste au ras du sol.

| Niveau | Lieu | Sol, bords et décor |
|---|---|---|
| 1-1 | Lisière de Lysbourg | Route de terre et ornières ; poteaux de bois ; chaumières aux fenêtres allumées, lanternes ; lumière chaude ; toits du village sur l'horizon |
| 1-2 | Sentier des lucioles | Chemin de terre ; sapins serrés ; lanternes et une nuée de lucioles |
| 1-3 | Clairière brisée | Herbe foulée, feuilles mortes ; souches pour piliers ; souches éclatées et troncs couchés ; arbres écartés |
| 1-4 | Roncier | Vrilles de ronces sur le sol ; pierres violettes ; buissons d'épines, deux pierres runiques allumées ; lueur violette |
| 1-5 | Clairière aux fougères | Herbe, pousses et reflets de lune ; grandes fougères ; lumière bleue de la lune |
| 1-6 | Cercle des fées | Chemin moussu, fleurs roses ; pierres de fée lumineuses ; deux anneaux de champignons lumineux ; aurore rose |
| 1-7 | Pont des ruines | La chaussée de pierre au-dessus du vide, la Tour du Croissant à l'horizon |
| 1-8 | La Source | Flaques ; pierres mouillées ; nappes d'eau et roseaux de part et d'autre |
| 1-9 | Cœur corrompu | Veines du Surge et éclats de cristal ; piliers de cristal lumineux ; cristaux violets ; arbres teintés de violet |
| 1-10 | Domaine de la Sylvarche | Racines sur le sol et sur les bords ; bois sombre ; l'arbre-mère sur l'horizon |

**Détails** (zone 1, hors du pont) :
- **Végétation en relief** (`WorldArt.foliage_atlas`, `shaders/foliage.gdshader`) : 12 éléments par lieu (touffes, fleurs aux couleurs du lieu, buisson, rocher moussu, fougère, cailloux, herbes hautes, brindilles, et deux détails propres : bottes de foin et tonneaux à Lysbourg, branches cassées et champignons dans la clairière, rameaux d'épines et pierre runique tombée au roncier, fleurs de lune aux fougères, champignons de fée, roseaux et nénuphars à la Source, éclats de cristal au Cœur, racines et champignons violets chez la Sylvarche). Environ 350 éléments : le long des bords du terrain, clairsemés sur le terrain, partout sur le sol de la forêt. Ils ondulent au vent ; certains luisent doucement.
- **Arbres** (`WorldArt.tree_atlas`) : sapins, feuillus (verts, olive dans la clairière, bleu-vert à la Source, violets là où règne le Surge), arbre mort au roncier, au Cœur et chez la Sylvarche, arbres lumineux au cercle des fées ; leur mélange suit le lieu.
- **Sol** : taches de couleur (bruit), brins d'herbe, cailloux, bords du chemin envahis d'herbe.
- **Ambiance** : feuilles qui tombent (violettes chez la Sylvarche et au roncier), fumée des cheminées de Lysbourg, reflets qui scintillent sur l'eau de la Source, lueurs qui pulsent (lanternes, pierres runiques, champignons, cristaux).

## Combats de la zone 2 : un lieu par niveau

Même principe qu'en zone 1 : chaque niveau des Collines d'Ambre se joue **au sol**, dans son lieu, en plein jour (ou sous l'orage).

| Niveau | Lieu | Sol, bords et décor |
|---|---|---|
| 2-1 | Route d'Ambre | Ornières, cailloux ; poteaux de bois ; chariots brûlés qui fument, bornes ; colonne de fumée noire à l'horizon |
| 2-2 | Moulins d'Ambreval | Chaume doré sur les bords ; moulins à vent, meules de foin ; vergers ; moulins sur la crête |
| 2-3 | Pylônes d'ambre | Terre craquelée aux veines d'ambre lumineuses ; poteaux coiffés d'ambre ; flèches d'ambre qui luisent ; arbres morts ; cristaux sur l'horizon |
| 2-4 | Gué de la Rivière-Sèche | Galets mouillés ; la rivière de part et d'autre, ses reflets ; roseaux ; totems du clan au passage |
| 2-5 | Repaire de Varg | Boue piétinée, os ; pieux coiffés de rouge ; tentes de peau, palissade, caisses d'ambre qui bourdonnent de violet, feux de camp et leur fumée ; braises |
| 2-6 | Campement de l'orage | Boue sombre, flaques ; ciel noir, **pluie et éclairs** (la lumière blanchit puis retombe) ; totems qui crépitent de bleu ; tentes des chamans |
| 2-7 | La caravane | Ornières et traces de sabots ; chariots bâchés, caisses, bornes, un moulin |
| 2-8 | Le Rebouteux | Herbes coupées, petits os ; tentes, séchoirs d'herbes et d'os, feux |
| 2-9 | Le Traité d'Ambre | Herbe foulée, fleurs des prés ; poteaux coiffés d'or ; **tentes et étendards bleus de la Prévôté à gauche, rouges des clans à droite** ; les deux camps face à face sur l'horizon |
| 2-10 | Fort de Gharok | Boue, cendres, os ; palissade haute, tours de guet allumées, étendards au crâne, feux ; le fort tout proche sous l'orage, pluie et éclairs |

Végétation : herbe sèche dorée (ou vert doré près des moulins et du gué), fleurs du lieu (coquelicots, boutons d'or, ambre), deux détails propres à chaque lieu (roue brisée et borne, gerbe et meule, éclat d'ambre et rocher veiné, roseaux et galets, os et caisse d'ambre, lance brisée et petit totem, herbes et crâne, fanions bleu et rouge). Elle ondule plus fort quand le vent des steppes souffle sur le niveau. Des brins de paille et des graines filent au vent.

## Indications (données)

Facultatives, sur une réplique (`cam`, `fx`, `act`, `grade`, `emote`) ou dans l'en-tête d'une scène (`cast`, `grade`, `cam`). `cam` et `fx` acceptent une valeur ou une liste.

| Clé | Valeurs |
|---|---|
| `cam` | `push` (la caméra avance), `pull` (recule), `focus:<repère>` (s'approche d'un personnage ou du sujet), `kick` (à-coup amorti par un ressort), `tremble` (rare), `pan_left`, `pan_right`, `pan_up`, `reset`. Anciens noms acceptés : `zoom`, `zoom_out`, `punch`, `shake` |
| `fx` | `effet[@repère][:RRGGBB]`. **Effets propres à une scène** (jamais repris des sorts) : `seal` (le Sceau d'Écho se grave et laisse des échos), `spiral` (sortilège de Morvaen : cadran à rebours), `flux` (Surge canalisé : rubans convergents), `gate` (porte runique), `arrow` (flèche de semonce), `swarm` (lucioles), `clang` (choc de bouclier), `steam` (vapeur de colère), `thorns` (ronces des fées), `glitter` (poussière de fée), `hooves` (martèlement de sabots au loin), `drip` (lumière qui ruisselle), `ferns` (fougères qui volent), `lanes` (couloirs de charge), `timestop` (le temps se fige : bandes de distorsion, onde lente), `flicker` (flamme fragile), `wind` (coup de vent), `eyes` (yeux dans les fourrés), `veins` (veines de corruption sur le sol), `fountain` (jet d'eau), `heartbeat` (battement de cœur), `willo` (feux-follets), `cage` (cage de ronces, jusqu'à `shatter` qui la brise), `roots` (racines qui se tordent), `splinters` (éclats d'écorce), `renewal` (la forêt renaît). Collines d'Ambre : `smoke` (fumée qui monte au loin), `arcs` (la foudre saute d'un pylône d'ambre à l'autre), `shieldwall` (un mur de pavois se dresse et frappe le sol), `howl` (hurlement des loups : ondes de son), `drums` (tambours de guerre : boum, boum, BOUM), `rain` (pluie d'orage), `banners` (bannières de guerre qui claquent, sur les bords du cadre), `pact` (le Traité : un ruban bleu et un rouge se nouent, l'or jaillit), `shadow` (le Surge se tord sous la peau), `coins` (pièces d'or jetées), `chant` (chant de la rebouteuse : volutes vertes et dorées), `sigils` (deux sceaux du Surge qui pulsent, jusqu'à `shatter`), `cheer` (vivats : chapeaux et fleurs en l'air), `bars` (cage de bois, jusqu'à `shatter`). Lumière : `bloom` (halo), `ring` (onde), `shock` (onde au sol et poussière), `rays` (rayons tournants), `bolt` (éclair), `beam` (colonne de lumière), `crack` (faille qui se déchire dans le ciel), `slash` (entaille), `charge` (particules aspirées vers le repère), `burst` (gerbe d'étincelles). Matière : `wisps` (volutes qui montent), `dust`, `embers`, `leaves`. Écran : `fade` (sortie du noir), `white` (éclair blanc et halo). Anciens noms : `flash`, `lightning`, `sparkles` |
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

## Zone 2

Un décor par lieu (`StoryArt._ambre`) : la route d'Ambre (chariots renversés, fumée noire), les moulins, la crête des pylônes (cristaux d'ambre reliés par la foudre), le gué de la Rivière-Sèche (lit de galets, totems), le repaire de Varg (crépuscule, feux), le campement de l'orage, la route de la caravane (le chariot de vivres, les moulins au loin), la hutte de la rebouteuse (fumée verte), le Traité (les deux camps), le fort de Gharok.

| Scène | Mise en scène |
|---|---|
| 2-1 | Le vent couche l'herbe, la fumée monte au loin ; un pillard au milieu de la route. Fin : Krag dans une **cage de bois** ; le Sceau tranche ses liens (le Sceau se grave, entaille, la cage vole en éclats) ; Krag repart dans le vent |
| 2-2 | Les moulins tournent à vide, rafales ; la prévôte s'avance. Fin : **vivats**, puis la fumée des clans au loin, la colère de la prévôte |
| 2-3 | La foudre court entre les cristaux (arcs dorés, puis violets) ; Krag de face. Fin : l'ombre du Surge sur le chef de son clan (étalonnage violet) |
| 2-4 | **Mur de boucliers** au gué ; Brann ravi. Fin : Krag abattu ; Varg arme les possédés (pièces d'or jetées) |
| 2-5 | Le repaire au crépuscule (braises) ; **Varg en pied**, il jette son or et lâche les loups (hurlement, yeux dans l'ombre), les couloirs rouges de sa charge. Fin : il s'effondre, une voix dans l'orage (éclair violet), le Sceau brûle la paume, le temps se fige quand la Voix parle |
| 2-6 | **Pluie**, éclairs sur les totems ; Krag face aux siens. Fin : le violet quitte les chamans (volutes), l'aube revient, Krag bondit de joie |
| 2-7 | Le chariot de vivres sur la route ; des yeux dans les fourrés, le hurlement des loups. Fin : **vivats** à Ambreval ; la prévôte et son deuil |
| 2-8 | Le **chant** de la rebouteuse possédée, deux **sceaux du Surge** qui pulsent ; une colonne de lumière. Fin : les sceaux volent en éclats, elle tombe à genoux, son chant redevient doré |
| 2-9 | **Tambours de guerre**, bannières ; la prévôte et Krag s'élancent chacun vers les siens. Fin : la fumée retombe ; les deux camps se déchirent ; le **pacte** (rubans bleu et rouge) au moment du choix |
| 2-10 | Le fort sous la pluie, bannières, tambours ; **Gharok en pied**, il rugit, éclair et ombre du Surge sous sa peau ; Krag, son fils ; selon le Traité : la prévôte s'élance, les chamans chantent, ou le pacte. Fin : Gharok tombe à genoux, l'ombre se tord ; Krag s'agenouille ; carton « Acte 2 · Les Alliances » |

## Revoir ou passer (missions déjà réussies)

- Une scène déjà vue ne se rejoue pas d'elle-même. Pour une mission déjà réussie qui a une intro ou une fin, l'écran de **préparation** (sous le choix Deck ou Tiroir) propose **Passer** (par défaut : droit au combat) ou **Revoir** (l'intro avant le combat, la fin après la victoire).
- Le choix est mémorisé dans le profil (`replay_scenes`) et vaut pour toutes les missions déjà réussies.
- Une scène revue (`DialogueScreen.replay`) suit les choix déjà faits sans les redemander et ne rejoue aucun effet (drapeaux, loyauté, objets).
- Une mission jamais réussie n'affiche pas ce choix : ses scènes non vues se jouent toujours.

## Outils

- Les indications de chaque zone sont listées dans `tools/cine/cues_zNN.py` et posées par `python3 tools/cine_cues.py data/dialogues/fr/zNN.json tools/cine/cues_zNN.py`, dans le texte du fichier de dialogues, sans changer sa mise en forme : chaque réplique visée voit ses anciennes indications remplacées, et relancer le script ne change rien.
- `tools/ui_smoke.gd` (`_cine_ok`) contrôle le vocabulaire des indications de toutes les zones (`CineStage.check_cues`), les images de bouche et de clignement de 5 portraits, puis joue le prologue et les zones 1 et 2 réplique par réplique (jamais plus de 2 personnages à l'écran).
- `tools/ui_smoke.gd` (`_replay_scenes_ok`) contrôle que le choix n'apparaît qu'une fois la mission réussie, que « Passer » mène au combat et que « Revoir » rejoue l'intro sans redemander le choix ni en rejouer les effets.
- Aperçu web : `?scene=prologue`, `?scene=z01_l01_intro`, `?scene=z01_l05_outro`. `&cdbg=back,front,light,figs` masque des calques (débogage).

## Suite

Zones 3 à 7, une par une : décors de combat par niveau, décors de cinématique par lieu, créatures et chefs en pied, effets écrits pour chaque scène.
