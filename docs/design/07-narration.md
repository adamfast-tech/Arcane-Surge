# Étape 7 — Narration, choix et continuité

> Canon : [`00-lore.md`](00-lore.md) · Zones et boss : [`06-monde.md`](06-monde.md)

## 1. État de l'histoire (fils du destin)

| Type | Exemples | Plage |
|---|---|---|
| **Drapeaux** (choix) | `sylvarche_purifiee`, `gharok_exorcise`, `voie_aube` | vrai / faux |
| **Corruption** | Rituels, choix sombres, voie des Cendres | 0 → 100 |
| **Loyauté** (une par compagnon) | Brann, Sylwen, Krag, Nyx, Ignara, Ssareth | 0 → 100 (départ : 50) |
| **Réputation** des factions | Elfes, Clans orcs, Royaumes humains, Nains, Cercle des Cendres, Ordre de l'Aube, Dragons, Archivistes reptiliens | −100 → +100 |
| **Dette d'Écho** (cachée) | +1 à chaque « Changer le futur » | 0 → ∞ |
| **Fragments de Morvaen** | Pages du journal cachées, une par zone | 0 → 10 |

Les drapeaux sont rangés par saison (`s1.*`, `s2.*`) pour que l'histoire puisse continuer d'une saison à l'autre (§7).

## 2. Arbre des choix (saison 1)

- ✦ = choix majeur : il crée un point de retour sur la Carte des fils du destin.
- Les options **[Race]** ou **[Classe]** n'apparaissent que pour la race ou la classe indiquée.

