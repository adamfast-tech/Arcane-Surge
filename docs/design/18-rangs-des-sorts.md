# Rangs des sorts élémentaires

> Suite de [`13-sorts.md`](13-sorts.md). Données : `data/spells.json` (champs `rank` et `school`) ; règles : `Profile.SPELL_RANKS` et `Profile.RANK_INFO`.

## Rangs (par ordre croissant)

| Rang | Niveau requis | Prix à la Bibliothèque | Profil des sorts |
|---|---|---|---|
| Novice | 1 | 50 or | 15 mana, recharge 3–4 s : petits effets rapides |
| Intermédiaire | 1 | 120 or | Sorts de départ (connus dès le début) |
| Apprenti | 5 | 250 or | Effets spécialisés (gel, bouclier, soin…) |
| Mage | 10 | 500 or | 40 mana : colonnes, barrages d'éclairs, vagues |
| Maître | 16 | 900 or | 50 mana : grandes zones durables, comète |
| Archimage | 24 | 1 500 or | 65 mana : effets de masse |
| Interdit | 32 | 2 500 or | 80 mana, recharge 30 s, **Corruption +10** quand on l'apprend, **20 à 25 points de Barrière** à chaque lancer |

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
- Une section par rang, avec son niveau ; « verrouillé » tant que le niveau n'est pas atteint.
- Le deck s'affiche en icônes : toucher une icône retire le sort.
- Chaque carte indique le rang, l'école, le mana et la recharge.
- Sur les sorts interdits, le prix en Corruption est affiché.

## Aperçu web

`?level=z02_l01&deck=orage,mur_flammes,tempete,comete` lance un niveau avec ces sorts.
