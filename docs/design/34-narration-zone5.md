# Acte 5 · Le Collège oublié (narration de la zone 5, étape 15.2)

> Suite de [`32-narration-zone4.md`](32-narration-zone4.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Zone jouable : [`33-zone5.md`](33-zone5.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Thalren** | Mage du Collège Arcanique. Il cherche depuis vingt ans les ruines du premier Collège. Érudit, poli, prudent : certains savoirs se brûlent | Cheveux sombres à mèche d'argent, barbe courte, lunettes cerclées d'or, robe violette à col haut |
| **Le Sphinx de verre** | Gardien du Collège depuis la Fracture | Visage de cristal fendu, coiffe or et turquoise, yeux d'ombre violette |
| Ysolde | Quitte le groupe au pied des Pics (5-1) | — |
| La Voix inconnue | Revient en 5-5 | — |

## Ce que l'acte révèle

- Le premier Collège a brûlé à l'aube de la Fracture, réveillé par un élève prodige dont le nom a été effacé des registres.
- Le Journal, signé « M. », contient les pensées de ce prodige :
  - Liriel est morte dans l'incendie de la bibliothèque, à l'aube.
  - Le prodige portait un Sceau d'Écho, et il a remonté le fil « encore une fois », jusqu'à briser le temps.
- Le joueur fait lui-même le lien avec Morvaen : l'archimage du prologue, l'élève, « M. ». Le nom n'est jamais dit en clair ; la révélation complète reste pour l'acte 7.
- **Premier signe du Reflet (5-4)** : dans un miroir du Collège, ton reflet s'arrête, puis sourit quand tu ne souris pas.
- **Le Sphinx, si le Sceau lui est révélé** : « Alors c'est toi. Le prochain. » C'est le premier écho de la Boucle.

## Déroulé

| Niveau | Temps fort |
|---|---|
| 5-1 | Ysolde repart vers les cols ; les scarabées de verre ; Thalren se présente (réplique propre au Mage : « confrère ») |
| 5-2 | Un mirage montre un jeune homme du Collège et une femme qui rit ; le Sceau brille |
| 5-3 | La vieille prêtresse : « Un élève l'avait réveillé » |
| 5-4 | Le reflet qui sourit tout seul |
| 5-5 | Le Scarabée-soleil ; la Voix : « le temps n'est qu'une page… qu'on peut tourner à l'envers » |
| 5-6 | La caravane mène au premier Collège, enterré |
| 5-7 | La nuit des élèves spectres : **choix mineur** avec Nyx |
| 5-8 | Les portes s'ouvrent ; tous les sabliers se sont arrêtés à l'aube de la Fracture |
| 5-9 | **Le Journal** (choix) |
| 5-10 | Le Sphinx vaincu pose sa dernière énigme : « Qui es-tu ? » **✦ L'énigme du Sphinx** (choix majeur). Fin de l'acte 5, vers la Forêt Cendrée |

## Choix

### 5-7 · Les élèves du Collège

| Option | Effets |
|---|---|
| A. « Libère-les, Nyx. » | `s1.eleves_liberes`, Nyx +10, Sylwen +5 |
| B. « Demande-leur ce qu'ils savent d'abord. » | `s1.eleves_interroges`, Nyx −5 ; le nom de Liriel et l'aube de la Fracture |

### 5-9 · Le Journal

| Option | Effets |
|---|---|
| A. Le lire | `s1.journal_lu`, **Fragment de Morvaen +1**, Corruption +10, Nyx +5, Sylwen −5 ; extraits du Journal |
| B. Le brûler | `s1.journal_brule` et `s1.thalren_confiance`, Corruption −5, Sylwen +5, Nyx −5 |

**Effets devant le Sphinx** (`story_mods` de z05_l10) :

| Drapeau | Effet |
|---|---|
| `s1.journal_lu` | Chaque réponse aux énigmes ne demande que 8 invocations au lieu de 12 (nouvelle clé `riddle_need`) |
| `s1.thalren_confiance` | Thalren tient un bouclier arcanique : Barrière +25 |

### ✦ 5-10 · L'énigme du Sphinx

| Option | Effets |
|---|---|
| A. Révéler ton Sceau d'Écho | `s1.sceau_revele`, `s1.faiblesse_morvaen` (le Sphinx révèle la faiblesse cachée : montrer à Morvaen le visage de celle qu'il a voulu sauver ; P2 du combat final plus facile), Archivistes +10 |
| B. Mentir : « Un simple Canalisateur » | `s1.sphinx_mensonge` (Ssareth méfiant à son arrivée, acte 7), Archivistes −10 |

**Nouvelle valeur** : `fragments` (Fragments de Morvaen, 0 à 10), affichée « Fragments de Morvaen +1 ». Elle compte pour la fin cachée (la Boucle : 10 fragments).

## Répliques de combat

- Répliques du désert pour les quatre compagnons, ajoutées à l'étape 15.1.
- Variantes selon `s1.journal_lu`, `s1.journal_brule` et `s1.eleves_liberes`.
- Brann et ses devinettes devant le Sphinx.

## Illustrations

| Planche | Contenu |
|---|---|
| `dunes` | Ciel bleu vers l'or, soleil, dunes, éclats de verre |
| `oasis` | Eau turquoise, palmiers, temple blanc |
| `miroirs` | Deux grands miroirs au couchant |
| `college` | Le premier Collège enterré : colonnes, dômes de verre fendus |
| `desert_nuit` | Nuit étoilée, ruines, élèves spectres |
| `sphinx` | Salle de verre sous le Collège, porte scellée, lueur violette |

Elles sont dessinées dans `StoryArt._desert` et `_sphinx_hall`. Les portraits `thalren` et `sphinx` sont dans `PortraitArt`.

## Aperçu web

- `?scene=z05_l04_outro` : le reflet.
- `?scene=z05_l09_outro` : le Journal.
- `?scene=z05_l10_outro` : le choix majeur.

## Vérifications

`tools/ui_smoke.gd` (`_act5_ok`) contrôle :
- les 20 scènes, les 2 portraits et les 6 planches ;
- 5-7 A, 5-9 A (Fragment, Corruption), ✦ 5-10 A (faiblesse, Archivistes) ;
- devant le Sphinx : 8 invocations par réponse si le Journal a été lu, bouclier de Thalren s'il a été brûlé.
