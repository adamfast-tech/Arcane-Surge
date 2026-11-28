# 43 — Son : musique, effets, voix

Le jeu avait des images, pas de son. Il a maintenant :
- des musiques composées pour chaque zone, les boss, les cinématiques et les menus ;
- un son propre à **chaque sort** (447 sorts, 447 signatures différentes) ;
- les sons du combat (tirs de classe, coups, morts, Barrière, Nexus, attaques annoncées, cris des boss) ;
- les voix des personnages pendant les cinématiques ;
- les sons de la mise en scène (éclairs, cloches, chaînes brisées, ombre d'ailes…).

Tout est **fabriqué par nos outils** (`tools/audio/`), sans banque de sons achetée ni enregistrement. Rien n'a pu être écouté pendant la fabrication. Chaque son a été vérifié par son spectre (images), sa sonie (mesurée) et la justesse de ses notes (rouleau de piano des partitions).

## Les outils

| Outil | Rôle |
|---|---|
| `tools/audio/synth.py` | Boîte à outils de synthèse. Oscillateurs à bande limitée, bruits blanc, rose et brun, crépitements à fenêtre douce. Enveloppes. Filtres fixes et filtre balayé à variables d'état « TPT » (stable à toutes les fréquences). FM, corde pincée (Karplus-Strong), objets résonants (cloches, verre, métal, os). Distorsion. Réverbération, chorus, délai et compression (pedalboard). Notes d'instruments réels par FluidSynth et la banque FluidR3 GM (licence MIT) : chœur, cordes, cors, harpe, célesta, timbales, taikos, cloches. Mixage aux bords adoucis, sonie mesurée, normalisation avec compresseur (jamais de saturation), encodage OGG Vorbis (ffmpeg), spectrogrammes. |
| `tools/audio/sfx_bank.py` | Les effets : 33 familles de sorts, cris des créatures, tirs de classe, combat, interface, évènements de l'arène. 246 sons, 24 kHz, 2,3 Mo. |
| `tools/audio/voices.py` | 29 voix : 22 syllabes par personnage (une par famille de lettres : « a », « é », « ba », « pi », « da »…), rangées dans une « bande » par voix. 0,5 Mo. |
| `tools/audio/music.py` | 15 morceaux écrits en Python (tonalité, mode, grille d'accords, mélodies, arrangement), joués par FluidSynth, polis (salle, compression, limiteur) et bouclés sans couture : la queue de réverbération est repliée sur le début. Stéréo, 24 kHz, 3,2 Mo. |

Régénérer : `python3 tools/audio/sfx_bank.py`, `voices.py`, `music.py` (`--only motif` pour un seul son, `--png dossier` pour les spectres). Prérequis : numpy, scipy, pedalboard, mido, matplotlib, ffmpeg (libvorbis), fluidsynth et `fluid-soundfont-gm`. Puis `godot --headless --path . --import`.

## Dans le jeu

| Code | Rôle |
|---|---|
| `scripts/core/audio.gd` (autoload `Audio`) | Trois catégories, Musique, Effets et Voix, toutes sur le **seul bus Master**. Sur le web, des bus ajoutés en cours de route ne sont pas raccordés à la sortie : plus aucun son, sur aucun appareil (corrigé, et contrôlé par le test de fumée). Le volume de chaque catégorie s'applique à chaque lecteur : son niveau de base, fondus compris, plus le réglage de sa catégorie et le général. Musique en fondu enchaîné, que l'on peut atténuer un instant pendant un grand sort. Sur le web, la sortie (bus Master) reste coupée jusqu'à ce que la sauvegarde soit chargée (volumes du joueur en place) et que le navigateur laisse jouer le son ; elle s'ouvre alors en fondu (0,8 s), sans clic si le navigateur l'autorise. L'état réel du son du navigateur est lu grâce à un petit script de la page (`html/head_include` dans `export_presets.cfg`, qui garde l'`AudioContext` de Godot) ; le jeu lui demande aussi de relancer le son. Si un navigateur exige malgré tout un premier toucher, n'importe quel toucher suffit (aucune bulle ni message), et la musique repart alors de son début. Sans cette porte, le son retenu pendant l'attente sortait d'un coup, fort et haché. Les volumes du profil sont réappliqués dès que le profil change (chargement de la sauvegarde locale ou du cloud) : l'audio démarre avant le chargement de la sauvegarde. Réserve de 28 lecteurs d'effets : un même son joue 3 fois au plus en même temps, avec un intervalle minimal par son contre les rafales. Sons en boucle pour une durée donnée (zones de sorts). Syllabes de voix lues par tranche. Aucun effet de bus : le web les ignore, tout est inclus dans les fichiers. |
| `scripts/core/snd.gd` (`Snd`) | Accès statique, sans risque là où l'autoload n'existe pas (outils). |
| `scripts/core/spell_audio.gd` (`SpellAudio`) | Signature sonore de chaque sort (voir plus bas). |
| `scripts/battle/battle_audio.gd` (`BattleAudio`) | Son du combat. Il lit les évènements de la simulation avant l'arène et compare son état d'une image à l'autre. |
| `scripts/ui/cine_audio.gd` (`CineAudio`), `voice_babble.gd` (`VoiceBabble`) | Son des cinématiques et voix des personnages. |
| `scripts/main.gd` (`_screen_sound`) | Musique de chaque écran. |

**Options** (clé à molette) : Son oui ou non, et quatre volumes (Général, Musique, Effets, Voix) par pas de 10 %, avec un son d'essai à chaque changement. Le réglage est enregistré dans `options.sound` et `options.vol`.

## Un son pour chaque sort

Chaque sort a une **famille de timbre**. Elle vient de sa discipline de classe, sinon de son école, sinon de son élément, et pour certains types de son type (soin de Barrière, bouclier, purification, mur, séisme…).

Les 33 familles :
- Feu, Givre, Foudre, Nature, Ombre, Lumière, Arcane, Terre ;
- Poison, Sang, Os, Âmes, Maléfice, Morts ;
- Flèche, Piège, Astral, Bêtes ;
- Lame, Spectre, Garde, Hache, Cri, Clan, Séisme, Chevalier, Forteresse, Justice ;
- Soin, Anges, Purification, Sacré, Tempête.

Chaque famille a un lancement, un impact léger, un gros impact, une boucle (zones qui durent) et, pour certaines, un projectile.

Par-dessus, chaque sort reçoit :
- un **accent** quand son élément diffère de sa famille : une flèche de feu est une flèche plus du feu ;
- une **hauteur** : celle de son rang (Novice plus aigu, Interdit plus grave), puis 13 crans de 1,5 % tirés de son identifiant ;
- une **touche d'attaque** parmi celles qui vont à sa famille : scintillement, verre, tintement, souffle, coup sourd, cliquetis, murmure ;
- un **volume** selon son rang ;
- les **couches de prestige** : montée orchestrale pour l'Archimage ; pour l'Interdit, un chœur grave, un souffle inversé et la musique qui s'efface un instant ;
- s'il invoque, le cri de ses créatures : os, loups, ours, faucon, cerf, anges, chevaliers, lames, guerriers, totems, géants, golem, esprits, cristal, néant, machine.

Si deux sorts sonnaient pareil, le second (dans l'ordre des identifiants) monte d'un cran jusqu'à être unique : 447 sorts, 447 signatures.

Les sons suivent l'animation du sort :

| Phase | Son |
|---|---|
| Lancement | Lancement de la famille, touche d'attaque, couches de prestige ; cor pour un renfort ; ultime |
| Projectile | Souffle du projectile : boule de feu, éclat de glace, éclair, flèche, lame, hache |
| Impact | Impact léger ou gros impact (selon le rayon et le rang), et l'accent de l'élément |
| Zone qui dure | Impact, puis la boucle de la famille pendant toute la durée, puis un fondu |
| Foudre, rayon, colonne, vague, bouclier, séisme | Tonnerre, rayon qui vibre, souffle, onde, bouclier qui monte, grondement |
| Invocation | Le cri des créatures invoquées |

## Le combat

| Évènement | Son |
|---|---|
| Début | Musique de la zone (ou du boss : `boss_1` pour les zones 1 à 3, `boss_2` pour les zones 4 à 7). |
| Tir de classe | Squelettes qui sortent de terre, luciole, corde d'arc, onde d'épée, orbe de lumière, bouclier qui tournoie, haches. Plus bas pour les compagnons. |
| Coups, morts | Coups et chutes variés, limités en rafale. |
| Barrière, Nexus | Barrière frappée, cœur qui bat quand elle est basse, Nexus qui tinte, éclats quand il tombe. |
| Attaques annoncées | Alarme à l'annonce. À l'impact : tentacule, souffle de feu, venin, vague, avalanche, passage de dragon. |
| Boss | Un cri propre à chaque boss à son arrivée et à chaque phase, avec la musique qui s'efface un instant ; un cri plus grave à sa chute. 19 cris : dragon, wyrm, bête, loup, ours, golem, hydre, arbre, sphinx, créature des mers, kraken, mort-vivant, orc, insecte, cerf, phénix, démon, esprit, petite créature. |
| Surge pleine, Champion | Montée scintillante, fanfare. |
| Fin | Fanfare de victoire ou complainte de défaite ; la musique s'éteint. |

## Les cinématiques

- **Musique de la scène** :
  - `cine_calm` (paisible), `cine_mystery` (mystère), `cine_tension` (danger), `cine_heroic` (fin d'acte, serment) ;
  - elle suit l'humeur du décor, puis l'étalonnage des répliques fortes (rouge et sombre : danger ; violet : mystère ; or : héroïque), pas plus d'un changement toutes les 10 s ;
  - le carton-titre de fin d'acte joue la musique héroïque et une fanfare.
- **Effets de mise en scène** : 110 effets ont un son (`CineAudio.FX`), par exemple :
  - éclair : tonnerre ; sceau : sort sacré ; chaînes brisées : verre qui éclate ;
  - ombre d'ailes : battements et cri ; cloche : gong ; souffle du dragon ; tentacules ;
  - chant des sirènes ; Marée noire ; pages ; enclume…
- **Gestes** : coup porté, blessure, chute, sort, échos.
- **Sujets** : la créature au centre rugit, encaisse, tombe, apparaît ou s'efface avec son cri (Cerf, Sylvarche, Mère-Dragon, Wyrm, Léviathan, Sphinx, Gharok, Varg…).
- **Voix des personnages**, babillage à la « Animal Crossing », dans le style de l'Ancien Tobin : pendant que la réplique s'écrit, chaque lettre déclenche une courte syllabe nette de la voix du personnage, choisie d'après la lettre (« b » → « ba », « i » → « i », « t » → « té »…), si bien qu'un même mot sonne toujours pareil ; jamais sur un espace ni sur la ponctuation.
  - Débit : vif pour les gens (une syllabe toutes les 0,07 s environ, la fée encore plus vite), lent et grave pour les grandes créatures (le Grand Cerf, la Sylvarche, le Léviathan, le Wyrm : 0,19 à 0,22 s, syllabes deux fois plus longues ; la Mère-Dragon, l'Ourdisseur, Gharok, le Sphinx entre les deux).
  - Hauteur : plus aiguë quand il est joyeux (+7 %) ou surpris (+12 %), plus grave quand il est triste (−7 %) ; la fin d'une question monte, la fin d'une phrase descend, une exclamation sonne plus fort, la colère aussi.
  - Les lèvres des bustes bougent au rythme des syllabes : grandes ouvertes sur la syllabe, entrouvertes, puis fermées.
  - Le héros garde la même voix, à la hauteur de sa race : fée très aiguë, orc et nain graves.
  - Un personnage sans voix propre prend celle du héros, à une hauteur qui lui est propre. Le narrateur n'a pas de voix : on entend sa plume.

| Voix | Timbre |
|---|---|
| Brann, Durgan | Nain, grave et rauque |
| Krag, Gharok, Varg | Orcs et pillard : très graves, rugueux (Gharok le plus) |
| Sylwen, Ysolde | Elfes : claires, soufflées |
| Nyx | Sombre, un peu d'écho |
| Ignara | Chaude, une pointe de raucité (sang de dragon) |
| Ssareth | Reptilien : sifflantes |
| Thalren, l'Ancien | Hommes âgés : souffle, tremblement |
| Orrin | Spectre : écho, voix doublée |
| La Voix, l'Ourdisseur | Chuchotements doublés, réverbération |
| Le Sphinx | Résonante, trois voix mêlées, écho |
| Fées | Très aiguës, rapides |
| Sylvarche, le Grand Cerf, le Léviathan, le Wyrm, la Mère-Dragon | Créatures immenses : très graves, lentes, écho (le Léviathan étouffé par l'eau) |
| Prévôte, Aurèle, Vesper, Corvin, Morvaen, le héros | Humains, chacun sa hauteur et son timbre (Corvin nasillard) |

## Les écrans

| Écran | Musique |
|---|---|
| Carte | Carte |
| Tous les autres écrans (connexion, Havre-Aube, salles) | Havre-Aube (thème principal) |

Il n'y a plus d'ambiances sonores en boucle (retirées : leurs grains aigus évoquaient un verre qu'on tapote).

Dans la Bibliothèque, un sort ajouté au deck ou appris fait entendre sa signature. Chaque bouton créé par `UiTheme.button` fait un clic.

## Les musiques

| Morceau | Caractère |
|---|---|
| `havre` | Thème principal, ré majeur, 84 bpm. Mélodie écrite note à note : flûte, puis cor et violon ; harpe, cordes, violoncelle, timbales et célesta à la fin. |
| `map` | Sol majeur, 104 bpm : pizzicati, clarinette et hautbois. |
| `battle_z1` | Forêt : ré dorien, 116 bpm. Harpe en doubles croches, flûte, chœur. |
| `battle_z2` | Collines : la mixolydien, 132 bpm. Galop, violon des steppes, cuivres en accents. |
| `battle_z3` | Marais : mi phrygien, 100 bpm. Trémolos graves, clarinette, chœur. |
| `battle_z4` | Pics : si mineur, 120 bpm. Glockenspiel, cors, timbales. |
| `battle_z5` | Désert : mode hijaz sur ré, 112 bpm. Flûte de roseau, shamisen, percussions sur peau. |
| `battle_z6` | Forêt Cendrée : do mineur, 138 bpm. Taikos, cuivres graves, chœur. |
| `battle_z7` | Cité Engloutie : fa dièse dorien, 104 bpm. Voix « oh », marimba et harpe. |
| `boss_1`, `boss_2` | Mineur harmonique, 146 et 152 bpm. Ostinato, chœur, cuivres, timbales. |
| `cine_calm`, `cine_mystery`, `cine_tension`, `cine_heroic` | Musiques de fond des cinématiques. |

## Poids

Le pck passe de 4,4 Mo à environ 11 Mo : 6,8 Mo de son au total.

| Contenu | Poids |
|---|---|
| Effets | 2,3 Mo, 24 kHz |
| Voix | 0,27 Mo |
| Musique | 3,2 Mo, stéréo 24 kHz |

Les très petits fichiers OGG paient chacun environ 3 Ko d'en-tête : les syllabes de chaque voix sont donc rangées dans un seul fichier.

## Contrôles

`tools/ui_smoke.gd` (`_audio_ok`) vérifie :
- que chaque sort a tous ses sons et une signature unique ;
- que chaque son référencé existe : familles, tirs, cris, invocations, effets et gestes des cinématiques, musiques, voix ;
- que des sons sont vraiment partis pendant les combats et les cinématiques du test ;
- qu'il n'y a qu'un bus audio (le Master), le seul raccordé à la sortie sur le web.

Dans un navigateur, on peut suivre chaque source Web Audio jusqu'à la sortie : chaque source doit atteindre la destination avec un gain non nul (le contrôle qui a révélé le silence complet).

## Suite possible

- Musiques plus longues (sections B, C) et une musique par boss.
- Musique téléchargée à part sur le web, pour un premier chargement plus léger.
