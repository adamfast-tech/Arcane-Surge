# Étape 4 — Classes, races et progression

> Canon : [`00-lore.md`](00-lore.md) · Combat : [`03-combat.md`](03-combat.md)

## 1. Statistiques du personnage

| Stat | Abr. | Effet par point |
|---|---|---|
| Puissance | POU | +1 % ATQ des invocations et dégâts des sorts |
| Vigueur | VIG | +1 % PV des unités, +0,5 PV de Barrière |
| Esprit | ESP | +1 mana max, +0,05 mana/s, +1 % de soins |
| Célérité | CÉL | +0,5 % de cadence du Flux, +0,3 % de vitesse des unités |
| Destin | DES | +0,1 % de chance de critique, +0,2 % de chance de loot rare |

- **Valeurs de départ par classe** : total de 50 au niveau 1.
- **Progression par niveau** : chaque stat gagne `départ / 10`, soit +5 au total par niveau.

| Classe | POU | VIG | ESP | CÉL | DES |
|---|---|---|---|---|---|
| Archer | 12 | 8 | 8 | 14 | 8 |
| Épéiste | 13 | 10 | 6 | 13 | 8 |
| Mage | 14 | 6 | 16 | 8 | 6 |
| Clerc | 8 | 12 | 16 | 7 | 7 |
| Nécromancien | 12 | 8 | 14 | 6 | 10 |
| Chevalier | 10 | 18 | 8 | 6 | 8 |
| Berserker | 16 | 14 | 4 | 10 | 6 |

## 2. Races

### 2.1 Modificateurs et dons
Chaque race donne un modificateur de stats (+5 net), 2 passifs et 1 **Don racial**. Le Don est un sort actif à part, sur un emplacement dédié, avec une recharge de 45 à 60 s.

| Race | Stats | Passifs | Don racial |
|---|---|---|---|
| Humain | +1 partout | **Polyvalence** : +10 % d'XP, +1 point de compétence tous les 20 niveaux · **Diplomatie** : options de dialogue en plus, prix −5 % | **Ralliement** : ATQ +20 % pour toutes les unités alliées pendant 6 s |
| Elfe | CÉL +4, DES +2, VIG −1 | **Œil sylvestre** : portée +10 %, critique +5 % · **Lien des Veines** : régénération de mana +10 % | **Pas de brise** : cadence +50 % pendant 5 s |
| Nain | VIG +4, POU +2, CÉL −1 | **Sang de pierre** : DÉF des unités +15 % · **Héritage runique** : +1 emplacement de rune sur les armures, Forge −10 % | **Rempart runique** : la Barrière gagne un bouclier de 20 PV |
| Orc | POU +4, VIG +3, ESP −2 | **Peau épaisse** : PV des unités +10 % · **Cri de guerre** : gain de Surge +10 % | **Charge des clans** : les unités repoussent les ennemis pendant 4 s |
| Fée | ESP +4, DES +3, VIG −2 | **Ailes** : les unités ignorent le 1er portail négatif · **Poussière d'étoiles** : soins +20 % | **Nuée féerique** : 12 lucioles qui soignent et attaquent |
| Draconique | POU +3, ESP +2 | **Sang ardent** : dégâts de Feu +20 %, résistance au Feu · **Écailles** : la Barrière subit −10 % de dégâts | **Souffle** : cône de feu |
| Reptilien | VIG +3, CÉL +2 | **Régénération** : unités +1 % PV/s, Barrière +0,2 PV/s · **Venin** : 10 % de chance d'empoisonner | **Mue** : purifie les effets négatifs, Barrière invulnérable 2 s |
| Revenant *(débloqué par l'histoire)* | POU +2, ESP +3 | **Non-mort** : immunité au poison, Ombre +15 % · **Pacte** : squelettes +20 % de stats | **Retour** : relève les 10 dernières unités alliées mortes |

Toutes les combinaisons classe × race sont autorisées. Celles qui collent au lore (ex. Orc Berserker, Elfe Archer) débloquent une **tenue d'Ordre** cosmétique.

### 2.2 Arbre racial
- 5 nœuds de 3 rangs chacun, financés par les **Points d'héritage**.
- Points d'héritage : 1 tous les 10 niveaux, plus 1 par **quête de race** (des quêtes de lore liées à la terre d'origine de la race). Environ 15 au total.

