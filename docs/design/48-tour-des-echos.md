# 48. La Tour des Échos

> Code : `scripts/core/profile.gd` (section « Tour des Échos »), `scripts/ui/tower_screen.gd`, `scripts/battle/battle_screen.gd` (étage composé, fin d'étage), `scripts/main.gd` (`_show_tower`, `_start_tower_floor`), `scripts/core/cloud.gd` (classement). Base Supabase : table `arcane_tower_scores`, fonctions `arcane_tower_submit`, `arcane_tower_board`, `arcane_week`.

Ascension sans fin, ouverte après l'acte 1 (la Sylvarche vaincue).

## 1. Les étages

- Chaque étage est un niveau de l'histoire, pris dans les zones déjà atteintes : une zone par dizaine d'étages, en boucle (étages 1 à 10 au Bois des Lucioles, 11 à 20 aux Collines d'Ambre…).
- Étages 5, 15, 25… : le **mini-boss** de la zone ; 10, 20, 30… : son **boss** ; sinon un assaut, une purification ou un siège (jamais une escorte).
- Ce qui monte : points de vie du Nexus et des tours (+5 % par étage), du boss (+6 %), budget des vagues (+4 %), niveau des ennemis, et la difficulté générale (+3 % par étage). Le décor est celui du niveau d'origine ; les fils de l'histoire n'y jouent pas.
- Les compagnons du Cercle montent avec le héros ; équipement, runes, arbres et cosmétiques comptent.

## 2. Bonus

Après chaque étage franchi : **un bonus à choisir parmi trois**, qui dure toute l'ascension et se cumule : Puissance (+12 % de dégâts des sorts), Cadence (+15 %), Rempart (+60 de Barrière), Bastion (+12 % de Barrière), Source vive (mana +20 %), Œil sûr (+6 % de critiques), Économie (sorts −10 %), Renforts (invocations +12 %), Écho du Surge (+20 %), Lumière douce (soins +25 %), Mains vives (recharges −10 %).

## 3. Récompenses et fin

- Chaque étage : or (40 + 8 par étage ; ×2 au mini-boss, ×3 au boss) et poussière. Mini-boss : une rune (niveau qui monte avec l'étage). Boss : un objet (Rare, Épique dès l'étage 20, Légendaire dès 40).
- Une défaite (ou quitter un étage en cours) **met fin à l'ascension** ; on peut aussi abandonner entre deux étages. L'étage franchi le plus haut est le record ; celui de la semaine va au classement.

## 4. Classement de la semaine

- Semaine comptée par le serveur. À l'ouverture de la Tour, si le record de la semaine a progressé et que le joueur est connecté, il est envoyé (`arcane_tower_submit`) avec l'allure du héros (apparence, race, classe, cosmétiques visibles, équipement) ; le serveur garde le meilleur étage.
- Le classement (50 premiers, `arcane_tower_board`) est lisible par tous. Les **trois premiers sont sur un podium, en volume**, avec l'allure de leur meilleure ascension (le premier célèbre sa victoire) ; les suivants en liste, le joueur surligné.
- Sécurité : lecture publique ; aucune écriture directe dans la table (seule la fonction, qui n'écrit que la ligne du joueur connecté et refuse un étage hors de 0 à 1 000).

## 5. Écrans

- **Havre-Aube** : tuile « Tour des Échos » (record).
- **Tour des Échos** : commencer l'ascension ; ou l'étage suivant (numéro, type, nom, zone, renforcement, bonus acquis, gains) avec MONTER et Abandonner ; ou le choix du bonus ; records ; classement.
- **Fin d'étage** : « Étage N franchi » (or, poussière, rune ou objet, hauts faits) → CHOISIR UN BONUS ; ou « L'ascension s'arrête » (record).

## 6. Vérifications

`_quests_tower_ok` : étages bien composés (mini-boss, boss, pas d'escorte ni de fils d'histoire), renforcés ; une victoire donne de l'or, l'étage suivant et trois bonus ; un bonus choisi s'applique aux combats ; une défaite clôt l'ascension et fixe le record ; un étage se lance en combat ; l'écran de la Tour propose de commencer.

Aperçu : `?room=tower`.
