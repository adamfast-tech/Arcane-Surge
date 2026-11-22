# Création du personnage et Miroir (étape 13.1)

> Ébauche : [`04-classes-races.md`](04-classes-races.md) §2 et §4. Code : `scripts/ui/creation_screen.gd`, `scripts/core/player_look.gd`, `PortraitArt._porteur`, `SpriteAtlas._gen_player`.

## Quand

- **Création** : à la première arrivée à Havre-Aube, y compris pour une partie déjà avancée, qui garde sa progression.
- **Miroir** : on touche son portrait à Havre-Aube pour changer l'**apparence** ; la race est fixée à la création.
- Le profil enregistre `player.created`, `player.race`, `player.class` et `player.look`.

## Race

Les 8 races de l'ébauche, avec leurs modificateurs de stats, appliqués en combat :

| Race | Stats |
|---|---|
| Humain | +1 partout |
| Elfe | CÉL +4, DES +2, VIG −1 |
| Nain | VIG +4, POU +2, CÉL −1 |
| Orc | POU +4, VIG +3, ESP −2 |
| Fée | ESP +4, DES +3, VIG −2 |
| Draconique | POU +3, ESP +2 |
| Reptilien | VIG +3, CÉL +2 |
| Revenant | POU +2, ESP +3 |

- Le Revenant est verrouillé : il sera débloqué par l'histoire, à l'acte 6.
- Les **passifs** et le **Don racial** sont affichés ; leurs effets arrivent à l'étape suivante (13.2, Races).
- Chaque race a 5 teintes de peau, un trait visible et une taille en combat :
  - oreilles pointues (Elfe) ;
  - barbe (Nain) ;
  - crocs (Orc) ;
  - ailes (Fée) ;
  - cornes et écailles (Draconique) ;
  - queue et écailles (Reptilien) ;
  - lueur spectrale (Revenant).

## Classe

- Les 7 classes sont présentées. Seul le **Mage** est jouable pour l'instant.
- Les autres affichent « Bientôt jouable » ; elles arrivent à l'étape 13.3 (Classes).

## Apparence

| Choix | Options |
|---|---|
| Silhouette | Robe longue · Cape et tunique |
| Coiffe | Capuche (visage dans l'ombre, regard lumineux) · Cheveux courts · Cheveux longs · Tresse |
| Visage | Doux · Anguleux · Balafré |
| Peau | 5 teintes, selon la race |
| Cheveux | Noir, brun, châtain, roux, blond, blanc, bleu, rose |
| Yeux et magie | Cyan, ambre, vert, violet, rouge, argent (couleur des yeux, du liseré et de la lueur du bâton) |
| Tenue | Bleu nuit, cramoisi, émeraude, violet, cendre, ocre, blanc, noir |

- L'aperçu montre le **portrait** (dialogues, Havre-Aube) et le **sprite de combat** vu de dos.
- Les deux sont générés par code selon ces choix.
- En combat, la taille du héros suit sa race : 1,25 m pour un Nain, 1,1 m pour une Fée, 1,55 m pour un Orc.