## 3. Arbres de compétences de classe

### 3.1 Règles
- **Points** :
  - 1 point de compétence par niveau à partir du niveau 2, plus 1 bonus tous les 10 niveaux : 109 au niveau 100.
  - Les 3 branches demandent **123 rangs** au total, donc on ne peut pas tout prendre.
- **Structure d'une branche** (41 rangs) :

| Palier | Seuil (points investis dans la branche) | Contenu |
|---|---|---|
| P1 | 0 | 2 nœuds passifs, 5 rangs chacun |
| P2 | 5 | 2 nœuds passifs, 5 rangs chacun, + **1 sort actif** (1 rang) |
| P3 | 10 | 3 nœuds passifs, 5 rangs chacun |
| P4 | 20 | 1 nœud de 3 rangs + **1 évolution du Champion ou de l'Ultime** |
| P5 | 30 | **Clé de voûte** (1 rang) |

- **Limite : 2 Clés de voûte actives** au maximum.
- **3e branche, la « Voie du Surge »** : verrouillée jusqu'à l'acte 3 (Marais, Cercle des Cendres). Sa Clé de voûte existe en **2 variantes**, Aube ou Cendres, selon le choix narratif de l'acte 3 (un fil du destin).
- **Réinitialisation** : à la Salle de méditation. Gratuite la 1re fois, puis le coût en or augmente. Le joueur peut sauvegarder **3 configurations**.
- **Changer de classe** : possible à partir de l'acte 2. Lore : le Sceau d'Écho permet d'« emprunter d'autres voies ».
  - Chaque classe garde son propre arbre. Les points dépendent du niveau global, donc changer ne pénalise pas.

### 3.2 Branches par classe
Format : branche · thème · 3 nœuds clés · Clé de voûte.

