# Étape 10.2 — Narration de la zone 1

> Suite de [`11-boucle-de-jeu.md`](11-boucle-de-jeu.md). Règles d'origine : [`07-narration.md`](07-narration.md), canon : [`00-lore.md`](00-lore.md). Étape suivante : 10.3 (compétences, Bibliothèque, Cercle).

## 1. Parcours

```
1re partie : Prologue ─> Intro 1-1 ─> Combat ─> Récompenses ─> Fin 1-1 ─> Carte / Havre-Aube
Niveau suivant :         Intro     ─> Combat ─> Récompenses ─> Fin (et choix éventuel)
```

| Moment | Règle |
|---|---|
| **Prologue** | Avant la toute première partie (1-1 jamais gagné) |
| **Intro d'un niveau** | Avant le combat, tant qu'elle n'a jamais été vue |
| **Fin d'un niveau** | Après la 1re victoire, quand le joueur quitte l'écran des récompenses (Rejouer, Carte ou Havre-Aube) |
| **Choix en suspens** | Une sauvegarde antérieure à la narration avec 1-9 ou 1-10 déjà gagné : la scène du choix est proposée à l'arrivée à Havre-Aube |
| **Abandon** | Une scène interrompue est rejouée. Un choix déjà fait n'est jamais redemandé ni réappliqué |

## 2. Écran de dialogue

Conforme à la maquette [`mockups/Dialogue.dc.html`](../mockups/Dialogue.dc.html) :
- **Illustration** du lieu en plein écran ;
- **sujet** de la scène au centre (Grand Cerf, Sylvarche, fée, Lanterne), qui change de teinte quand il est purifié ;
- **panneau** en bas :
  - portrait 64×64 ;
  - nom dans la couleur de la faction ;
  - titre et loyauté pour les compagnons ;
  - texte en machine à écrire (45 caractères par seconde).

| Commande | Tactile / souris | Clavier |
|---|---|---|
| Afficher tout le texte, puis réplique suivante | Toucher l'écran | `Espace`, `Entrée` |
| **Auto** (avance seul) | Bouton | — |
| **Historique** de la scène | Bouton | `H` |
| **Passer** jusqu'au prochain choix | Bouton | `Échap` |

- **Choix majeur** : en-tête « ✦ FIL DU DESTIN » en violet, avec la mention « Ce choix changera la suite de l'histoire ».
- **Choix mineur** : en-tête « CHOIX ».
- **Bilan** : il s'affiche après chaque choix, par exemple « Sylwen : loyauté +10 » ou « Objet obtenu : … ».
- **Paysage** : le panneau s'élargit, le texte et le portrait grandissent.

## 3. Les scènes de la zone 1 (21)

