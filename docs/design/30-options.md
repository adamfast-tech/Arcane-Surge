# Options (étape 13.6)

> Code :
> - `scripts/ui/options_screen.gd` ;
> - dans `Profile` : `elem_for_all`, `difficulty`, `DIFFICULTIES`, `difficulty_mult`, `is_elemental`, `elem_allowed`, `starter_spells` ;
> - `BattleSim.diff`.
>
> Données : `data/party.json` (`starter_spells` de chaque classe).

À Havre-Aube, le bouton **clé à molette**, en haut à droite sous la fiche du héros, ouvre les Options. Il affiche la difficulté en cours. Les choix sont enregistrés dans la sauvegarde (`options`) et synchronisés avec le compte.

## Sorts en combat

| Choix | Effet |
|---|---|
| **Deck** | Les 7 sorts choisis à la Bibliothèque. |
| **Tiroir** | Tous les sorts connus, rangés par école et par discipline. |

C'est le même réglage que sur l'écran de Préparation (`spell_mode`).

## Grimoires

| Choix | Effet |
|---|---|
| **Écoles pour toutes les voies** (par défaut) | Les sorts élémentaires (Feu à Terre, le grimoire du Mage) servent à toutes les voies, en plus du grimoire de chaque classe. |
| **Chaque voie son grimoire** | Seul le Mage emporte les sorts élémentaires. Les autres voies n'emportent que leur grimoire de classe, les sorts de leur arbre et les sorts sans école (Purifier). |

**Quand chaque voie a son grimoire :**
- **Bibliothèque :** les sorts élémentaires y restent visibles, mais ne s'achètent plus (« Réservé au Mage (Options) »).
- **Sorts déjà appris :** ils ne sont jamais perdus. Ils reviennent si l'on repasse sur l'autre option ou sur la voie du Mage.
- **Tiroir :** il s'ouvre directement sur les 8 disciplines de la classe, sans bouton de bascule.
- **Deck :** s'il compte moins de 3 sorts, il est complété avec les sorts connus.

**Techniques de départ.** Chaque voie connaît d'office 3 techniques Novice de son grimoire, quelle que soit l'option :

| Voie | Techniques de départ |
|---|---|
| Archer | Flèche vive, Salve, Marque du chasseur |
| Épéiste | Entaille, Estoc rapide, Lame-éclair |
| Clerc | Éclat sacré, Soin léger, Rayon de l'aube |
| Nécromancien | Éclat d'os, Relever les morts, Trait ténébreux |
| Chevalier | Coup de bouclier, Frappe juste, Pavois |
| Berserker | Hache lancée, Bond, Pillards |

## Difficulté

Un seul multiplicateur par difficulté s'applique à six choses :
- la **vitesse des ennemis** ;
- les **dégâts des ennemis** : coups, tours, pulsations du Nexus, frappes de boss sur les couloirs, dégâts à la Barrière ;
- les **PV du Nexus**, et du boss sur un niveau de boss ;
- l'**XP gagnée**, héros et compagnons, en victoire comme en défaite ;
- le **nombre d'objets** ;
- les **matériaux**.

Au-delà de Normal, chaque objet a en plus une chance d'être tiré deux fois, et la meilleure rareté est gardée. Cette chance vaut 25 % par point de multiplicateur au-dessus de 1 (×1,25 → 6 %, ×3 → 50 %), plafonnée à 60 %.

| Difficulté | Multiplicateur | Ennemis | Nexus et boss | XP et butin |
|---|---|---|---|---|
| Facile | ×0,75 | 25 % plus lents, 25 % de dégâts en moins | -25 % de PV | -25 % |
| Normal | ×1 | — | — | — |
| Sérieux | ×1,25 | 25 % plus rapides, 25 % de dégâts en plus | +25 % de PV | +25 % |
| Difficile | ×1,5 | 50 % plus rapides, 50 % de dégâts en plus | +50 % de PV | +50 % |
| Ça va pas non !? | ×2 | 100 % plus rapides, 100 % de dégâts en plus | +100 % de PV | +100 % |
| Impossible | ×3 | 200 % plus rapides, 200 % de dégâts en plus | +200 % de PV | +200 % |

Les PV des ennemis ne changent pas : la difficulté joue sur leur vitesse et leurs dégâts. Le nombre d'objets d'une victoire vaut `étoiles × multiplicateur` (au moins 1 objet ; la partie décimale est une chance d'objet en plus).

**Contrôle au simulateur** (1-5, Grand Cerf, Mage, IA aux commandes, `tools/sim_cli.gd -- --diff=X`) :

| Difficulté | Résultat |
|---|---|
| Facile | 1/1, 92 s, Barrière 64 % |
| Normal | 6/6, 108 s |
| Sérieux | 2/2, 145 s, Barrière 42 % |
| Difficile | 1/2 |
| Ça va pas non !? | 0/2 |
| Impossible | 0/1 |

## Aperçus

`?room=options` ouvre les Options ; `?room=hub` ouvre Havre-Aube sans passer par la connexion.

## Version du jeu et mises à jour

- La section « Version du jeu » affiche la version (`application/config/version`), l'empreinte du commit, la date de publication et le dernier changement (`data/build.json`, écrit par la CI avant l'export ; « dev » en local).
- **Vérifier les mises à jour** lit `version.json`, publié par la CI à côté du jeu (requête sans cache), et compare son empreinte à celle du jeu chargé :
  - même empreinte : « Tu as la dernière version » ;
  - empreinte différente : « Nouvelle version disponible : <commit> — <titre> », avec le bouton **Mettre à jour**.
- **Mettre à jour** ou **Recharger** sauvegarde la progression (locale et cloud). Le jeu retélécharge ensuite ses fichiers en contournant le cache du navigateur (`fetch(..., {cache: 'reload'})` sur index.html, .js, .wasm, .pck et version.json), puis recharge la page. On voit les changements sans fermer l'application.
- Après chaque changement, la publication prend quelques minutes (CI, puis cache de GitHub Pages).
- Hors version web, le bouton indique que la vérification n'est disponible que sur le web.

