# Animations propres à chaque sort

## Le constat

Beaucoup de sorts partageaient la même animation :
- 13 sorts reprenaient le « météore » ;
- 7 reprenaient le vortex ;
- 7 reprenaient la boule de feu ;
- 4 reprenaient les racines.

Les sorts d'ombre en souffraient le plus : Vortex, Brume funeste, Puits du néant et Linceul étaient identiques, et Éclipse ressemblait à un météore.

## Fonctionnement

- **Côté simulation.** Chaque évènement émis pendant la résolution d'un sort porte son identifiant (`sid`). Un évènement `spell` marque aussi le lancement, avec le point visé et le lanceur. Les impacts différés des barrages gardent leur identifiant.
- **Côté rendu.**
  - `SpellFx` confie ces évènements à `SpellSig` (`scripts/battle/spell_sig.gd`).
  - `SpellSig` appelle la méthode `s_<sort>(phase, évènement)`.
  - La méthode renvoie vrai quand elle remplace l'animation générique de cette phase.
- **Éléments disponibles.**
  - Sprites pixel-art teintés (`FxArt.sprite`) : éclat, cristal, roche, os, crâne, étoile, épée, flèche, plume, feuille, bulbe, hache, tombe, main osseuse, spectre, lance, ronce, étincelle, bouclier.
  - Projectiles animés : arc, rotation par images, ondulation, traînée, fondu.
  - Sprites qui sortent du sol, sprites en orbite, sphères (soleil noir, trou noir, astre).
  - Glyphes au sol : runes, pentacle, hexagramme, flocon, cadran, croix, soleil, triangle.
  - Tracés : faux, âmes, fissures, marée, tentacules, couronne verticale, disque d'accrétion, lucioles, rayon épais, entaille, ondes sonores, constellation, rafales, alvéoles, arcs électriques, lianes, bulles.
- **Lisibilité.** Les tracés sont épaissis (trois traits) pour rester lisibles sur un écran de téléphone.
- **Garantie.** Le smoke test vérifie que chaque sort du jeu a sa signature déclarée.

Certains sorts gardent l'animation générique de leur phase, dont ils sont désormais les seuls utilisateurs :
- Boule de feu, Brasier, Mur de flammes, Météore arcanique ;
- Pluie de givre ;
- Éclair en chaîne, Orage, Tempête ;
- Racines, Épines ;
- Vortex d'ombre ;
- Onde arcanique ;
- Pic rocheux, Mur de pierre, Séisme ;
- Purifier.

## Signatures

