# Rangs des sorts élémentaires

> Suite de [`13-sorts.md`](13-sorts.md). Données : `data/spells.json` (champs `rank` et `school`) ; règles : `Profile.SPELL_RANKS` et `Profile.RANK_INFO`.

## Rangs (par ordre croissant)

| Rang | Profil des sorts |
|---|---|
| Novice | 15 mana, recharge 3–4 s : petits effets rapides |
| Intermédiaire | Sorts de départ (connus dès le début) |
| Apprenti | Effets spécialisés (gel, bouclier, soin…) |
| Mage | 40 mana : colonnes, barrages d'éclairs, vagues |
| Maître | 50 mana : grandes zones durables, comète |
| Archimage | 65 mana : effets de masse |
| Interdit | 80 mana, recharge 30 s, **Corruption +10** quand on l'apprend, **20 à 25 points de Barrière** à chaque lancer |

### Prix en or, proportionnel à la puissance

Tout sort s'achète à la Bibliothèque, sans niveau requis. Son prix suit sa puissance par lancer :

`prix = max(40, puissance × 1,5)`, arrondi à 10 or (à 50 or au-delà de 1 000).

La puissance (`Profile.spell_power`) se calcule à partir des caractéristiques du sort, avec `surface(r) = 0,5 + 0,5 r²` :

| Type | Calcul |
|---|---|
| Zone d'impact | dégâts × surface(rayon), plus gel × 25 × surface |
| Zone durable | dégâts par seconde × durée × surface, plus ralentissement × durée × 12 × surface, plus attraction × durée × 8 |
| Chaîne | somme des dégâts de chaque rebond |
| Colonne | dégâts × largeur × 4 |
| Barrage | nombre d'impacts × dégâts × surface |
| Vague | dégâts × surface, plus recul × 20 |
| Soin ou bouclier de la Barrière | quantité × 12 |
| Tous | plus dégâts au Nexus × 2, plus Surge × 20 |

Exemples : Étincelle 40 or, Boule de feu 150, Comète 630, Soleil noir 3 750.

Gain d'un combat gagné : 20 + 10 × niveau du lieu en or, multiplié par le bonus d'étoiles. Les sorts les plus chers demandent donc de nombreux combats.

- La Barrière paie le prix d'un sort interdit directement : le bouclier ne la protège pas.
- Un sort interdit est impossible à lancer si la Barrière ne peut pas payer son prix.
- L'IA ne lance un sort interdit que si la Barrière est au-dessus de 60 %.

## Grille (6 écoles × 7 rangs = 42 sorts)

| Rang | Feu | Givre | Foudre | Nature | Ombre | Arcane |
|---|---|---|---|---|---|---|
| Novice | Étincelle | Éclat de givre | Décharge | Ronces | Trait d'ombre | Projectile arcanique |
| Intermédiaire | Boule de feu | Pluie de givre | Éclair en chaîne | Racines | Vortex d'ombre | Onde arcanique |
| Apprenti | Brasier | Prison de glace | Javelot de foudre | Nuée de lucioles | Brume funeste | Bouclier arcanique |
| Mage | Mur de flammes | Lance de glace | Orage | Épines | Marée d'ombre | Rayon arcanique |
| Maître | Comète | Blizzard | Tempête | Étreinte de la forêt | Puits du néant | Distorsion |
| Archimage | Pluie de météores | Hiver éternel | Jugement céleste | Sève vitale | Éclipse | Nova arcanique |
| Interdit | Soleil noir | Tombeau de glace | Colère du ciel | Floraison putride | Moisson des âmes | Déchirure |

- Purifier reste à part, comme sort utilitaire.
- Brasier et Prison de glace s'apprennent aussi à la Bibliothèque ; l'arbre de compétences les offre toujours.

## Nouveaux types et effets

| Mécanisme | Sorts | Effet |
|---|---|---|
| `barrage` | Pluie de météores, Orage, Colère du ciel | `count` impacts espacés de `interval` dans un rayon `spread`. Chaque impact est une petite zone de dégâts (`radius`, `damage`). L'animation (météore ou éclair, `fx`) part 0,45 s avant l'impact |
| `barrier_cost` | Sorts interdits | Barrière prélevée à chaque lancer |
| `surge_gain` | Moisson des âmes | +10 % de Surge |
| Colonnes avec `fx` | Mur de flammes, Lance de glace, Épines, Trait d'ombre, Rayon arcanique | Gerbe d'effets le long de la colonne : flammes, éclats de glace, épines, ombre, énergie |
| Orbes teintés (`tint`) | Projectiles et chutes | Teintés à la couleur du sort |
| Tempête (`fx: storm`) | Tempête | Pluie et éclairs répétés dans la zone |

## Bibliothèque

- Filtres par école : Tous, Feu, Givre, Foudre, Nature, Ombre, Arcane.
- Une section par rang, avec la fourchette de prix.
- Le deck s'affiche en icônes : toucher une icône retire le sort.
- Chaque carte indique le rang, l'école, la puissance, le mana, la recharge et le prix (ou l'or manquant).
- Sur les sorts interdits, le prix en Corruption est affiché.

## Aperçu web

`?level=z02_l01&deck=orage,mur_flammes,tempete,comete` lance un niveau avec ces sorts.

> Ajout : école Terre et sorts de terrain (13 sorts, 55 au total) — voir [`19-terrain-interactif.md`](19-terrain-interactif.md).
