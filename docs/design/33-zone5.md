# Zone 5 · Désert de Verre (étape 15.1)

Suite de [`28-zone4.md`](28-zone4.md). La conception vient de [`06-monde.md`](06-monde.md) : zone 5, bestiaire, Sphinx de verre, palette. La narration de l'acte 5 (le Collège oublié, les traces de Morvaen, le choix 5-9 du Journal) est l'étape 15.2.

## Niveaux (niveaux globaux 41 à 50)

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 5-1 | Les Dunes de Verre | Assaut | Scarabées et chacals ; cycle soleil/lune, portail de Givre |
| 5-2 | Le Mirage | Assaut | Un portail ×3 est un mirage |
| 5-3 | L'Oasis | Assaut | 2 Prêtresses solaires (soins plus forts le jour), Golems de grès |
| 5-4 | Les Miroirs | Assaut | 2 miroirs de verre, Momies archères, Constructs-miroirs |
| 5-5 | Le Scarabée-soleil | Mini-boss | Soleil roulé en couloirs, plein jour forcé, carapace que seul le Givre traverse |
| 5-6 | La Caravane | Escorte | Caravane (7 000 PV), embuscades de chacals, mirage |
| 5-7 | La Nuit des Spectres | Assaut | Commence de nuit (35 s), Spectres du Collège qui se dématérialisent |
| 5-8 | Les Sceaux du Collège | Purification | 2 sceaux, portail de Lumière mobile, un miroir, Prêtresses solaires |
| 5-9 | Le Collège oublié | Siège | 2 Nexus, tour, 2 miroirs, Scorpions de cristal |
| 5-10 | Le Sphinx de verre | Boss | Énigmes entre les phases, rayons réfléchis, mirages, cycle accéléré |

- Les ennemis sont surtout de **Feu** : le **Givre** les bat. Les portails de la zone sont surtout de Givre, avec de la Lumière contre les ennemis d'Ombre (Momies, Spectres, Sphinx).
- Le jour avantage le Feu des ennemis ; la nuit avantage ton Givre.

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Scarabée de verre | sbire | Feu |
| Chacal des sables | coureur | Très rapide |
| Golem de grès | bouclier | Bloque de face (60 %) |
| Momie archère | tireur | Ombre, à distance (3,4 m) |
| Construct-miroir | brute | Lumière ; renvoie 40 % des tirs |
| Spectre du Collège | lanceur | Ombre ; après chaque sort, il se dématérialise et réapparaît 1,1 m plus près (tant qu'il est au-delà de 7,5 m et qu'il ne combat pas) |
| Prêtresse solaire | soigneuse | Soigne le Nexus et les unités ; ses soins sont ×1,5 le jour |
| Scorpion de cristal | brute élite | 440 PV, défense 22 ; renvoie 25 % des tirs |
| Miroir de verre | structure | Immobile, 420 PV ; renvoie 50 % des tirs ; le jour, un rayon de soleil le long de sa colonne |
| **Scarabée-soleil** | mini-boss | Feu |
| **Sphinx de verre** | boss | Ombre ; énigmes |
| Caravane | escorte | À conduire jusqu'aux ruines |

## Mécaniques de zone

**Cycle soleil/lune** (`daynight` : `{day, night, start}`).
- Le jour, tous les dégâts de Feu sont ×1,25, amis comme ennemis ; la nuit, ce sont les dégâts de Givre.
- Le ciel annonce « LE SOLEIL SE LÈVE » ou « LA NUIT TOMBE ».
- L'arène passe d'un soleil doré à une lune bleutée, et le décor de fond suit.
- Le bandeau d'aide affiche la phase et le temps restant.

**Mirages** (portail `mirage: true`, `spots` : emplacements possibles ; `mirage_reform` en secondes).
- Un mirage ressemble à un vrai portail (×3, ×2 ou +5) mais n'a aucun effet, et il ondule légèrement.
- Il se révèle quand une invocation l'approche (ou quand Purifier le touche) : « MIRAGE ! », puis il se dissipe.
- Il se reforme ailleurs sur sa rangée après 12 s, avec un autre faux effet.
- L'IA ne s'y laisse prendre qu'à moitié.

**Miroirs** (`mirrors` : `[{x, y}]`, unité `glass_mirror`).
- Ils renvoient la moitié des tirs (unités à distance) au tireur.
- Le jour, toutes les 8 s, ils projettent un rayon annoncé en or le long de leur colonne : il blesse les invocations, pas la Barrière.
- La nuit, ils s'éteignent.
- Nouveau champ d'unité `reflect`, aussi porté par le Construct-miroir et le Scorpion de cristal.