| Scène | Lieu | Contenu |
|---|---|---|
| Prologue | Fracture, Surge, Nexus, Lysbourg | Morvaen et la Fracture, l'Arcane Surge, les Nexus, les Canalisateurs, Lysbourg endormi |
| 1-1 | Lysbourg | L'Ancien Tobin réveille le joueur : un Nexus attaque. Portes runiques et Barrière |
| 1-2 | Bois | **Sylwen** (Vigiles Sylvestres) rejoint le groupe ; les lucioles rendent du mana |
| 1-3 | Bois | **Brann Forgecœur** (Bastion d'Argent) rejoint le groupe. Choix mineur (ronflements) |
| 1-4 | Bois | Les fées sombres et leurs portes maudites. Purifier et ordres aux bots |
| 1-5 | Bois, Grand Cerf | Le gardien corrompu. À la fin, le Cerf purifié confie le **Sceau d'Écho** au joueur |
| 1-6 | Bois | Les fées s'organisent. À la fin, 1er Écho, et une voix inconnue (le Roi Éclipsé) |
| 1-7 | Pont, puis Tour | La Lanterne de l'Aube. À la fin, la **Tour du Croissant** apparaît à l'horizon |
| 1-8 | Source des Lucioles | Sceaux et dryades. À la fin, Sylwen révèle que la Sylvarche est sa mentore |
| 1-9 | Cœur de la forêt | Deux Nexus et une tour. À la fin, choix : **les fées captives** |
| 1-10 | Sylvarche | Le boss, puis le choix majeur : **la Sylvarche**. Fin de l'acte 1, vers les Collines d'Ambre |

**Continuité du lore**
- Le prologue ne dit pas comment Morvaen a brisé le monde. Le Cerf évoque seulement « le dernier qui a porté le Sceau ». La révélation reste celle de l'acte 7.
- Ton de l'acte 1 : lumineux, humour de Brann.
- Le joueur est tutoyé, sans accord masculin ou féminin.

## 4. Choix et conséquences

| Choix | Options | Effets |
|---|---|---|
| 1-3 (mineur) | « Respirer avec conviction… » · « J'entends encore les sangliers… » | Brann +3 · Sylwen +3 |
| 1-9 Les fées captives | **A.** Libérer les fées · **B.** Poursuivre la Sylvarche | A : `s1.fees_liberees`, Sylwen +10 ; **en 1-10, les fées aident** : Barrière +30 (bouclier) et 4 lucioles (mana) · B : `s1.sylvarche_poursuivie` ; **en 1-10, la Sylvarche commence à 85 %** |
| ✦ 1-10 La Sylvarche | **A.** Purifier · **B.** Abattre | A : `s1.sylvarche_purifiee`, Sylwen +30, Elfes +20, **la forêt guérit** (sol plus vert, veines dorées, lucioles dans l'arène de la zone 1) · B : `s1.sylvarche_abattue`, Sylwen −30 (−15 si les fées ont été libérées), **Bâton de la Première Sève** (légendaire, unique) |

- Le Bâton n'est plus donné à la 1re victoire sur la Sylvarche : il dépend du choix B.
- **Effets en jeu** : les drapeaux arrivent dans la simulation (`opts.flags`). Le niveau décrit ses effets dans `story_mods`, et un message les annonce au début du combat.
- **Loyauté** : +1 par partie jouée avec le compagnon, au plus +5 par jour (07-narration §5.1).
- **Havre-Aube** : le Cercle affiche la loyauté, l'Observatoire le fil de la Sylvarche.
- **« Changer le futur »** viendra avec l'Observatoire. Chaque choix est déjà enregistré avec sa date (`story.choices`), pour la Carte des fils du destin.

## 5. Répliques de combat

Brann et Sylwen parlent pendant la partie : portrait, nom et une phrase courte, du côté où ils se trouvent.

- **Fréquence** : une fois par déclencheur et par partie, au plus une toutes les 7 s. Les répliques urgentes passent en priorité.
- **Déclencheurs** :
  - début de partie ;
  - Barrière sous 40 % ;
  - objectif à moitié ;
  - changement de phase d'un boss ;
  - 1er Écho ;
  - ultime ;
  - grande armée (120 alliés) ;
  - Lanterne sous 50 %.
- **Variantes** :
  - selon la loyauté (`loy_min`, `loy_max`) ;
  - selon les drapeaux (`if`, `if_not`), par exemple après la Sylvarche purifiée ou abattue ;
  - propres à un niveau (Grand Cerf, Lanterne, Sylvarche).

## 6. Art

| Élément | Détail |
|---|---|
| Portraits | 8 personnages × 5 expressions (neutre, joie, colère, tristesse, surprise), 64×64, générés par code (`scripts/gfx/portrait_art.gd`) : toi, Sylwen, Brann, l'Ancien Tobin, le Grand Cerf, la Sylvarche (corrompue ou purifiée), une fée, la Voix inconnue |
| Illustrations | Générées par code (`scripts/gfx/story_art.gd`) : Fracture, Surge, Nexus, Lysbourg, Bois, Bois guéri, Pont, Source, Tour du Croissant, Sylvarche, Collines d'Ambre |
| Remplacement | `assets/portraits/<perso>-<expression>.png`, ou `<perso>.png` pour toutes les expressions (voir [`10-sprites.md`](10-sprites.md) §7) |

Aperçus : [planche des portraits](../art/portraits.png) · [choix « Fil du destin »](../art/dialogue-choix.png) · [réplique en combat](../art/replique-combat.png).

## 7. Données et code

- **Textes** : `data/dialogues/fr/z01.json`. Une langue = un dossier, l'anglais viendra dans `data/dialogues/en/`.
  - `characters` : nom, titre, couleur, portrait, loyauté affichée.
  - `scenes` : lignes `{who, text, mood, art, subject, subject_tint, if, if_not}`, lignes d'effets `{effects}` et choix `{choice, major, options: [{key, text, effects, then}]}`.
  - `barks` et `barks_level` : les répliques de combat.
- **Effets** : `set`, `clear` (drapeaux), `add` (`loy.<compagnon>`, `rep.<faction>`, `corruption`), `grant` (objet), `also` (effets conditionnels).
- **Code** :
  - `scripts/core/story.gd` : état de l'histoire, dans la sauvegarde, donc synchronisé avec le compte Académie ;
  - `scripts/core/dialogues.gd` : accès aux textes ;
  - `scripts/ui/dialogue_screen.gd` : l'écran.
- **Aperçu** : `…/Arcane-Surge/?scene=z01_l10_outro` ouvre directement une scène.
- **Test** : `tools/ui_smoke.gd` parcourt le prologue, une intro, une fin, Passer, l'Historique et les deux choix, puis vérifie leurs effets (loyauté, Bâton, aide des fées en 1-10). Il utilise sa propre sauvegarde.
