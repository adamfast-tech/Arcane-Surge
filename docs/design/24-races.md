# Races : passifs, Don racial et héritage (étape 13.2)

> Ébauche : [`04-classes-races.md`](04-classes-races.md) §2. Données : `data/party.json` (`passive_mods`, `don_id`, `don_cd`), `data/race_trees.json`. Code : `Profile.race_mods` / `don_info` / `heritage_*`, `BattleSim.use_don` et les passifs dans la simulation.

## Passifs (actifs en combat et hors combat)

| Race | Passifs (effets) |
|---|---|
| Humain | XP +10 % ; +1 point de compétence tous les 20 niveaux ; prix des sorts et de la Forge −5 % ; choix de dialogue réservés aux Humains (ex. négocier le Traité d'Ambre) |
| Elfe | Portée des invocations +10 % ; régénération de mana +10 % ; critique +5 % |
| Nain | Défense des invocations +3 (Sang de pierre) ; Forge −10 % |
| Orc | PV des invocations +10 % ; jauge Surge +10 % |
| Fée | Chaque invocation survole son 1er portail négatif ; soins de la Barrière +20 % |
| Draconique | Sorts de Feu +20 % ; invocations −20 % de dégâts de Feu ; Barrière −10 % de dégâts subis |
| Reptilien | Invocations +1 % de PV par seconde ; Barrière +0,2 PV/s ; 10 % de chance d'empoisonner à chaque coup |
| Revenant (verrouillé) | Immunité aux mares de poison ; Ombre +15 % ; squelettes +20 % de stats |

## Don racial (bouton DON, touche D)

- Il apparaît sur la rangée du Champion (paysage : dans la grille).
- Une recharge de 30 % est imposée au début du combat.

| Race | Don | Recharge | Effet |
|---|---|---|---|
| Humain | Ralliement | 50 s | Attaque des invocations +20 % pendant 6 s |
| Elfe | Pas de brise | 45 s | Cadence du Flux +50 % pendant 5 s |
| Nain | Rempart runique | 55 s | Bouclier de Barrière : 20 + niveau/2 |
| Orc | Charge des clans | 50 s | 4 s : chaque coup d'invocation repousse l'ennemi |
| Fée | Nuée féerique | 60 s | 12 lucioles de Lumière (dissipent la brume, survolent les portails négatifs) ; Barrière +10 |
| Draconique | Souffle | 45 s | Cône de feu devant le héros (ou au curseur) : dégâts, brûlure, braises au sol |
| Reptilien | Mue | 60 s | Barrière invulnérable 2 s ; poisons et ralentissements des invocations purgés ; mares proches assainies |
| Revenant | Retour | 60 s | Relève les 10 dernières invocations mortes |

L'IA de test lance le Don dès qu'il est prêt : Rempart et Mue seulement si la Barrière descend sous 75 %.

## Arbre d'héritage (Entraînement, onglet « Héritage »)

- 5 nœuds de 3 rangs par race :
  - 2 ou 3 nœuds de stats dans le thème de la race ;
  - 1 nœud de puissance du Don (+15 %/rang : durée, dégâts ou nombre selon le Don) ;
  - 1 nœud de recharge du Don (−8 %/rang).
- **Points d'héritage** : 1 tous les 10 niveaux, plus 1 par acte terminé (boss de fin de zone vaincu), en attendant les quêtes de race de l'ébauche.
- Les rangs restent attachés à la race ; l'arbre n'est pas réinitialisé avec celui de la classe.