**Sphinx de verre.**
- **Énigmes** (`riddle` : `need`, `time`, `y`, `xs`) : en entrant en phases 2 et 3, il pose une énigme du lore et ouvre 3 portails-réponses, dans un ordre tiré au sort.
  - Le bandeau « ÉNIGME DU SPHINX » affiche la question.
  - Seules les invocations du héros répondent (12 par portail ; celles des compagnons passent sans compter).
  - Tant que l'énigme est ouverte, le Sphinx ne subit que 10 % des dégâts.
  - **Bonne réponse** : exposé, +50 % de dégâts subis pendant 20 s.
  - **Mauvaise réponse**, ou pas de réponse en 40 s : il regagne 10 % de PV et ses rayons frappent 30 % plus fort pendant 20 s.
  - Cinq énigmes : le temps, une Porte runique, le Porteur qui brisa le monde, le désert, un miroir.
  - L'IA connaît le lore et vise la bonne réponse.
- **Phases :**
  - P1 : rayons réfléchis (couloirs annoncés en or) et scarabées ;
  - P2 : énigme, mirages (un vrai portail devient un mirage pendant 8 s : `mirage_gates`) et Spectres ;
  - P3 : énigme, cycle jour/nuit ×3 (`fast_cycle`), rayons, Momies, mirages.
- **Couronne de l'Énigme** : résoudre les deux énigmes d'un même combat donne cet objet unique de tête (Esprit +8, Destin +5, Lumière), en légendaire, une seule fois. Il apparaît dans le butin de fin de combat (`riddle_reward` du niveau, `bonus_unique` de la simulation, paramètre `unique` de `Profile.apply_battle`).

**Scarabée-soleil.**
- Capacités :
  - `lane_strike` « fait rouler son soleil » (annonce dorée) ;
  - `force_day` (le plein jour revient pour 18 s) ;
  - bouclier « seul le Givre » ;
  - `row_sweep` « embrase les dunes ».
- `lane_strike` et `row_sweep` acceptent désormais `log` (texte) et `sun` (annonce dorée).

## Décor

- Recoloriage `_desert` : sable doré, grès ocre, éclats turquoise (`WorldArt.zone = 5`).
- Fond `_backdrop_desert` : ciel bleu vers l'or, grand soleil bas, dunes, ruines du Collège, éclats de verre. La nuit, il est teinté de bleu.
- Voiles de sable qui filent avec le vent.
- Carte : ambiance « desert » (lumière dorée, poussière), texte de zone.
- 12 sprites : scarabée, momie, construct, spectre, prêtresse, scorpion, miroir, Scarabée-soleil, Sphinx, caravane. Chacal et Golem de grès reprennent les silhouettes du loup blanc et du golem de glace, recoloriées.

## Récompenses

- Rareté plus haute qu'en zone 4 : 42 % commun, 40 % rare, 18 % épique ; boss : 40 % rare, 60 % épique.
- Matériaux : Verre-soleil (1–3), Sable d'or (0–2).

## Répliques

Le fichier `data/dialogues/fr/z05.json` contient les personnages et les répliques de combat du désert, dont celles de 5-2, 5-4, 5-5, 5-7 et 5-10. Les scènes viendront avec la narration (15.2).

## Équilibrage (IA au niveau du lieu, Mage, Brann et Sylwen, 3 parties)

| Niveau | Victoires | Durée | Barrière |
|---|---|---|---|
| 5-1 | 3/3 | 101 s | 92 % |
| 5-2 | 3/3 | 72 s | 91 % |
| 5-3 | 3/3 | 103 s | 99 % |
| 5-4 | 3/3 | 87 s | 90 % |
| 5-5 | 2/3 | 230 s | 34 % |
| 5-6 | 3/3 | 113 s | 97 % |
| 5-7 | 3/3 | 228 s | 66 % |
| 5-8 | 3/3 | 180 s | 97 % |
| 5-9 | 3/3 | 185 s | 85 % |
| 5-10 | 2/3 | 310 s | 48 % |

Avec d'autres classes :

| Niveau | Classe | Victoires | Durée |
|---|---|---|---|
| Scarabée-soleil (5-5) | Berserker | 2/2 | 227 s |
| Sphinx (5-10) | Chevalier | 1/2 | 431 s |
| Sphinx (5-10) | Nécromancien | 1/2 | 321 s |

Comme le Colosse, le Sphinx est un vrai mur pour les classes lentes.

Réglages en cours de route :
- les Spectres sautaient jusqu'à la Barrière : saut de 1,4 → 1,1 m, seulement au-delà de 7,5 m et hors combat ;
- vagues de 5-7 à 5-9 réduites (5-9 : 27/7 → 18/4 ; à ce niveau, les ennemis grandissent plus vite que l'équipement) ;
- miroir de 5-8 déplacé hors de la colonne centrale ;
- caravane : 7 000 PV, but à 12,4 m, vagues plus légères ;
- Sphinx : 26 000 PV ; mirages de 8 s toutes les 24 s.

`tools/ui_smoke.gd` (`_zone5_ok`) contrôle :
- les sprites ;
- Feu ×1,25 le jour, Givre ×1,25 la nuit ;
- un mirage sans effet, puis reformé ;
- le renvoi des tirs par un miroir, et son rayon de jour (aucun la nuit) ;
- trois énigmes (juste, fausse, juste) : Sphinx protégé, compagnons ignorés, exposé, renforcé, Couronne ;
- la Couronne donnée une seule fois.