| Classe | Branche | Thème | Nœuds clés | Clé de voûte |
|---|---|---|---|---|
| **Archer** | Tireur d'élite | Critique, perforation | Perforation (+1 cible), Point faible (+3 % crit/rang), *Tir de précision* (sort en ligne) | **Œil du faucon** : le Champion vise l'ennemi le plus fort, critiques ×2,5 |
| | Pisteur | Pièges, Nature | Pièges à ronces, Marque du chasseur (+15 % dégâts), *Volée de filets* | **Maître de la traque** : un ennemi marqué explose en épines à sa mort |
| | Voie du Surge : Flèches astrales | Lumière, division | Flèches qui se divisent en passant un portail, élément Astral, *Constellation* | Aube : Pluie d'étoiles soigne la Barrière · Cendres : Pluie d'étoiles applique la Flétrissure |
| **Épéiste** | Duelliste | Critique, vitesse | Riposte, Élan (+VIT), *Fente* | **Danse parfaite** : chaque critique réduit les recharges de 0,2 s |
| | Lame-tempête | Foudre, chaînes | Acier chargé, Rebond (+1 chaîne), *Tranche-orage* | **Orage d'acier** : Mille lames ajoute des chaînes de foudre |
| | Voie du Surge : Lame spectrale | Clones | Double fantôme, Écho de lame, *Lames miroirs* | Aube : le Maître-lame laisse un double protecteur · Cendres : un double qui draine la vie |
| **Mage** | Pyromancie | Feu, brûlure | Combustion, Braises (+durée), *Boule de feu* améliorée | **Embrasement** : la brûlure se propage à la mort de la cible |
| | Cryomancie | Givre, contrôle | Morsure du froid, Éclats, *Prison de glace* | **Zéro absolu** : gel total dès 2 cumuls au lieu de 3 |
| | Voie du Surge : Arcanomancie | Portails, mana | Résonance runique, Flux de mana, *Faille* (crée un portail) | Aube : 1 sort Portail gratuit toutes les 15 s · Cendres : les portails négatifs deviennent ×2 mais coûtent 3 PV de Barrière |
| **Clerc** | Sanctification | Soins | Mains bénies, Prière continue, *Soin de Barrière* amélioré | **Miracle** : une fois par partie, une Barrière à 0 remonte à 50 % |
| | Jugement | Lumière offensive | Châtiment, Aura radieuse, *Lance solaire* | **Courroux céleste** : les soins en excès deviennent des dégâts de Lumière |
| | Voie du Surge : Purification | Anti-corruption, anti-soin ennemi | Purge, Sceau sacré, *Exorcisme* | Aube : purifier un portail le transforme en ×2 · Cendres : purifier vole 20 % des soins du Nexus ennemi |
| **Nécromancien** | Ossuaire | Squelettes, nombre | Os renforcés, Réveil rapide, *Horde* | **Légion** : 20 squelettes fusionnent en Colosse d'os |
| | Malédictions | Flétrissure, poison | Fléau, Peste, *Malédiction de masse* | **Pandémie** : la Flétrissure se propage aux ennemis proches |
| | Voie du Surge : Liche | Sacrifice, drain | Phylactère, Siphon, *Moisson d'âmes* | Aube : sacrifier 20 unités → Barrière +10 · Cendres : sacrifier → Surge +15 |
| **Chevalier** | Rempart | DÉF, Barrière | Armure lourde, Garde, *Bouclier levé* | **Inébranlable** : la Barrière perd au maximum 5 PV par coup |
| | Croisé | Lumière, charge | Ferveur, Élan sacré, *Charge* | **Avant-garde** : le Paladin colosse charge en ligne droite à son apparition |
| | Voie du Surge : Garde runique | Runes sur les unités | Rune de protection, Rune d'épines, *Cercle runique* | Aube : les unités renvoient 30 % des dégâts · Cendres : les unités explosent en runes à leur mort |
| **Berserker** | Carnage | ATQ, vol de vie | Soif de sang, Frénésie, *Tourbillon* | **Soif** : le vol de vie des unités soigne aussi la Barrière (1 %) |
| | Totem | Cris, renforcement des alliés et des bots | Cri de guerre, Totem de rage, *Hurlement* | **Chef de clan** : les bots gagnent +30 % de stats |
| | Voie du Surge : Fureur primordiale | Risque et récompense | Au bord du gouffre, Sang bouillant, *Déchaînement* | Aube : sous 25 % de Barrière, Rage permanente · Cendres : la Rage consomme de la Barrière pour un bonus d'ATQ ×3 |

Le détail des nœuds (valeurs par rang) ira dans `data/skill_trees/*.json` pendant le prototype.

## 4. Création et personnalisation du personnage
- **Pseudo** : celui du profil Académie.
- **Choix** : race, classe, sexe ou silhouette, visage, cheveux, couleurs (peau, yeux, tenue), traits de race :
  - ailes pour les Fées ;
  - cornes et écailles pour les Draconiques ;
  - motifs pour les Reptiliens ;
  - etc.
- **Couleurs des sorts** : variante cosmétique de la teinte des invocations et des sorts, sans effet sur le jeu.

## 5. Bots
- Les bots suivent les mêmes règles : stats, arbres, équipement, dons raciaux.
- **Compagnons** : race fixe, classe changeable. **Mercenaires** : race et classe libres.
- **XP** : un bot gagne 80 % de l'XP du joueur. Un bot laissé sur le banc gagne 30 %.
- **Loyauté des compagnons** (de 0 à 100) :
  - au-dessus de 75 : passif d'amitié (+5 % de stats) et dialogues exclusifs ;
  - sous 25 : risque de trahison dans l'acte 6, avec une rédemption possible qui garde l'Héritage de cendre (voir `06-monde.md` §4.1).

## 6. Niveaux et XP
- Niveau maximum : **100**, aligné sur les zones.
- XP pour passer au niveau suivant : `XP(L) = 100 × L^1,6`.
- Source d'XP :
  - **partie** : 80 % ;
  - **Salle d'entraînement** : 10 % (faible, plafonnée par jour) ;
  - **quêtes de lore** : 10 %.
