# Cinématiques des dialogues (étape 18.1)

> Mise en scène des scènes de dialogue : décor animé, acteurs sur scène, bouches qui parlent, actions et effets. Format des scènes : [`07-narration.md`](07-narration.md) §6.2. Code : `scripts/ui/cine_stage.gd` (scène), `scripts/ui/dialogue_screen.gd` (déroulé), `PortraitArt.frame` (portraits animés).

Le chantier avance zone par zone. **Fait : le moteur, le prologue et la zone 1** (70 répliques mises en scène). Les zones 2 à 7 jouent déjà le décor animé, les acteurs et les portraits vivants, mais sans indications propres.

## Ce qui bouge sans indication

| Élément | Comportement |
|---|---|
| Caméra | Lent travelling sur le décor : il s'approche de 5 à 10 % au fil de la scène et dérive ; sens inversé à chaque scène et à chaque changement de décor |
| Changement de décor | L'ancien décor s'efface sous le nouveau (fondu de 0,6 s), la caméra repart |
| Ambiance | Selon le décor (`CineStage.PLATE_MOOD`) : lucioles et brume en forêt, poussière arcanique (Fracture, Nexus), braises (forge, cendres), neige (Pics), sable (Désert), bulles et reflets (Cité Engloutie). Coupée si l'option « Ambiance enrichie » l'est |
| Acteurs | Les compagnons et le héros qui parlent entrent en scène depuis le bord (4 au plus, le plus ancien silencieux sort). Ils respirent ; celui qui parle sautille et s'anime pendant que son texte s'écrit, les autres restent dans l'ombre |
| Humeur de la réplique | surpris : saut · colère : tremblement · joie : double bond · triste : il s'affaisse |
| Sujet (créature, boss) | Il apparaît en grandissant, posé au fond de la scène, et respire. Avec un sujet, les acteurs se rangent sur les côtés |
| Portrait | La bouche s'ouvre et se ferme pendant que le texte s'écrit (fermée sur les espaces et la ponctuation) ; les yeux clignent toutes les 2,4 à 4,6 s. Les portraits sans bouche dessinée (Grand Cerf, Sylvarche, la Voix, dragons, Léviathan, Ourdisseur, Orrin) respirent en parlant |

Les acteurs : `porteur` (le sprite du héros, selon son apparence, sa race et sa classe), `brann`, `sylwen`, `krag`, `nyx`, `ignara`, `ssareth`. Le locuteur `traitre` prend le sprite du compagnon marqué.

## Indications (données)

Facultatives, sur une réplique (`"cam"`, `"fx"`, `"act"`) ou une scène (`"cast"`, `"cam"`). `cam` et `fx` acceptent une valeur ou une liste.

| Clé | Valeurs |
|---|---|
| `cam` | `zoom`, `zoom_out`, `reset`, `punch` (coup de zoom), `shake` (secousse), `tremble` (tremblement long), `pan_left`, `pan_right`, `pan_up` |
| `fx` | `flash` ou `flash:RRGGBB`, `white` (éclair blanc), `fade` (sortie du noir), `lightning` (double éclair et secousse), `sparkles[:RRGGBB]` (gerbe d'étincelles), `embers` (braises qui montent) |
| `act` | `{"qui": "action"}` — acteurs : `jump`, `hop`, `shake`, `hurt`, `attack` (bond vers le centre), `droop`, `kneel`, `glow`, `fall`, `exit`, `enter`, `rise` ; `subject` : `roar` (grossit, rougit, secousse), `hit`, `fall`, `glow`, `rise` |
| `cast` | Distribution présente dès le début de la scène : `["porteur", "sylwen"]` ou `[{"id": "brann", "x": 0.7, "hidden": true}]`. Avec `cast`, seuls ces acteurs montent sur scène |

Les étincelles partent de l'acteur (ou du sujet) qui agit sur la même réplique, sinon du centre.

Exemple (1-5, le Sceau) :

```json
{"act": {"porteur": "glow"}, "fx": ["white", "sparkles:4fe3d2"], "cam": "punch", "who": "narrateur", "text": "Une lumière brûle ta paume…"}
```

## Zone 1

| Scène | Mise en scène |
|---|---|
| Prologue | Sortie du noir sur la Fracture ; éclair blanc et secousse quand la trame se déchire ; étincelles du Surge ; tremblement sur les Nexus ; Lysbourg endormi, puis flash violet « Plus pour longtemps » |
| 1-1 | Flash violet et secousse au réveil ; le héros canalise, puis part au combat |
| 1-2 | Sylwen surgit (coup de zoom), le héros recule ; les lucioles |
| 1-3 | Brann frappe en entrant ; « Je ne ronfle pas » |
| 1-4 / 1-6 | Les fées brillent et rugissent ; le héros se prépare à purifier |
| 1-5 | Le Grand Cerf rugit (flash, zoom, secousse) ; apaisé, il se relève ; **le Sceau** : éclair blanc, le héros brille, gerbe turquoise |
| 1-6 (fin) | Le monde se fige (éclair blanc), la Voix fait trembler l'image |
| 1-7 | La Lanterne brille ; la Tour du Croissant au loin (zoom) |
| 1-8 | La Source jaillit (flash et étincelles) |
| 1-9 | La Sylvarche fait trembler le Cœur de la Forêt ; les fées libérées brillent, ou s'éteignent si on les abandonne ; Brann file |
| 1-10 | La Sylvarche se dresse, rugit ; purifiée elle brille (le héros aussi), la forêt guérit ; abattue, Brann frappe, Sylwen s'en va seule |

## Revoir ou passer (missions déjà réussies)

- Une scène déjà vue ne se rejoue pas d'elle-même. Pour une mission déjà réussie qui a une intro ou une fin, l'écran de **préparation** (sous le choix Deck ou Tiroir) propose **Passer** (par défaut : droit au combat) ou **Revoir** (l'intro avant le combat, la fin après la victoire).
- Le choix est mémorisé dans le profil (`replay_scenes`) et vaut pour toutes les missions déjà réussies.
- Une scène revue (`DialogueScreen.replay`) suit les choix déjà faits sans les redemander et ne rejoue aucun effet (drapeaux, loyauté, objets).
- Une mission jamais réussie n'affiche pas ce choix : ses scènes non vues se jouent toujours.

## Outils

- Les indications de chaque zone sont listées dans `tools/cine/cues_zNN.py` et posées par `python3 tools/cine_cues.py data/dialogues/fr/zNN.json tools/cine/cues_zNN.py`, dans le texte du fichier de dialogues, sans changer sa mise en forme (une indication déjà posée est laissée telle quelle).
- `tools/ui_smoke.gd` (`_cine_ok`) contrôle le vocabulaire des indications de toutes les zones (`CineStage.check_cues`), les images de bouche et de clignement de 5 portraits, puis joue le prologue et la zone 1 réplique par réplique (3 acteurs en scène au moins).
- `tools/ui_smoke.gd` (`_replay_scenes_ok`) contrôle que le choix n'apparaît qu'une fois la mission réussie, que « Passer » mène au combat et que « Revoir » rejoue l'intro sans redemander le choix ni en rejouer les effets.
- Aperçu web : `?scene=prologue`, `?scene=z01_l05_outro`, `?scene=z01_l10_intro`.

## Suite

Zones 2 à 7, une par une : indications de chaque scène, et quelques gestes propres aux zones (éclairs de l'orage des Collines, souffle des dragons, vagues de la Cité Engloutie).
