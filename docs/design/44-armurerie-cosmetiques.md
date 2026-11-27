# 44. Armurerie d'Aldric et curiosités

> Code : `scripts/ui/armory_screen.gd` (écran), `scripts/core/profile.gd` (sections « boutique » et « cosmétiques »), `data/shop.json`, `data/cosmetics.json`, `scripts/gfx/hero_model.gd` (pièces portées sur le héros en volume), `scripts/ui/cosmetic_thumb.gd` (vignettes), `scripts/ui/equipment_screen.gd` (panneau Apparence).

Aldric, armurier et marchand de curiosités, tient boutique à Havre-Aube (tuile **Armurerie** de l'accueil, à côté de la Forge). Tout s'y achète à l'or. L'écran a deux onglets : **Équipement** (armes et armures, renouvelées toutes les 5 h) et **Curiosités** (pièces cosmétiques en kits). Aldric commente en haut de l'écran (arrivage, vitrine, achat, or manquant, essayage).

## 1. Équipement : l'arrivage

- **Renouvellement toutes les 5 h**, aligné sur l'horloge (périodes de 5 h depuis l'époque Unix) : tous les joueurs voient le compte à rebours tomber au même moment. L'arrivage est tiré à la première visite de la période et gardé dans la sauvegarde (`shop.period`, `shop.offers`). Un objet vendu reste « Vendu » jusqu'au prochain arrivage.
- **7 offres** : une **vitrine** (grande carte en tête) et 6 offres courantes réparties par emplacement (arme ; armure ; tête, mains ou pieds ; main secondaire ou charme ; amulette ou anneau ; au choix).
- Les objets viennent des panoplies des zones déjà atteintes (jamais les légendaires uniques). Niveau d'objet : celui du prochain combat de l'histoire (+1 pour la vitrine, jusqu'à −2 pour les offres courantes).

| Chances | Vitrine | Offres courantes |
|---|---|---|
| Commun | — | 62 % |
| Rare | 70,8 % (le reste) | 33 % |
| Épique | 11 % | 5 % |
| Légendaire | 5,7 % | — |
| Mythique | **12,5 % (1 sur 8)** | — |

Épique ou légendaire ensemble : **1 sur 6** (16,7 %), partagés 66/34. Les chances ne sont pas affichées : sous le compte à rebours, un « bruit de boutique » (8 phrases d'Aldric, une par arrivage) laisse deviner qu'une merveille peut tomber. La tuile de l'accueil annonce « Vitrine : Mythique ! » (ou Légendaire, Épique) tant qu'une vitrine de haute rareté n'est pas vendue, sinon le temps avant le prochain arrivage.

**Prix** : base × (1 + 0,15 × niveau d'objet), arrondi à 5 or. Bases : commun 60, rare 180, épique 600, légendaire 1 800, mythique 5 000. Au niveau d'objet 15 : 195 / 585 / 1 950 / 5 850 / 16 250 or.

Chaque carte montre l'icône, la rareté, l'emplacement, le niveau d'objet, les stats, la comparaison avec l'objet porté (« Mieux que l'équipé · Puissance +14 », « Emplacement libre chez toi ») et ACHETER, ou l'or qui manque. L'objet acheté rejoint la réserve : il s'équipe, s'améliore, se grave et se fusionne comme un butin.

## 2. Curiosités : les kits cosmétiques

8 kits insolites de 4 pièces (**Tête, Tenue, Dos, Arme**), plus chers que l'équipement courant. Une pièce se porte **par-dessus** l'équipement : elle change l'apparence du héros sans toucher à l'objet équipé. Les bonus ne dépendent que des pièces portées :

- **2 pièces** d'un même kit : un bonus de stats ;
- **kit complet** (4 pièces) : un bonus spécial en combat.

| Kit | Thème | Prix / pièce | 2 pièces | Kit complet | Pièces |
|---|---|---|---|---|---|
| Mie d'Havre-Aube | Le fournil du village, au petit matin | 1 600 | +6 Vigueur | Barrière +100 points de vie | Toque enfarinée, Tablier du fournil, Sac de farine, Baguette de combat |
| Corsaire des Sables | Pillard des dunes, perroquet compris | 1 900 | +6 Destin | +15 % d'or gagné en combat | Tricorne à plume, Veste à boutons d'or, Perroquet bavard, Sabre des dunes |
| Nuit des Courges | La fête des récoltes | 1 800 | +6 Puissance | +10 % de dégâts de Feu et d'Ombre | Tête de citrouille, Robe de la récolte, Cape de feuilles mortes, Lanterne-courge |
| Chevalier de Carton | L'armure rêvée des enfants de Lysbourg | 1 500 | +6 Vigueur | Barrière +12 % | Heaume en carton, Cuirasse en carton, Cape en drap à carreaux, Épée de bois |
| Gardien des Ruches | Le miel des collines d'Ambre | 1 700 | +6 Célérité | Invocations +12 % plus rapides | Chapeau à voile, Combinaison d'apiculteur, Ruche portative, Enfumoir |
| Prince Grenouille | Un sort raté au Marais Murmurant | 1 700 | +6 Esprit | Mana +15 % plus rapide | Capuche-grenouille, Costume des mares, Nénuphar porte-bonheur, Parapluie des marais |
| Roi Sporelin | Le seigneur des sous-bois | 1 800 | +6 Esprit | Soins +20 % | Chapeau d'amanite, Robe d'humus, Hotte à champignons, Bâton-champignon |
| Voyageur Stellaire | Tombé d'une étoile filante | 3 400 | +4 à toutes les stats | Barrière +100 et Surge +15 % | Couronne d'étoiles, Robe constellée, Cape de la nuit, Sceptre-comète |

Toutes les classes et toutes les races portent tous les kits. Les bonus de 2 pièces s'ajoutent aux stats d'équipement du héros (donc à sa Puissance) ; ceux du kit complet passent par les modificateurs de combat (`barrier_flat`, `gold_bonus`, `elem_dmg.*`, `barrier_max`, `unit_speed`, `mana_regen`, `heal_bonus`, `surge_gain`).

### Onglet Curiosités

- **Essayage** : le héros en volume, qu'on fait tourner, porte ce qui est porté plus les pièces essayées (toucher une pièce l'essaie, « Essayer » enfile tout le kit). Les bonus actifs sont listés dessous.
- Une carte par kit : nom, thème, pièces portées (n/4), 4 vignettes (le héros du joueur qui ne porte que cette pièce, de face, de dos pour le dos, recadré sur la tête pour un couvre-chef ; assombrie si la pièce n'est pas à lui), prix ou « À TOI » / « PORTÉ », les deux bonus (allumés quand ils sont actifs), puis l'action de la pièce choisie (ACHETER, qui l'enfile aussitôt ; PORTER ; RETIRER) et l'achat groupé des pièces manquantes.

## 3. Apparence dans l'Équipement

Sous la poupée du héros, le panneau **Apparence** montre les 4 emplacements cosmétiques (vignette de la pièce portée, ou la silhouette de l'emplacement si rien ne recouvre l'équipement). Toucher un emplacement ouvre la liste des pièces achetées pour cet emplacement, plus « Aucune (équipement) ». **Visible / Masquée** affiche ou cache les cosmétiques sur le héros (les bonus restent actifs) ; **Armurerie** mène aux Curiosités. Les bonus des kits portés sont rappelés en bas. Brann et Sylwen n'ont pas d'apparence (pour l'instant).

## 4. Rendu des pièces

Les pièces sont construites en cubes sur le modèle du héros (`HeroModel.build(look, race, classe, cosmétiques)`) :

- **Tenue** : palette du kit (ombre, foncé, principal, clair, liseré) sur la robe ou la tunique, puis ses détails (tablier taché de farine, revers noirs et boutons d'or, ruban adhésif et blason au feutre sur le carton, fermeture éclair de l'apiculteur, ventre clair de la grenouille, petits chapeaux rouges sur l'ourlet du sporelin, étoiles brodées qui luisent…).
- **Tête** : selon le kit, la pièce se pose sur les cheveux (toque, tricorne, chapeau d'amanite, couronne), remplace la tête (citrouille, heaume en carton, chapeau à voile) ou la coiffe d'une capuche (grenouille).
- **Dos** : sac de farine, perroquet sur l'épaule, cape de feuilles, cape à carreaux, ruche, nénuphar, hotte, cape de nuit, collés au dos.
- **Arme** : remplace l'arme de la classe dans la main droite (baguette de pain, sabre, lanterne, épée de bois, enfumoir, parapluie, bâton-champignon, sceptre-comète).

Les modèles sont gardés en cache par combinaison ; les vignettes sont rendues une par image (`CosmeticThumb`) pour ne pas figer l'écran.

## 5. Sauvegarde

`shop: {period, offers: [{item, price, sold, showcase}]}` et `cosmetics: {owned: [« kit.emplacement »], worn: {emplacement: pièce}, show}`. Les sauvegardes plus anciennes reçoivent ces champs à la première lecture.

## 6. Vérifications

`tools/ui_smoke.gd` (`_armory_ok`) : chances de la vitrine sur 20 000 tirages (mythique 12,5 %, épique ou légendaire 16,7 %), arrivage de 7 offres stable dans la période et renouvelé à la suivante, prix, achat (or retiré, objet en réserve avec un identifiant, « Déjà vendu »), refus sans or, 8 kits de 4 pièces, bonus de 2 pièces dans les stats et la Puissance, bonus du kit complet dans les modificateurs, pièce non possédée refusée, barrière +100 en combat, rendu changé par chaque kit de face et de dos, Armurerie (deux onglets, essayage) et panneau Apparence.

Aperçus : `?room=armory`, `?room=armory&tab=curios`, `&cos=corsaire` (kit possédé et porté) ou `&cos=mix`.
