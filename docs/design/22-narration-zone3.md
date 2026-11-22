# Acte 3 · Les Cendres (narration de la zone 3, étape 12.2)

> Suite de [`17-narration-zone2.md`](17-narration-zone2.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Zone jouable : [`21-zone3.md`](21-zone3.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Nyx** | Fée assombrie du Cercle des Cendres, nécromancienne sarcastique. Rejoint le groupe en 3-6 | Ailes de phalène, cheveux cendrés, regard violet, pendentif d'os |
| **Vesper** | Gardien des Cendres, chef du Cercle | Masque d'os relevé, robe cendre, braise au collier |
| **Aurèle** | Inquisitrice de l'Ordre de l'Aube | Armure blanc et or, soleil de l'Aube |
| **Corvin** | Jeune adepte renégat ; il a relevé les morts du marais pour tuer l'hydre et a perdu leur contrôle | Capuche bleu-gris, rune violette sur la joue |
| La Voix inconnue | Revient en 3-5 | — |

## Déroulé

| Niveau | Temps fort |
|---|---|
| 3-1 | Arrivée au marais ; Nyx se présente : « Le Cercle veut voir le Porteur d'Écho » |
| 3-2 | Nyx guide le groupe : le feu et la glace contre le poison |
| 3-3 | Aurèle, de l'Ordre de l'Aube, met en garde contre le Cercle |
| 3-4 | Des morts relevés par un rituel ; le nom de Corvin apparaît |
| 3-5 | Le Crocodile-liche, gardien du gué réveillé ; la Voix se manifeste |
| 3-6 | Le Cercle de Saules ; Vesper : « Le Surge est une blessure, et ton Sceau la main qui l'a ouverte. » **Nyx rejoint le groupe** (`s1.nyx_allie`) |
| 3-7 | La barque des passeurs ; Nyx et Aurèle s'affrontent sur les bûchers de l'Ordre |
| 3-8 | Les sorcières de Corvin ; on le localise au refuge |
| 3-9 | **L'Adepte renégat** (choix) |
| 3-10 | L'Hydre vaincue, Vesper révèle la vérité sur la Fracture. **✦ La Vérité des Cendres** (choix majeur). Fin de l'acte 3, vers les Pics Gelés |

**La vérité sur la Fracture** (acte 3) :
- ce n'était pas une catastrophe, mais un sort ;
- un Porteur d'Écho a voulu réparer le temps, défaire une seule mort, et il a ouvert une blessure entre les instants ;
- le Surge est ce qui en coule.

Cela répond à l'avertissement du Grand Cerf en 1-5. Son identité (Morvaen) reste pour l'acte 7.

## Choix

### 3-9 · L'Adepte renégat

| Option | Effets |
|---|---|
| A. Le livrer à l'Ordre de l'Aube | `s1.corvin_livre`, Ordre de l'Aube +20, Nyx −20 |
| B. Le protéger | `s1.corvin_protege`, Cercle des Cendres +20, Nyx +20, Corruption +5 |

### ✦ 3-10 · La Vérité des Cendres

| Option | Effets |
|---|---|
| A. Voie de l'Aube | `s1.voie_aube`, Corruption −10, Aube +20, Cendres −10, Nyx −10 |
| B. Voie des Cendres | `s1.voie_cendres`, Corruption +20, Cendres +20, Aube −10, Nyx +10, Sylwen −5 |

Les deux options posent `s1.verite_cendres`, qui **ouvre la 3ᵉ branche de l'arbre**.

## Branche « Voie du Surge » (Arcanomancie)

- Elle s'ouvre avec `unlock_flag` (`Profile.branch_locked`).
- Les nœuds marqués `flag` sont réservés à une voie : le bouton affiche « Réservé : … ».

| Palier | Nœuds |
|---|---|
| 1 (0 point) | Résonance (Arcane +6 %/rang), Flux vital (mana +4 %/rang) |
| 2 (5) | Éclat du Surge (jauge Surge +6 %/rang), Portail instable (Onde arcanique +8 % de rayon), **sort Distorsion** |
| 3 (10) | Concentration (−2 % de coût), Esprit vif (+1 % de critique), Faille ouverte (Distorsion +0,3 s) |
| 4 (20) | Cœur arcanique (Arcane +5 %/rang), **Météore du Surge** (évolution de l'Ultime : +20 % de dégâts, +20 % de rayon, Surge +10 %) |
| 5 (30) | Clé de voûte **Aube éternelle** (Voie de l'Aube) : la Barrière se répare de 0,4 PV/s · **Cendres vives** (Voie des Cendres) : chaque ennemi abattu rend 1 mana |

Nouveaux modificateurs de la simulation : `surge_gain`, `barrier_regen`, `kill_mana`.

## Nyx, 4ᵉ compagnon

- Fée nécromancienne (`necromancien` / `fee`).
- Familiers : Squelettes liés (Ombre).
- Sorts : **Linceul** (zone d'ombre qui ralentit et blesse) et **Pluie d'ossements** (4 impacts).
- Rôle affiché au Cercle : Ombre.
- Le Cercle choisit 2 compagnons actifs parmi ceux qui ont rejoint (jusqu'à 4).
- Elle a ses répliques de combat dans toutes les zones : sarcastiques, avec une variante si Corvin a été protégé et une autre si sa loyauté est basse.

## Illustrations

Planches `marais`, `cercle`, `hydre` et `refuge` (`StoryArt._marais`) : crépuscule, saules, pilotis et lanternes, cercle de braseros, silhouette de l'hydre.

## Aperçu web

`?scene=z03_l10_outro` lance la révélation et le choix majeur.
