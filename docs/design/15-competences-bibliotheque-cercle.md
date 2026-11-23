# Étape 10.3 — Entraînement, Bibliothèque, Cercle

> Règles d'origine : [`04-classes-races.md`](04-classes-races.md) §3 et §5, maquettes `mockups/Arbre.dc.html` et `mockups/Preparation.dc.html`. Données : `data/skill_trees/mage.json`, `data/spells.json`. Code : `scripts/core/profile.gd`, `scripts/ui/skill_tree_screen.gd`, `library_screen.gd`, `circle_screen.gd`, effets dans `scripts/battle/sim.gd`.

## 1. Entraînement : arbre du Mage

- **Points** : 1 par niveau à partir du niveau 2, plus 1 tous les 10 niveaux (calculés depuis le niveau).
- **Paliers** : 0, 5, 10, 20 et 30 points investis dans la branche ouvrent les paliers 1 à 5.
- **Clés de voûte** : 2 au plus.
- **Réinitialisation** : gratuite la 1re fois, puis 100 or de plus à chaque fois. Elle est aussi proposée à la Salle de méditation (étape 13.4, [`27-meditation-compagnons.md`](27-meditation-compagnons.md)).

| Palier | Pyromancie (Feu, brûlure) | Cryomancie (Givre, contrôle) |
|---|---|---|
| 1 (0) | Combustion : brûlure +8 % · Ardeur : sorts de Feu +4 % | Morsure du froid : sorts de Givre +6 % · Gel profond : gel +0,2 s |
| 2 (5) | Braises : brûlure +0,4 s · Étincelle : rayon de la Boule de feu +6 % · **Sort : Brasier** | Éclats : ennemis gelés +5 % de dégâts subis · Givre persistant : Pluie +0,3 s · **Sort : Prison de glace** |
| 3 (10) | Fournaise : +1 % de critique · Feu dévorant : ennemis en feu +4 % de dégâts subis · Flamme sobre : −2 % de mana | Hiver : ralentissement des zones +4 % · Blizzard : rayon de la Pluie +6 % · Cristal de mana : régénération +4 % |
| 4 (20) | Cœur ardent (3 rangs) : Feu +5 % · **Évolution : Météore+** (+30 % de rayon, +25 % de dégâts) | Cœur de glace (3 rangs) : Givre +5 % · **Évolution : Golem de givre** (Champion de Givre, +30 % de PV) |
| 5 (30) | **Clé de voûte : Embrasement** (la brûlure se propage à la mort de la cible) | **Clé de voûte : Zéro absolu** (gel dès 2 cumuls) |

Les valeurs sont par rang ; les nœuds passifs ont 5 rangs. Arcanomancie, la « Voie du Surge », s'ouvrira à l'acte 3.

## 2. Bibliothèque : deck et grimoire
- **Deck** : 7 sorts au plus emportés en combat, au moins 1. En combat, ils sont rangés dans l'ordre du grimoire.
- **Sorts de départ** : Boule de feu, Pluie de givre, Racines, Éclair en chaîne, Vortex d'ombre, Onde arcanique, Purifier.
- **À apprendre** (or et niveau) :

| Sort | Prix | Effet |
|---|---|---|
| Bouclier arcanique | 150 or, niveau 3 | Bouclier de 20 sur la Barrière |
| Javelot de foudre | 250 or, niveau 4 | 55 dégâts sur toute une colonne |
| Nuée de lucioles | 300 or, niveau 5 | Répare 20 points de Barrière |

- **Débloqués par l'arbre** :

| Sort | Origine | Effet |
|---|---|---|
| **Brasier** | Pyromancie, palier 2 | Zone de feu pendant 4 s, qui enflamme les ennemis |
| **Prison de glace** | Cryomancie, palier 2 | Gèle tous les ennemis d'une petite zone pendant 2 s ; les boss y résistent |

## 3. Le Cercle : compagnons
- **Pour Brann et Sylwen** :
  - **ordre par défaut** : Focus Nexus, Défends, Suis-moi ou Libre ;
  - **sort emporté** : Brann a Bouclier levé ou Charge du Bastion, Sylwen a Tir de précision ou Volée de flèches.
- **Côtés** : Brann à gauche, Sylwen à droite par défaut. Un bouton les échange.
- **Amitié** : à partir de 75 de loyauté, le compagnon gagne +5 % de stats.
- **Niveau** : les compagnons ont le niveau du joueur − 1. En combat, toucher un compagnon change encore son ordre.

## 4. Havre-Aube
Trois tuiles s'ajoutent sous Carte et Équipement :
- **Entraînement** : points disponibles, en or s'il en reste ;
- **Bibliothèque** : taille du deck ;
- **Le Cercle** : loyauté des compagnons.

Seul l'Observatoire (« Changer le futur ») reste à venir.
