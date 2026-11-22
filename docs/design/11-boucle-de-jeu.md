# Étape 10.1 — Boucle de jeu, progression et zone 1 complète

> Suite de [`09-prototype.md`](09-prototype.md). Étapes suivantes : 10.2 (narration de la zone 1, [`12-narration-zone1.md`](12-narration-zone1.md)), 10.3 (compétences, Bibliothèque, Cercle).

## 1. Parcours du joueur

```
Connexion (compte Académie) ─┐
Jouer sans compte ───────────┴─> Havre-Aube ─┬─> Carte (zone 1, 10 niveaux) ─> Combat ─> Récompenses ─┐
                                             └─> Équipement & Forge                                    │
                                 <──────────────────────────────────────────────────────────────────────┘
```

| Écran | Contenu |
|---|---|
| **Connexion** | Pseudo (ou e-mail) et mot de passe du compte Académie, ou « Jouer sans compte » (sauvegarde sur l'appareil) |
| **Havre-Aube** | Profil (pseudo, niveau, XP, or, poussière), état du compte, bouton « Continuer », accès à la carte et à l'équipement. Salles à venir : Bibliothèque, Entraînement, Cercle, Observatoire |
| **Carte** | Les 10 niveaux de la zone 1 : étoiles, record, verrouillage (un niveau s'ouvre quand le précédent est gagné), puissance recommandée, mode solo |
| **Équipement & Forge** | 5 stats et puissance ; 10 emplacements ; inventaire avec Équiper, Améliorer (or, jusqu'au maximum de la rareté) et Recycler (contre de la poussière) |
| **Récompenses** | XP (et niveaux gagnés), or, matériaux, objets. Rejouer, Carte ou Havre-Aube |

## 2. Progression

| Élément | Règle |
|---|---|
| Niveau | XP nécessaire = 100 × niveau^1,6 ; +1 point de compétence par niveau (utilisé à l'étape 10.3) |
| Stats | Base de la classe + progression par niveau + race + équipement (étape 4) |
| XP et or d'une victoire | (30 + 15 × niveau du lieu) XP et (20 + 10 × niveau) or, +10 % par étoile, ×2 à la 1re victoire |
| Défaite | 30 % de l'XP, pas d'or ni de butin |
| Butin | 1 coffre par étoile (Commun 70 %, Rare 25 %, Épique 5 %). Boss : le 1er coffre est Rare ou Épique. **Bâton de la Première Sève** (légendaire, élément Nature) : si la Sylvarche est abattue (choix de 1-10, étape 10.2) |
| Objets | Base de la zone × (1 + 0,12 × (iLvl − 1)) × rareté, + affixes aléatoires selon la rareté. Amélioration +4 % par niveau |
| Matériaux | Bois-lune, Luciole séchée (pour la fabrication à venir) |
| Groupe | 1-1 en solo · Sylwen rejoint en 1-2 · Brann en 1-3. Les bots ont le niveau du joueur − 1 |
| Élément des familiers | Celui de l'arme équipée (étape 5) |

## 3. Les 10 niveaux de la zone 1

| Niveau | Type | Nouveauté |
|---|---|---|
| 1-1 Premières lueurs | Assaut (solo) | Flux, portails `+5` et `×2` |
| 1-2 Le Sentier des Lucioles | Assaut | **Lucioles** : traverser une luciole rend du mana · Sylwen |
| 1-3 La Clairière brisée | Assaut | Coureurs, portail de Feu, tours · Brann |
| 1-4 Les Ronces | Assaut | Portails négatifs, Purifier, ordres |
| 1-5 **Le Grand Cerf** | Mini-boss | **Charges** annoncées par des couloirs rouges, appel de la harde |
| 1-6 Écho des Fées | Assaut | Tireurs et porte-boucliers, Échos |
| 1-7 Le Pont des Ruines | **Escorte** | La Lanterne de l'Aube avance vers le Nexus ; les ennemis convergent vers elle et des embuscades surgissent sur les flancs. Lanterne éteinte = défaite |
| 1-8 La Source flétrie | Purification | Sceaux, unités de Lumière, Dryades |
| 1-9 Le Cœur de la Forêt | **Siège** | Deux Nexus et une tour à détruire |
| 1-10 **La Sylvarche** | Boss | 3 phases : balayages de racines, **écorce** (seul le Feu blesse), Fleurs-sèves qui la soignent, invocations |

**Règles des boss**
- Un familier qui touche le boss frappe une fois, puis se dissipe, comme sur un Nexus. Champions et élites restent au corps à corps.
- Le boss émet une onde toutes les 2,5 s.
- Ses attaques sont annoncées par des zones rouges hachurées.
- Les dégâts sur la durée (brûlure, poison) sont plafonnés, pour qu'un boss ne fonde pas.

### Calibrage (IA, personnage du niveau du lieu, équipement typique)
| Niveau | Durée IA | Barrière | Remarque |
|---|---|---|---|
| 1-1 | 59 s | 98 % | Tutoriel |
| 1-2 | 77 s | 99 % | |
| 1-3 | 93 s | 96 % | |
| 1-4 | 86 s | 97 % | |
| 1-5 | 125 s | 50 % | Mini-boss |
| 1-6 | 110 s | 96 % | |
| 1-7 | 125 s | 93 % | Lanterne à 70–95 % |
| 1-8 | 125 s | 100 % | |
| 1-9 | 140 s | 100 % | |
| 1-10 | 220 s | 57 % | Boss (un humain mettra 4 à 5 min) |

## 4. Compte et sauvegarde en ligne

**Projet Supabase partagé avec les apps Académie** (`academie-cmd-powershell`), donc mêmes identifiants.

**Connexion, identique aux apps Académie**
1. `rpc/resolve_login(pseudo ou e-mail, mot de passe)` renvoie l'e-mail.
2. Une session est ouverte avec cet e-mail et le mot de passe (`auth/v1/token`).
3. Le pseudo est lu dans `profiles.username`.

**Table `public.arcane_saves`**
- Colonnes : `user_id`, `data` jsonb, `version`, `updated_at`.
- **RLS** : chaque joueur ne lit et n'écrit que sa propre ligne. Aucun accès anonyme.

**Synchronisation**
- **Locale** : une sauvegarde est toujours écrite sur l'appareil.
- **En ligne** : connecté, la version **la plus avancée** (XP cumulée) l'emporte au démarrage et à la connexion. La plus récente ne l'emporte qu'à progression égale : une partie neuve ne peut plus écraser une progression. L'autre version est gardée en copie de secours sur l'appareil (`user://save_backup_appareil.json` / `_compte.json`). La progression est envoyée après chaque partie et chaque action de Forge.
- **Session** : elle est mémorisée sur l'appareil, sous la forme d'un jeton de rafraîchissement.
- **Clé du client** : clé publique « publishable ». La sécurité repose sur RLS.
- **Saisie (version web)** : de vrais champs HTML sont posés sur les champs du jeu (`scripts/core/web_form.gd`).
  - Ils permettent le collage, le trousseau iCloud et les gestionnaires de mots de passe (`autocomplete` « username » et « current-password »).
  - Le formulaire est soumis vers une iframe muette, sans requête réseau : le navigateur peut proposer d'enregistrer le mot de passe. Le seul envoi reste celui vers Supabase.

## 5. Outils
- `tools/sim_cli.gd` joue chaque niveau avec un personnage du niveau du lieu et donne la durée, la Barrière et la part restante de l'objectif.
- `tools/ui_smoke.gd` parcourt tout le jeu :
  - les écrans : combat, Échos, victoire, défaite, pause, Havre-Aube, carte, équipement, connexion ;
  - les objectifs : boss, escorte, siège, lucioles.
- Débogage : `?level=<id>&nexus=0.5` démarre un niveau avec l'objectif entamé.