| Acte | Choix | Options | Conséquences |
|---|---|---|---|
| 1 | 1-9 Les fées captives | A. Libérer les fées · B. Poursuivre la Sylvarche | A : fées alliées dans 1-10 et l'acte 3 (variante d'aide), Sylwen +10 · B : la Sylvarche est affaiblie en P1 |
| 1 | ✦ 1-10 La Sylvarche | A. Purifier · B. Abattre | A : Sylwen +30, Elfes +20, la forêt guérit (décor de la zone 1 changé) · B : Sylwen −30 (−15 si les fées ont été libérées), Bâton de la Première Sève garanti |
| 2 | 2-9 Le Traité d'Ambre | A. Défendre le village humain · B. Défendre le campement orc · C. **[Humain/Clerc] Négocier** | Réputation des factions · C : les deux factions envoient des renforts neutres dans la zone 2 |
| 2 | ✦ 2-10 Gharok | A. Exorciser · B. Achever | **Krag est le fils de Gharok.** A : Krag rejoint le groupe (loyauté 60) · B : Krag rejoint seulement si B ou C a été choisi en 2-9, avec une loyauté de 20 (**candidat à la trahison**) |
| 3 | 3-9 L'adepte renégat | A. Le livrer à l'Ordre de l'Aube · B. Le protéger | A : Aube +20, Nyx −20 · B : Cercle +20, Nyx +20, Corruption +5 |
| 3 | ✦ 3-10 La Vérité des Cendres | A. Voie de l'Aube · B. Voie des Cendres | Variante de la branche 3 (étape 4) · Corruption −10 ou +20 · ton des dialogues de l'Ordre ou du Cercle |
| 4 | 4-9 La Forteresse | A. **[Nain] Réactiver les Portes** · B. Sceller la forteresse | A : portails « Forge » ×2 dans la zone 4, mais des sentinelles anciennes se réveillent · B : Brann −15, zone 4 plus sûre |
| 4 | ✦ 4-10 Le Colosse | A. Le reprogrammer · B. Le détruire | A : **le Colosse devient un allié** dans le combat final · B : Enclume-Cœur garantie et matériaux ×3 |
| 5 | 5-9 Le Journal | A. Le lire · B. Le brûler | A : Fragment de Morvaen +1, Corruption +10, lore révélé · B : Corruption −5, Thalren +confiance |
| 5 | ✦ 5-10 L'énigme du Sphinx | A. Révéler son Sceau · B. Mentir | A : le Sphinx révèle la **faiblesse cachée** de Morvaen (P2 plus facile) · B : le Collège te traite en Porteur ordinaire, Ssareth méfiant (−10 à son arrivée) |
| 6 | 6-9 La Mère-Dragon | A. Pacte · B. **Voler l'Œuf de cendre** | A : des dragons alliés dans l'acte 10 · B : un objet de grande puissance, mais des dragons hostiles dans les variantes des zones 7 à 10, Ignara −40 |
| 6 | ✦ 6-10 Trahison et rédemption | Voir `06-monde.md` §4.1 | Fils *Rédemption* ou *Exilé* |
| 7 | 7-9 Les Archives du Temps | A. Lire sa propre ligne · B. Sceller les Archives | A : débloque les **Prémonitions** (les choix suivants affichent l'icône du type de conséquence), Ssareth −10 · B : Ssareth +20 |
| 7 | ✦ 7-10 Le Léviathan | A. Libérer le gardien · B. Le tuer | A : le Léviathan protège la Cité, l'Ordre des Archivistes s'allie · B : Trident des Archives garanti |
| 8 | 8-9 L'écho d'un disparu | A. Ramener l'écho · B. Le laisser reposer | Un allié perdu dans une autre ligne (ou un compagnon mort) revient sous forme d'écho. A : allié spectral, Dette d'Écho +1, Corruption +10 · B : Corruption −10 |
| 8 | ✦ 8-10 La Chimère | A. Absorber un aspect · B. La disperser | A : passif permanent au choix (Feu, Givre ou Ombre), Corruption +15 · B : Corruption −15 |
| 9 | 9-9 L'offre du Héraut | A. Accepter l'alliance · B. Refuser | A : ouvre la fin **Domination** · B : le Héraut combat dans l'acte 10 |
| 9 | ✦ 9-10 Le Reflet | A. Le briser · B. L'absorber · C. Se réconcilier | A : vers la Purification · B : Corruption +25, vers la Domination · C : condition de **la Boucle** |
| 10 | ✦ Le Roi Éclipsé | Selon les fins débloquées (§4) | Fin du jeu et état de départ de la saison 2 |

> Zone 3 mise en œuvre à l'étape 12.2 : voir [`22-narration-zone3.md`](22-narration-zone3.md). Les deux voies de 3-10 ouvrent la branche « Voie du Surge » ; sa Clé de voûte dépend de la voie choisie.
>
> Zone 7 mise en œuvre à l'étape 17.2 : voir [`40-narration-zone7.md`](40-narration-zone7.md). 7-9 A pose `s1.premonitions` : les choix suivants affichent le type de leurs conséquences. 5-10 B rend Ssareth méfiant (−10) ; 6-9 B fait survoler la côte par les dragons (7-2, 7-4).
>
> Zone 6 mise en œuvre à l'étape 16.2 : voir [`38-narration-zone6.md`](38-narration-zone6.md). La Marque du Wyrm se pose au début de l'acte sur le compagnon le moins loyal (sous 25) ; il résiste si sa loyauté remonte à 40. ✦ 6-10 sans traître : briser la Marque ou en garder un éclat.
>
> Zone 5 mise en œuvre à l'étape 15.2 : voir [`34-narration-zone5.md`](34-narration-zone5.md). 5-9 A donne le 1er Fragment de Morvaen et des énigmes plus faciles ; 5-9 B, le bouclier de Thalren devant le Sphinx ; ✦ 5-10 A pose `s1.faiblesse_morvaen`.
>
> Zone 4 mise en œuvre à l'étape 14.2 : voir [`32-narration-zone4.md`](32-narration-zone4.md). L'option [Nain] de 4-9 a une variante [Brann · loyauté 60] pour les autres races ; ✦ 4-10 A pose `s1.colosse_allie` pour le combat final.

> Zone 2 mise en œuvre à l'étape 11.2 : voir [`17-narration-zone2.md`](17-narration-zone2.md). Effet de 2-9 en 2-10 : Ambreval défendu donne Barrière +25, le campement défendu fait commencer Gharok à 90 %, le Traité négocié donne les deux.

> Zone 1 mise en œuvre à l'étape 10.2 : voir [`12-narration-zone1.md`](12-narration-zone1.md). En 1-10, l'aide des fées vaut Barrière +30 et 4 lucioles ; la Sylvarche « affaiblie » commence à 85 % de ses PV.

## 3. Changer le futur

### 3.1 Accès et interface
- **Où** : Observatoire → **Carte des fils du destin**. C'est un arbre chronologique de tous les ✦.
  - Chaque nœud indique le choix fait et sa date.
  - Les options jamais explorées s'affichent en « ? ».
  - Les lignes abandonnées restent visibles, en grisé.
- **Sélection d'un nœud passé** : une fenêtre d'avertissement s'ouvre.
  > *« Vous allez retourner dans le passé, avec vos capacités mais… êtes-vous sûr de cela ? Changer le passé risque de changer votre vie… »*
  - Elle liste ce qui sera **perdu** et ce qui sera **conservé** (§3.2).
  - Pour confirmer, il faut **maintenir le bouton 2 s**.

### 3.2 Règles
| Conservé | Perdu ou réinitialisé |
|---|---|
| Niveau, XP, arbres, équipement, inventaire, or, cosmétiques, sorts | Les drapeaux et la progression de l'histoire **après** ce point |
| **Codex** et « Mémoire d'Écho » | Les choix suivants et leurs objets garantis |
| Succès | L'Héritage de cendre, si l'on remonte avant la trahison |

- **Gratuit**. Le seul coût est narratif : **Dette d'Écho +1**.
- Les niveaux rejoués gardent leur difficulté. Les récompenses de 1re victoire ne sont **pas** données une 2e fois, sauf dans les **nouvelles variantes**, ce qui évite le farm.
- **Mémoire d'Écho** : un dénouement déjà vu débloque parfois des options de dialogue supplémentaires (« Je sais ce qui va arriver… »). Revenir dans le passé est donc récompensé.
- **Ssareth** perçoit les retours dans le temps : sa loyauté baisse de 5 à chaque retour.

### 3.3 Paliers de la Dette d'Écho
| Dette | Effet |
|---|---|
| 1 | Séléné le remarque, de façon ambiguë |
| 3 | Visions de Morvaen entre les niveaux, avertissements explicites |
| 5 | Le Reflet ressemble de plus en plus à Morvaen. **La Boucle** devient possible (§4) |

## 4. Fins

| Fin | Conditions | Résumé |
|---|---|---|
| **Purification** | Corruption < 40, Reflet brisé ou réconcilié, réputation positive auprès d'au moins 3 factions | Le Surge s'apaise, les Veines guérissent, Morvaen est libéré de son éclipse et meurt en paix |
| **Domination** | Corruption ≥ 60, **ou** alliance avec le Héraut, **ou** Reflet absorbé | Le joueur prend le trône du Surge et devient le nouveau souverain. Les compagnons dont la loyauté est inférieure à 50 partent |
| **Sacrifice** | Toujours proposée | Le joueur scelle la Fracture en se sacrifiant. **Variante** : un compagnon dont la loyauté est ≥ 90 se porte volontaire à sa place, et le joueur peut accepter ou refuser |
| **La Boucle** (cachée) | Dette d'Écho ≥ 5, 10 Fragments de Morvaen, Reflet réconcilié | Révélation : chaque Porteur finit par devenir le prochain Roi Éclipsé. Le joueur choisit de **briser la boucle**, ce qui mène directement à la saison 2 |

- Toutes les fins se terminent par un **épilogue** propre à chaque compagnon, selon sa loyauté et son état (vivant, exilé, racheté, sacrifié).
- Une **scène post-générique**, commune à toutes les fins, prépare la saison 2 (§7).

## 5. Arcs des compagnons

Chaque compagnon a une **quête personnelle en 3 parties**, débloquée à certains seuils de loyauté (40, 60, 80).

| Compagnon | Lien au lore | Il apprécie | Il n'apprécie pas | Quête personnelle (temps fort) |
|---|---|---|---|---|
| **Brann Forgecœur** | Neveu de Durgan (la Forge) ; son clan a scellé la forteresse des Pics | Protéger, l'honnêteté | Rituels sombres, abandonner un allié | Restaurer l'honneur du clan (acte 4) |
| **Sylwen** | Vigile Sylvestre, liée à la Sylvarche, sa mentore | La nature, la clémence | La destruction, la Domination | Soigner les Veines ; elle découvre qu'elles sont liées au temps |
| **Krag** | Fils de Gharok | Le courage, l'alliance orque | Le mensonge, la mort de son père | Choisir entre l'honneur et la rage ; succession du clan |
| **Nyx** | Fée assombrie par le Surge, membre du Cercle | La voie des Cendres, protéger le Cercle | Le fanatisme de l'Aube, la délation | Retrouver sa nature lumineuse, ou l'assumer |
| **Ignara** | Draconique, cherche sa lignée | Le pacte avec les dragons, l'audace | Le vol de l'Œuf | Retrouver la Mère-Dragon (acte 6) |
| **Ssareth** | Gardien des Archives du Temps | La vérité, sceller les Archives | Les retours dans le temps | Décider si le Sceau d'Écho doit être détruit |

### 5.1 Ce qui fait évoluer la loyauté
- Les choix de dialogue.
- Les choix majeurs.
- Jouer une partie avec ce compagnon : +1, plafonné à +5 par jour.
- Les **cadeaux** : objets ou matériaux qu'il aime.

### 5.2 Veillées
À Havre-Aube, entre deux niveaux, de courtes scènes réunissent 2 compagnons.
- Leurs échanges reflètent les fils du destin.
- Ils sont facultatifs et donnent un peu de loyauté.

## 6. Style des dialogues

### 6.1 Ton
| Actes | Ton |
|---|---|
| 1–2 | Lumineux, plein d'espoir, humour léger |
| 3–5 | Mystère, révélations |
| 6–8 | Épique, tragique |
| 9–10 | Sombre, introspectif |

L'humour vient surtout de **Brann** (bourru) et de **Nyx** (sarcastique).

### 6.2 Format
- **Portraits** en pixel art 64×64, avec 4 à 6 expressions. Le nom s'affiche dans la couleur de la faction.
- **Bulles** de 120 caractères maximum ; **2 à 6 bulles** par intro ou outro de niveau.
- Mode auto, possibilité de passer, historique des dialogues.
- **Bips vocaux** propres à chaque personnage. Pas de doublage au départ.
- **Choix** : 2 ou 3 options. Les choix majeurs ✦ sont marqués « Fil du destin ». Les options liées à une race ou une classe portent une icône. Aucun choix n'est limité en temps.
- **Répliques de combat** : phrases courtes des compagnons pendant la partie (portail ×3, Barrière basse, ultime). Elles varient selon la loyauté et les drapeaux.
- **Codex** : entrées de 600 caractères maximum.
- **Langues** : français d'abord, anglais ensuite. Tout le texte passe par des clés de traduction (`data/i18n/fr.json`).

### 6.3 Prologue
1. Planches illustrées en pixel art : la Fracture, il y a 300 ans.
2. Création du personnage.
3. Lysbourg, la veille de l'attaque.
4. Niveau 1-1.

## 7. Continuité : saison 2 et au-delà

### 7.1 Principes
1. **Chaque fin est canonique pour son joueur.** La saison 2 démarre depuis l'état de fin de saison 1 et lit les drapeaux `s1.*` : compagnons vivants ou exilés, alliances, Héritage de cendre, fin obtenue.
2. **L'intrigue principale converge** : les 4 fins mènent au même enjeu de la saison 2, mais avec une introduction, des alliés et des ennemis différents.
3. **Les fils sont déjà semés en saison 1** :
   - **L'Ourdisseur** : l'entité qui a créé les Sceaux d'Écho. On l'entrevoit dans les Archives (acte 7), dans les Fragments de Morvaen et dans la scène post-générique.
   - **Au-delà des Veines** : un nouveau continent ou plan d'existence, révélé lorsque la Fracture se referme ou est conquise.
   - **Les autres Porteurs** : la Boucle révèle qu'il en existe d'autres, dans d'autres lignes temporelles.

### 7.2 Format d'une saison
| Élément | Saison 2 (indicatif) |
|---|---|
| Zones | 5 nouvelles zones (11 à 15), 50 niveaux |
| Niveau maximum | Porté à 150 |
| Contenu | 1 nouvelle race, 1 nouvelle classe, nouvelles runes et mots runiques, nouveaux compagnons |
| Entre deux saisons | Des **Chroniques** : événements narratifs courts et Failles thématiques |

### 7.3 Technique
- Les données d'histoire sont versionnées par saison.
- La sauvegarde garde les drapeaux de toutes les saisons.
- Un **résumé « Précédemment »** est généré à partir des drapeaux du joueur au lancement d'une nouvelle saison.

## 8. Technique : dialogues et sauvegarde de l'histoire

### 8.1 Format des dialogues
- Format **JSON maison** (`data/dialogues/*.json`), lu par un petit moteur en GDScript.
- Pas d'Ink : l'intégration Ink pour Godot passe par C#, que l'export web de Godot 4 ne prend pas en charge.

```json
{
  "id": "z01_l10_outro",
  "lines": [
    { "who": "sylwen", "emo": "sad", "text": "dlg.z01_l10.sylwen_1" },
    { "choice": "sylvarche", "major": true, "options": [
      { "text": "dlg.z01_l10.opt_purify", "set": { "sylvarche_purifiee": true }, "add": { "loy.sylwen": 30, "rep.elfes": 20 } },
      { "text": "dlg.z01_l10.opt_fell",   "set": { "sylvarche_purifiee": false }, "add": { "loy.sylwen": -30 }, "if_flag_mod": { "fees_liberees": { "loy.sylwen": 15 } } }
    ]}
  ]
}
```

### 8.2 Tables Supabase (préfixe `arcane_`, données visibles par leur seul propriétaire)
| Table | Contenu |
|---|---|
| `arcane_story_state` | `user_id`, `season`, `flags` (jsonb), `counters` (jsonb : Corruption, loyautés, réputations, Dette), `current_node` |
| `arcane_timeline` | `id`, `user_id`, `parent_id`, `choice_id`, `option`, `snapshot` (jsonb, état de l'histoire seulement), `abandoned`, `created_at` |

« Changer le futur » remet en place l'instantané du nœud choisi et marque la branche précédente `abandoned`. Les données du personnage ne sont pas touchées.
