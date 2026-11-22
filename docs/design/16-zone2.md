# Zone 2 · Collines d'Ambre (étape 11.1)

> Suite de [`11-boucle-de-jeu.md`](11-boucle-de-jeu.md) et [`06-monde.md`](06-monde.md). Narration de l'acte 2 : étape 11.2.

## Carte

- La carte a des onglets de zone : **Bois des Lucioles** (1-1 à 1-10) et **Collines d'Ambre** (2-1 à 2-10, niveaux globaux 11 à 20).
- Le niveau 2-1 s'ouvre après la victoire sur 1-10. La tuile Carte du Havre-Aube affiche la zone du prochain niveau.
- `data/levels/index.json` contient `zones` (id, nom, niveaux) et `levels` (liste à plat).

## Niveaux

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 2-1 | La Route d'Ambre | Assaut | Pillards et chevaucheurs de loup |
| 2-2 | Les Moulins | Assaut | Vent des steppes |
| 2-3 | Les Pylônes d'ambre | Assaut | Pylônes |
| 2-4 | Le Gué du Clan | Assaut | Gardes de clan et Ogres, vent |
| 2-5 | Varg, chef pillard | Mini-boss | Charges en ligne, renforts, Cri de guerre |
| 2-6 | Le Campement de l'orage | Assaut | Chamans d'orage, vent et pylône |
| 2-7 | La Caravane | Escorte | Chariot de vivres (1 600 PV), embuscades de loups |
| 2-8 | Le Rebouteux | Purification | 2 sceaux, Rebouteux qui soignent le Nexus |
| 2-9 | Le Traité d'Ambre | Siège | 2 Nexus, tours |
| 2-10 | Gharok | Boss | 3 Bannières de guerre, Totems d'orage, vent et pylône |

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Pillard | sbire | De base, en nombre |
| Chevaucheur de loup | coureur | Rapide, fragile |
| Ogre d'ambre | brute | Lent, très résistant |
| Frondeur | tireur | Attaque à distance |
| Garde de clan | bouclier | Bloque de face |
| Chaman d'orage | lanceur | Foudroie les invocations (toutes les 4,5 s) |
| Rebouteux possédé | soigneur | Soigne le Nexus et les unités |
| Bannière de guerre | bannière | Fixe ; tant qu'une bannière tient, le boss ne subit que 20 % des dégâts |
| Totem d'orage | lanceur | Fixe, foudroie (toutes les 4 s) |
| Chariot de vivres | escorte | À protéger jusqu'au village |
| **Varg** | mini-boss | Charges en ligne, renforts, Cri de guerre |
| **Gharok** | boss | Charges, balayages, renforts ; armure de bannières |

## Mécaniques de zone

- **Vent des steppes.** Calme → annonce (traits d'air, message « Rafale imminente vers la gauche/droite ») → rafale (poussière et herbe, les unités glissent sur le côté). La poussée dépend du poids : les Ogres bougent peu, les boss, bannières et escortes pas du tout. Réglage par niveau : `wind` = `{first, every: [min, max], warn, dur, force}`.
- **Pylônes d'ambre.** Cristaux au bord de la chaussée. Ils s'illuminent pendant 2 s, puis surchargent leur portail : il affiche **FOUDRE ×2** (jaune). Pendant quelques secondes, chaque invocation qui le traverse devient Foudre et se dédouble. Les portails négatifs ne sont pas surchargés. Réglage : `pylons` = `[{x, y, portal, every, dur, first}]`.
- **Cri de guerre** (Varg, Gharok) : les ennemis infligent +30 % de dégâts pendant la durée du cri.
- **Bannières** (Gharok) : à chaque phase, de nouvelles bannières apparaissent. La barre d'objectif affiche « ARMURE : n bannières ».

## Décor

- Plein jour : ciel bleu de midi, soleil, nuages blancs, collines ocre et un fort orc au loin.
- La chaussée et l'herbe sont recolorées en herbe sèche dorée et grès ocre (`WorldArt.zone = 2`, recoloriage `_warm`).
- Sapins vert olive, lumière chaude, brume de poussière, pollen doré à la place des lucioles.
- `WorldArt.zone` est défini par le combat d'après la zone du niveau, puis remis à 1 en sortie.

## Récompenses

- Butin de zone 2 : rareté plus haute.
- Matériaux : Éclat d'ambre (1–3) et Crin de loup (0–2).
- XP d'un combat = 33 % de l'XP du niveau suivant, multiplié par le bonus d'étoiles et ×2 au premier passage. La courbe reste donc la même quelle que soit la zone.

## Équilibrage (IA au niveau du lieu, 3 combats par niveau)

| Niveau | Victoires | Durée moyenne | Barrière restante |
|---|---|---|---|
| 2-1 | 3/3 | 90 s | 100 % |
| 2-2 | 3/3 | 110 s | 97 % |
| 2-3 | 3/3 | 119 s | 100 % |
| 2-4 | 3/3 | 116 s | 100 % |
| 2-5 | 3/3 | 123 s | 47 % |
| 2-6 | 3/3 | 159 s | 87 % |
| 2-7 | voir ci-dessous | 141 s | 100 % |
| 2-8 | 3/3 | 162 s | 92 % |
| 2-9 | 3/3 | 173 s | 87 % |
| 2-10 | 3/3 | 304 s | 46 % |

Le chariot de 2-7 est passé de 1 400 à 1 600 PV après un résultat de 2 victoires sur 3.
