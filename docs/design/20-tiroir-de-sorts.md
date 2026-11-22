# Préparation et tiroir de sorts

> Code : `scripts/ui/prep_screen.gd` (préparation), `scripts/battle/battle_screen.gd` (mode Tiroir), `Profile.spell_mode` / `Profile.drawer_spells`.

## Préparation

Avant chaque combat lancé depuis la Carte ou « Continuer », un écran **Préparation** rappelle le niveau et propose deux façons d'emporter ses sorts :

| Mode | Contenu | Usage |
|---|---|---|
| **Deck** | Les 7 sorts choisis à la Bibliothèque | Toucher un sort, puis toucher l'arène |
| **Tiroir** | **Tous** les sorts connus, rangés par école | Voir ci-dessous |

- Le choix est mémorisé (`spell_mode` dans la sauvegarde).
- « Rejouer » garde le mode en cours.
- « Combattre » lance les dialogues d'introduction, puis le combat.

## Tiroir en combat

Les 8 cases de sorts affichent les écoles, toujours à la même place pour les retrouver sans chercher :

| Feu | Givre | Foudre | Nature |
|---|---|---|---|
| **Ombre** | **Arcane** | **Terre** | **Lumière** (Purifier) |

- Chaque case indique le nombre de sorts prêts (« 3/5 prêts »).
- Une école sans sort connu est grisée.
- L'Ultime passe sur la rangée du Champion.

### Geste principal

1. **Toucher et maintenir** une école : les mêmes cases affichent ses sorts, du rang Novice au rang Interdit (8 au plus).
2. **Glisser** le doigt sur le sort voulu : il s'éclaire.
3. **Relâcher** sur le sort : il est choisi, et sa zone d'effet suit le doigt sur l'arène.
4. **Toucher l'arène** : le sort part, et les cases reviennent aux écoles.

### Raccourcis

- **Glisser jusqu'à l'arène** sans relâcher : la zone d'effet suit le doigt, et relâcher lance le sort aussitôt. Un seul geste suffit : école, sort, cible.
- **Toucher simple** sur une école : le tiroir reste ouvert, on touche ensuite le sort.
- Pour refermer le tiroir : relâcher ailleurs, ou toucher l'arène sans sort choisi. Échap et clic droit annulent aussi.
- **Clavier** : 1-8 ouvre une école, puis 1-8 lance le sort de ce rang au curseur. Deux touches suffisent.
- Un sort en recharge ou sans assez de mana est grisé ; le relâcher dessus affiche la raison.

## Petits écrans

Le panneau du bas mesure son contenu après la mise en page et grandit si besoin : la 2ᵉ rangée de cases n'est plus coupée sur les téléphones les plus courts.

## Aperçu web

`?level=z01_l03&mode=drawer&mana=1&deck=etincelle,boule_de_feu,…` lance un niveau en mode Tiroir avec ces sorts. Sans `deck`, il prend tous les sorts connus.
