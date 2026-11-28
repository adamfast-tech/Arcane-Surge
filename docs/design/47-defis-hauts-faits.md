# 47. Défis et hauts faits

> Code : `scripts/core/profile.gd` (section « défis et hauts faits »), `data/challenges.json`, `scripts/ui/quests_screen.gd`, `scripts/battle/battle_screen.gd` (fin de combat), `scripts/battle/sim.gd` (compteurs : sorts lancés par élément, Barrière au plus bas).

## 1. Défis

- **Trois défis du jour**, tirés chaque jour (minuit UTC), et **deux défis de la semaine**, tirés chaque semaine, parmi des modèles (`data/challenges.json`). Le tirage ne propose que ce qui est faisable : la Tour seulement si elle est ouverte, une zone déjà atteinte, un élément présent dans le deck.
- Ce qui les fait avancer : remporter des combats (dans une zone donnée), avec 3 étoiles, sans que la Barrière passe sous 75 %, vaincre des ennemis, un boss ou un mini-boss, lancer des sorts (d'un élément), gagner de l'or en combat, graver une rune, fusionner, améliorer un objet, acheter à l'Armurerie, atteindre un étage de la Tour des Échos, et (la semaine) accomplir des défis du jour.
- Un défi accompli se **réclame** dans l'écran Défis. Du jour : or et poussière selon le niveau du héros, parfois une rune. De la semaine : beaucoup d'or et de poussière, une rune de niveau III et **une curiosité** de l'Armurerie pas encore possédée (de l'or si la collection est complète).
- Compte à rebours jusqu'au prochain tirage, à côté de chaque section.

## 2. Hauts faits et titres

29 hauts faits, chacun avec son **titre** : victoires (1, 50, 200), étoiles (30, 120), ennemis vaincus (1 000, 10 000), sorts lancés (500), combats sans entamer la Barrière (10), boss (10), chacune des 7 zones terminée, fusions (5, 25), gravures (10), un objet Mythique, un kit de curiosités complet, 16 curiosités, 10 achats à l'Armurerie, Tour des Échos (10, 25, 50), 21 défis du jour, niveau 30.

Ils se débloquent d'eux-mêmes (en fin de combat, à la Forge, à l'Armurerie, à Havre-Aube). Le titre choisi (onglet Hauts faits : toucher un haut fait débloqué) s'affiche sous le nom du héros à Havre-Aube et sur la carte du héros.

## 3. Écrans

- **Havre-Aube** : tuile « Défis » (« 2 à réclamer ! » ou « Aujourd'hui 1 / 3 »).
- **Défis** : onglet Défis (cartes avec progression, récompenses, RÉCLAMER) et onglet Hauts faits (titre affiché, grille : débloqués en or, les autres avec leur progression).
- **Fin de combat** : les hauts faits débloqués et le nombre de défis à réclamer.

## 4. Vérifications

`tools/ui_smoke.gd` (`_quests_tower_ok`) : 3 défis du jour et 2 de la semaine, stables dans la journée ; trois victoires accomplissent les défis correspondants ; une récompense se réclame une seule fois ; « Premiers pas » se débloque ; un titre verrouillé est refusé.
