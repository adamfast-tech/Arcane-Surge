# Arbres de compétences (étape 13.10)

> Arbres d'origine : [`04-classes-races.md`](04-classes-races.md) §3 et l'étape 13.3. Données : `data/skill_trees/<classe>.json`. Écran : `scripts/ui/skill_tree_screen.gd`, vue `scripts/ui/skill_tree_view.gd`.

## 1. Un vrai arbre

Chaque branche s'affiche comme un arbre de RPG.
- Les compétences sont des médaillons, du palier 1 (en haut) aux Clés de voûte (en bas).
- Des chemins relient chaque compétence à celles dont elle dépend. Le fond est un ciel étoilé à la couleur de la branche.
- **Formes** : rond pour un passif, carré pour un nouveau sort, hexagone pour une évolution (Ultime ou Champion), losange pour une Clé de voûte.
- **États** :
  - verrouillée : grise, avec un cadenas ;
  - accessible : l'anneau pulse ;
  - investie : halo à la couleur de la branche ;
  - maîtrisée : anneau d'or.
  - Le rang s'affiche sous le médaillon (« 2/5 »).
- **Chemins** :
  - gris tant que rien n'est investi ;
  - colorés quand la compétence du dessus a un rang ;
  - lumineux, parcourus d'une étincelle, quand les deux bouts sont investis.
- **Paliers** : le seuil en points s'affiche à gauche (0, 5, 10, 15, 20, 25, 30) ; il passe en or quand la branche l'a atteint.
- **Sélection** : toucher un médaillon ouvre le panneau du bas, fixé à l'écran. On y voit le nom, le type, le rang, le palier, l'effet et ce qui bloque (palier, prérequis, Clé de voûte), avec le bouton +1. Investir met à jour l'arbre et les compteurs sans recharger l'écran.
- L'onglet Héritage (arbre racial) garde sa présentation en liste.

## 2. Règles

- **Points** : 1 par niveau à partir du niveau 2, plus 1 tous les 10 niveaux (109 au niveau 100). Une branche complète coûte environ 80 points : il faut choisir.
- Une compétence s'ouvre quand :
  - la branche a assez de points pour son palier (`req`) ;
  - au moins une des compétences reliées au palier précédent (`parents`) a un rang ;
  - pour une Clé de voûte : au plus 2 au total, et le drapeau de l'histoire requis s'il y en a un.
- Le blocage s'affiche « Prérequis : Braises ou Étincelle ou Brasier ».
- **Positions** : chaque nœud a une colonne `x` (de 0 à 3). Les parents sont les nœuds voisins du palier précédent (écart d'au plus 1 colonne).
- Aperçu : `?room=skills&lvl=40&build=1` (ajouter `&class=...` pour une autre classe).

## 3. Nouvelles compétences

+210 compétences, soit 10 par branche. On passe de 34 à **64 compétences par classe**, 448 au total.

| Palier | Ajouts par branche |
|---|---|
| 0, 5, 10 | 1 passif à chaque palier (élément des invocations, résistance, esquive, vitesse, mana par ennemi abattu, bouclier de départ…) |
| **15** (nouveau) | 3 passifs : dégâts des sorts, invocation en double, recharge des sorts, critique… |
| 20 | 1 passif double (ex. Âme du phénix : PV + dégâts de Feu des invocations) |
| **25** (nouveau) | 2 maîtrises (ex. Nova : Sorts de Feu +6 % par rang ; Roi des ossements ; Main divine) |
| 30 | 1 **Clé de voûte à double tranchant** |

Les descriptions des nouvelles compétences sont générées à partir de leurs effets (« Attaque des invocations +3 % par rang »).

**Clés de voûte à double tranchant** :

| Classe | Clés |
|---|---|
| Mage | Pyromanie (Feu +30 %, coût des sorts +15 %) ; Cœur de banquise (gel +1 s, cadence −15 %) ; Surcharge arcanique (sorts +25 %, Barrière −15 %) |
| Archer | Tireur isolé (attaque +30 %, PV −20 %) ; Chasse sauvage (vitesse +30 %, défense −4) ; Éclipse totale (Lumière +30 %, mana −20 %) |
| Épéiste | Duel à mort (critique +15 %, PV −20 %) ; Surtension (Foudre +30 %, Barrière −15 %) ; Miroir brisé (doubles +20 %, attaque −15 %) |
| Clerc | Martyr (soins +40 %, attaque −15 %) ; Zélote (Lumière +30 %, soins −30 %) ; Ascète (coût des sorts −25 %, PV −15 %) |
| Nécromancien | Horde sans fin (squelettes +10 %, PV −20 %) ; Pacte noir (Ombre +30 %, Barrière −15 %) ; Non-mort (Barrière +1 PV/s, soins −50 %) |
| Chevalier | Immobile (dégâts subis par la Barrière −30 %, cadence −15 %) ; Charge héroïque (attaque +25 %, défense −5) ; Runes vivantes (bouclier +30 % des PV, attaque −15 %) |
| Berserker | Sans armure (attaque +35 %, défense −6) ; Tambour de guerre (compagnons +30 %, mana −20 %) ; Folie (dégâts au bord du gouffre +40 %, Barrière −20 %) |

Les effets utilisent uniquement les modificateurs existants de la simulation.

## 4. Vérifications

`tools/ui_smoke.gd` contrôle :
- 7 paliers par branche et 64 compétences par classe ;
- une position et une description pour chaque compétence ;
- un parent pour chaque nœud hors du palier 1, et des parents qui existent ;
- les effets des passifs, qui doivent exister dans `sim.gd` ;
- le prérequis de Feu dévorant ;
- l'affichage de la vue en arbre.