| École | Sort | Signature |
|---|---|---|
| Feu | Étincelle | Étincelle zigzagante, gerbe d'éclats |
| | Comète | Arrive à l'horizontale depuis le fond, longue queue ; cratère fissuré |
| | Pluie de météores | Rochers en rotation et fumants ; petits cratères |
| | Soleil noir | Sphère noire couronnée de flammes, qui descend ; implosion puis éruption pourpre |
| | Terre brûlée | Anneau de flammes au sol, fissures ardentes |
| Givre | Éclat de givre | Éclat de glace ; éclats qui s'éparpillent, flocon |
| | Prison de glace | Cage de cristaux qui jaillissent, hexagramme |
| | Lance de glace | Lance de glace géante le long de la colonne, cristaux qui poussent |
| | Blizzard | Neige qui tourbillonne, rafales circulaires, brouillard |
| | Hiver éternel | Flocon géant, onde de froid, neige qui retombe |
| | Tombeau de glace | Pieux de glace qui tombent du ciel, anneau de cristaux |
| | Banquise | Fissures de glace, éclats |
| Foudre | Décharge | Arc bleu pâle, étincelles |
| | Javelot de foudre | Javelot doré et arcs électriques le long de la colonne |
| | Jugement céleste | Foudre dorée verticale sur chaque cible, halos |
| | Colère du ciel | Ciel assombri, triples éclairs dorés |
| | Champ statique | Arcs électriques au sol |
| Nature | Ronces | Ronces à baies rouges |
| | Nuée de lucioles | Lucioles qui volent jusqu'à la Barrière |
| | Étreinte de la forêt | Racines géantes, pluie de feuilles, ombre de canopée |
| | Sève vitale | Lianes le long de la Barrière, feuilles qui montent |
| | Floraison putride | Bulbes qui éclosent, spores |
| | Marais | Bulles, ondes d'eau |
| Ombre | Trait d'ombre | Pique d'encre et traînée de volutes noires |
| | Brume funeste | Nappes sombres au ras du sol, crânes qui affleurent |
| | Marée d'ombre | Mur liquide qui déferle, tentacules |
| | Puits du néant | Trou noir, disque d'accrétion, matière aspirée |
| | Éclipse | Lune noire devant une couronne d'astre ; colonne de lumière noire |
| | Moisson des âmes | Faux spectrale qui balaie le cercle, âmes qui filent vers le lanceur |
| | Miasme | Bulles et brume toxiques |
| | Linceul (Nyx) | Draps spectraux qui descendent en ondoyant |
| | Ossements (Nyx) | Os qui tournoient ; éclats d'os |
| | Horde | Fissures, mains osseuses qui sortent de terre |
| | Malédiction de masse | Pentacle tournant, flammes pourpres |
| | Sacrifice d'âmes | Âmes qui s'élèvent, implosion, triangle |
| Arcane | Projectile arcanique | Orbe ondulant ; triangle runique |
| | Bouclier arcanique | Alvéoles hexagonales au-dessus de la Barrière |
| | Rayon arcanique | Rayon épais depuis le lanceur, anneaux de runes |
| | Distorsion | Cadran géant, aiguilles, particules suspendues |
| | Nova arcanique | Rayons en étoile, hexagramme |
| | Déchirure | Faille verticale dans l'air ; éclats projetés |
| | Rune piège | Cercle de runes |
| Terre | Jet de pierres | Pierre qui tournoie ; poussière |
| | Éboulement | Rochers géants, fissures |
| | Faille tellurique | Faille rougeoyante qui s'ouvre, roches projetées |
| | Cataclysme | Séisme, pluie de rochers, ciel rougi |
| Classes et compagnons | Charge | Bouclier qui fonce, traînée de poussière |
| | Volée de flèches | Pluie oblique de flèches |
| | Bouclier levé | Rang de boucliers sur la Barrière |
| | Tir de précision | Flèche, anneaux de perforation |
| | Tourbillon | Haches en orbite, entailles en croissant |
| | Bond furieux | Saut en arc, onde d'atterrissage |
| | Lance solaire | Lance dorée, soleil au bout |
| | Fente | Entaille blanche, éclats d'acier |
| | Tranche-orage | Chaîne dorée, entailles en croissant |
| | Prière | Plumes dorées qui descendent, colonnes de lumière |
| | Hurlement | Ondes sonores |
| | Constellation | Étoiles reliées par des traits |
| | Lames miroirs | Éclats de miroir en orbite |
| | Exorcisme | Croix sacrée, colonne |
| | Cercle runique | Cercle de runes et hexagramme qui tournent en sens contraires |
| | Rage primordiale | Brume de sang, ondes |
| Ultimes | Pluie d'étoiles | Étoiles filantes, rayons |
| | Mille lames | Épées qui tombent du ciel |
| | Jugement solaire | Astre qui descend, soleil au sol, colonne dorée |
| | Armée des morts | Pierres tombales en cercle, feux follets, pentacle |
| | Rempart sacré | Dôme doré, boucliers qui rayonnent |
| | Déchaînement | Onde de feu rouge, fissures |

## Corrections au passage

- **Carrés noirs.** Les particules inactives s'affichaient en carrés noirs (le billboard ignorait leur échelle nulle). Les matériaux de particules gardent désormais l'échelle (`billboard_keep_scale`).
- **Évènement de colonne.** La simulation émet l'évènement `column` pour tous les sorts en colonne, y compris ceux sans champ `fx` : Javelot, Tir de précision, Charge, Bond.

## Aperçu

Les paramètres d'URL suivants lancent les sorts tour à tour au même point, avec des cibles :
- `?level=z01_l05&demo=eclipse,linceul&every=3` ;
- `&slow=0.3` pour le ralenti ;
- `&class=…` avec `demo=ultime` pour voir une Ultime.
