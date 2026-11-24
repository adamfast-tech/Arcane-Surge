# Acte 6 · Le Sang (narration de la zone 6, étape 16.2)

> Suite de [`34-narration-zone5.md`](34-narration-zone5.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Trahison et rédemption : [`06-monde.md`](06-monde.md) §4.1. Zone jouable : [`37-zone6.md`](37-zone6.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Ignara** | Draconique, Mage. Trouvée dans un œuf au pied de la Montagne de Braise, élevée à Braisemont. Audacieuse, fière, colérique ; elle chasse les Cultistes du Wyrm. **5ᵉ compagnon** | Cheveux cuivre en flammes, cornes recourbées, écailles sur les tempes, yeux d'ambre fendus, robe cramoisie, braises au creux des mains |
| **La Mère-Dragon** | Gardienne de la Montagne de Braise ; son souffle gardait la forêt vivante. La mère d'Ignara | Tête de dragonne dorée, crête, grandes cornes |
| **Le Wyrm de cendre** | Dragon qui a bu le Surge ; réveillé et nourri par « M. », gardé par le Héraut | Tête calcinée, fissures de braise, gueule de feu |
| Mère Hulda | Celle qui a élevé Ignara (6-6) | — |
| La Voix inconnue | Revient en 6-5 | — |

## Ce que l'acte révèle

- La forêt brûle sans mourir parce que le Wyrm a volé le feu de la Mère-Dragon et le nourrit de Surge.
- Le Wyrm « entend » les rancunes et pose sa **Marque** sur ceux qui l'écoutent.
- Le croissant du **Héraut** est gravé sur les autels du Wyrm (6-8). Une page de « M. » dit qu'il a donné « du temps » au dragon pour qu'il garde sa porte : **2ᵉ Fragment de Morvaen**.
- Ignara est la fille de la Mère-Dragon, cachée parmi les hommes quand le Wyrm s'est levé.
- Le Wyrm reconnaît dans le Sceau du joueur « le temps volé, comme celui de l'homme au croissant ».

## Déroulé

| Niveau | Temps fort |
|---|---|
| 6-1 | La forêt qui brûle sans mourir. Le compagnon marqué (s'il y en a un) évite ton regard. **Ignara rejoint le groupe** |
| 6-2 | Les Cultistes nourrissent l'incendie ; le feu de la Mère |
| 6-3 | Les dragons malades ; un wyverneau parle de la Marque |
| 6-4 | Les coulées de magma ; « l'un de vous porte sa Marque » |
| 6-5 | Le Drake ancien vaincu : « Fille des cendres… réveille la Mère ». Retour de la Voix |
| 6-6 | Braisemont évacué ; Mère Hulda (Ignara +5, Humains +5) |
| 6-7 | Le Nid des Phénix : **choix mineur** |
| 6-8 | Les autels au croissant ; la page de « M. » (Fragment de Morvaen +1) |
| 6-9 | La citadelle, puis la Mère-Dragon enchaînée : **choix** |
| 6-10 | La trahison (ou la résistance) ; le Wyrm ; **✦ choix majeur**. Fin de l'acte 6, vers la Cité Engloutie |
| 6-R | **Les Cendres du Pardon** (quête bonus de rédemption) |

## Choix

### 6-7 · Le dernier phénix

| Option | Effets |
|---|---|
| A. L'épargner et le soigner | `s1.phenix_epargne`, Ignara +10, Sylwen +5 ; devant le Wyrm, le phénix couve la Barrière (bouclier +30) |
| B. Prendre ses plumes | `s1.plumes_phenix`, Ignara −10, Krag +5, **Plume de phénix** épique |

### 6-9 · La Mère-Dragon

| Option | Effets |
|---|---|
| A. Sceller un pacte | `s1.pacte_dragons`, Dragons +30, Ignara +10 ; le Wyrm commence à 85 % de ses PV ; des dragons alliés dans l'acte 10 |
| B. Voler l'Œuf de cendre | `s1.oeuf_vole`, Dragons −40, Ignara −40, Corruption +10, **Œuf de cendre** (charme unique légendaire : Puissance +8, Esprit +8, Destin +4, Feu) ; dragons hostiles dans les zones 7 à 10 |

### ✦ 6-10 · Trahison et rédemption

**La Marque du Wyrm** (`Story.pick_traitor`, au début de 6-1) : parmi les compagnons recrutés, celui dont la loyauté est la plus basse, sous 25, porte la Marque (`s1.traitre`, `s1.traitre_<id>`). Ignara, qui arrive après, ne peut pas la porter. Exemples : Krag recruté avec 20 de loyauté (2-10 B), Sylwen après la Sylvarche abattue (1-10 B).

**Avant le Wyrm** (`Story.betrayal`, au début de 6-10) :
- si la loyauté du compagnon marqué est remontée à **40**, il résiste (`s1.marque_resistee`, loyauté +10) : pas de trahison ;
- sinon, il disparaît dans la nuit (`s1.trahison`) et n'est plus dans le groupe.

**Le combat** (capacité `traitor` en phase 3 du Wyrm) :
- le compagnon se dresse aux côtés du Wyrm, avec ses couleurs de cendre : il lance des boules de feu qui laissent des foyers ;
- **à 0 PV, la Marque se brise** : le compagnon reste à terre, les coups ne l'atteignent plus et les invocations l'ignorent ;
- **achever** : un sort de dégâts lancé par le joueur, une fois le compagnon à terre, le tue (`s1.traitre_tue`, `s1.mort_<id>`). Les sorts des autres compagnons ne l'achèvent pas ;
- s'il n'est pas achevé, la victoire l'épargne (`s1.traitre_epargne`), qu'il soit à terre ou encore debout quand le Wyrm tombe ;
- ces drapeaux passent de la simulation à l'histoire par `Profile.apply_battle` (`story_flags`), en cas de victoire seulement.

**Après le combat** :

| Situation | Choix | Effets |
|---|---|---|
| Épargné | A. Tendre la main | `s1.quete_pardon`, fil *Rédemption* : ouvre **6-R** |
| | B. Laisser partir | `s1.exile_<id>`, fil *Exilé* : le compagnon quitte le groupe (il pourra revenir à l'acte 9) |
| Achevé | — | Le compagnon est mort |
| Pas de trahison | C. Briser la Marque | `s1.marque_brisee`, Corruption −5, Ignara +5 |
| | D. Garder un éclat de la Marque | `s1.eclat_marque`, Corruption +10, Dragons −10 |

**6-R · Les Cendres du Pardon** (`z06_r01`, visible sur la carte quand `s1.quete_pardon` est posé) :
- seul le compagnon marqué combat à tes côtés (`"party": "traitre"`) contre la **Marque du Wyrm** (12 000 PV ; bouclier « seul le Givre » en phase 2) ;
- la victoire (`on_win` : `redeem`) le ramène, loyauté 60 (`s1.redemption_<id>`), avec l'**Héritage de cendre** (`s1.heritage_<id>`) :

| Héritage de cendre | Effet |
|---|---|
| Sang du Wyrm | Ses familiers deviennent de Feu ; dégâts +15 % |
| Souffle de cendre | Nouveau sort au Cercle : un souffle de braise qui flétrit les ennemis (soins reçus −50 %) pendant 4 s |
| Renaissance | Une fois par combat, quand la Barrière passe sous 25 %, il la ranime (+20) |
| Cosmétique | Ses couleurs de cendre (sprite `<id>_cendre`) |

La mini-branche d'arbre « Cendre » de la conception est ramenée ici à ces trois effets, propres aux compagnons. La règle « Changer le futur » (l'Héritage perdu si l'on remonte avant la trahison) attend l'Observatoire.

**Compagnon absent** (`Story.companion_lost`) : mort, parti, ou passé au Wyrm sans rachat. Il disparaît du Cercle et des combats.

## Ignara, 5ᵉ compagnon

- Draconique, Mage ; bot « agressif », sort **Souffle draconique** (colonne de feu). Rejoint le groupe à la fin de 6-1 (`s1.ignara_allie`), disponible dès 6-2.
- Au Cercle, son sort propre s'ajoute à ceux de sa voie. Si elle change de voie, elle prend ceux de la nouvelle.

## Répliques de combat

- Ignara : départ, phase du boss, Ultime.
- `{traitre}` dans les textes est remplacé par le nom du compagnon marqué ; le locuteur `traitre` prend son portrait.

## Illustrations

| Planche | Contenu |
|---|---|
| `cendres` | Forêt calcinée sous une lune rougie, dragon dans les fumées |
| `coulee` | Rivières de magma |
| `braisemont` | Le village en flammes et le gué |
| `nid` | Le nid des phénix sur son piton |
| `autels` | Les autels d'obsidienne au croissant violet |
| `citadelle` | La forteresse draconide aux bannières rouges |
| `caldeira` | La Mère-Dragon endormie, les chaînes brisées, l'Œuf de cendre |
| `antre` | L'antre du Wyrm, ossements et yeux dans l'ombre |

Elles sont dessinées dans `StoryArt._cendres` et `_cendres_cave`. Les portraits `ignara`, `mere_dragon` et `wyrm` sont dans `PortraitArt`.

## Aperçu web

- `?scene=z06_l09_outro` : la Mère-Dragon.
- `?scene=z06_l10_outro` : le choix majeur.

## Équilibrage du Wyrm (IA, Mage, 3 parties)

| Situation | Victoires |
|---|---|
| Sans trahison (Brann et Sylwen) | 2/3 |
| Krag passé au Wyrm | 1/3 |
| Krag passé au Wyrm, pacte et phénix épargné | 2/3 |
| 6-R, Krag seul à tes côtés | 3/3 |

## Vérifications

`tools/ui_smoke.gd` (`_act6_ok`) contrôle :
- les 22 scènes, les 3 portraits, les 8 planches et les sprites ;
- le choix du compagnon marqué (le plus bas sous 25), la résistance à 40, la trahison ;
- au combat : le traître absent du groupe, présent en phase 3, à terre à 0 PV, épargné par les coups et les sorts des compagnons, achevé par un sort du joueur ; l'épargne à la victoire ;
- 6-R fermé puis ouvert, avec le seul compagnon marqué ; le retour (loyauté 60, Souffle de cendre au Cercle, Héritage en combat) ; l'exil ;
- 6-7 A, 6-9 A et ✦ 6-10 C, joués à l'écran ; devant le Wyrm, le bouclier du phénix et les 85 % du pacte.
