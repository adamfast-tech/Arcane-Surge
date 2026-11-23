# Salle de méditation et compagnons (étape 13.4)

> Ébauche : [`04-classes-races.md`](04-classes-races.md) §3.1 (réinitialisation, 3 configurations, changer de classe dès l'acte 2) et §5 (bots), [`05-equipement-craft.md`](05-equipement-craft.md) §3 (Salle de méditation, Sœur Aelis, Harmonie).

Code :
- `Profile` : `meditation_unlocked`, `change_class`, configurations, `harmony`, compagnons (`companion_*`, `equip_to`, `holder_of`, `bots_opts`) ;
- `scripts/ui/meditation_screen.gd` ;
- Cercle et Équipement ;
- `BattleSim._setup_casters`.

## Salle de méditation (Sœur Aelis, Ordre de l'Aube)

Elle s'ouvre à la fin de l'acte 1 (Sylvarche vaincue en 1-10). La tuile MÉDITATION apparaît à Havre-Aube ; avant cela, elle indique « Fin de l'acte 1 ».

| Fonction | Règle |
|---|---|
| **Ta voie** | Changer de classe gratuitement (le Sceau d'Écho permet d'« emprunter d'autres voies »). Chaque classe garde son arbre, et les points dépendent du niveau global : changer ne pénalise pas. Le grimoire est commun. |
| **Voies des compagnons** | Un compagnon garde sa race mais peut changer de classe. Son invocation, ses stats, son rôle et les sorts proposés au Cercle suivent sa voie. Si son sort ne convient plus, il passe au premier sort de la nouvelle classe. |
| **Configurations** | 3 emplacements. Chacun garde la classe, l'arbre de cette classe, le deck et le mode Deck ou Tiroir. Charger est gratuit et remplace l'arbre de la classe par celui de la configuration. |
| **Réinitialisation** | Celle de l'Entraînement : gratuite la 1re fois, puis 100 or de plus à chaque fois. Elle reste aussi disponible à l'Entraînement. |
| **Harmonie** | Méditer fait baisser la Corruption de 5. Coût : 100 or, puis +50 à chaque séance. |

## Compagnons

**Niveau et XP.** Chaque compagnon a son propre niveau et sa propre XP.
- **Gain :**
  - en combat, un compagnon gagne 80 % de l'XP du héros ;
  - resté à Havre-Aube, il en gagne 30 %.
  - Il suit la même courbe (`100 × L^1,6`). L'XP d'un niveau bas étant plus courte, un compagnon en retard rattrape vite.
- **Plancher :** un compagnon n'est jamais à plus de 5 niveaux sous le héros.
- **Anciennes sauvegardes :** chaque compagnon démarre au niveau du héros − 1, comme avant.
- **Fin de partie :** l'écran affiche l'XP de chacun et ses montées de niveau.

**Équipement.**
- **Écran :** il propose en haut « Toi » et chaque compagnon recruté ; le bouton « Équiper » du Cercle y mène directement.
- **Règles :** les compagnons ont les mêmes emplacements que le héros. Un objet n'a qu'un porteur : l'équiper sur quelqu'un le retire du précédent, et un objet porté ne peut pas être recyclé.
- **En combat :** les stats de l'équipement s'ajoutent à celles du compagnon, et l'élément de son arme passe à ses invocations.

**Classes.** Sorts proposés au Cercle selon la voie du compagnon :

| Voie | Sorts |
|---|---|
| Chevalier | Bouclier levé, Charge du Bastion |
| Archer | Tir de précision, Volée de flèches |
| Berserker | Hache tournoyante, Bond furieux |
| Nécromancien | Linceul, Ossements |
| Mage | Boule de feu, Éclair en chaîne |
| Clerc | Prière, Lance solaire |
| Épéiste | Fente, Tranche-orage |

**Simulation.** `battle_opts()["bots"]` transmet, pour chaque compagnon recruté :
- son niveau ;
- sa classe, qui détermine l'invocation et les stats de base ;
- son équipement ;
- l'élément de son arme.

**Pas encore :** les arbres de compétences et les Dons raciaux des compagnons (04 §5).

## Aperçu

`?room=meditation`, `?room=circle` et `?room=equipment&who=brann` ouvrent directement une salle (prévisualisation).
