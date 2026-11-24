# Arcane Surge — Game Design Document (v0.1)

> Étape 1 : mise à plat de la vision. Chaque section sera détaillée dans une étape dédiée.

## 1. Pitch
Jeu mobile de « foule contrôlée » (genre crowd-runner / mob-shooter) en univers de fantasy magique.
Le joueur incarne un lanceur au centre de l'arène, flanqué de 2 compagnons (gauche/droite). Il projette
des vagues d'**invocations** qui traversent des **portails runiques** (multiplicateurs, altérations
élémentaires) pour submerger les ennemis et détruire leur **Nexus**. Progression RPG profonde
autour : classes, races, équipement, runes, arbres de compétences, histoire à choix.

## 2. Boucle de jeu
| Échelle | Boucle |
|---|---|
| Micro (secondes) | Viser → lancer le flux d'invocations → passer les portails → déclencher sorts actifs |
| Méso (1 partie, 2–4 min) | Vagues ennemies → mini-boss → destruction du Nexus / boss |
| Macro (sessions) | Loot + XP → salles (Forge, Labo…) → points de compétence → niveau suivant / choix narratif |

## 3. Combat (cœur)
> Détail complet : [`design/03-combat.md`](design/03-combat.md)

- **Lanceur central** (contrôlé) : tire le flux principal, vise latéralement.
- **2 bots** (gauche/droite) : IA autonome, personnalisables (classe, race, sorts, équipement). Option solo.
- **Portails runiques** : ×2, +N, conversion élémentaire (feu/givre/foudre/ombre/lumière), bouclier, soin.
- **Sorts actifs** : 3–4 emplacements, choisis avant la partie ; 1 choix « Surge » en cours de partie
  (sélection 1 parmi 3 à certains paliers, façon roguelite).
- **Jauge Arcane Surge** : se remplit en tuant → ultime de classe.

## 4. Classes (7)
> Détail : [`design/04-classes-races.md`](design/04-classes-races.md)

| Classe | Rôle | Invocations | Spécificité |
|---|---|---|---|
| Archer | DPS distance | Archers spectraux | Perce, tire à travers les portails |
| Épéiste | DPS mêlée | Lames dansantes | Vitesse, critiques |
| Mage | AoE | Élémentaires | Combo d'éléments |
| Clerc | Soutien | Gardiens de lumière | Soin, bouclier des unités |
| Nécromancien | Invocateur | Squelettes | Relève les ennemis tués |
| Chevalier | Tank | Fantassins | Unités lourdes, résistantes |
| Berserker | Burst | Furies | Plus fort quand l'équipe faiblit |

## 5. Races (bonus intrinsèques)
Elfe (précision/vitesse), Orc (PV/force), Nain (armure/forge −coût), Humain (XP+, polyvalent),
Fée (mana/régén), Draconique (dégâts élémentaires/feu), Reptilien (poison/régénération).
Combinaison Classe × Race = identité du personnage.

## 6. Progression
- **Niveau perso** → points de compétence → **arbre par classe** (3 branches) + **arbre racial** (petit).
- **Capacités** : chacune a un niveau (1→10) et des évolutions.
- **Rareté loot** : Commun → Rare → Épique → Légendaire → Mythique → Arcanique.
- Difficulté et rareté corrélées à la zone.

## 7. Hub (avant/après partie)
> Détail salles, équipement, runes, craft, loot : [`design/05-equipement-craft.md`](design/05-equipement-craft.md)

### Équipement
| Salle | Fonction |
|---|---|
| Forge | Armes et armures physiques : création, amélioration |
| Laboratoire | Potions, élixirs, bonus temporaires de partie |
| Atelier runique | Gravure de runes sur armes, boucliers, armures, médaillons, anneaux, charmes |
| Sanctum arcanique | Bâtons, grimoires, focalisateurs magiques |
| Ménagerie | Familiers / montures à bonus passifs |

### Capacités
| Salle | Fonction |
|---|---|
| Salle d'entraînement | Tester capacités, petit gain d'XP |
| Salle de rituel | Capacités sombres (nécromancie, sang, ombre) — coût/risque |
| Salle de méditation | Capacités stables (soins, boucliers, buffs) |
| Bibliothèque | Débloquer/apprendre de nouveaux sorts (parchemins) |
| Observatoire | Capacités célestes / Surge, liées au lore |

### Personnalisation
Apparence, couleurs, tenue, effets visuels des sorts ; même chose pour les 2 bots.

## 8. Création libre (crafting)
- Armes : base + matériau + modificateurs.
- Sorts : **élément + forme** (projectile, zone, chaîne, aura) **+ modificateur** (nombre, durée, taille).
- Runes : emplacements selon rareté de l'objet ; combinaisons de runes = « mots runiques » à effet spécial.

## 9. Monde
> Détail zones, bestiaire, boss, DA : [`design/06-monde.md`](design/06-monde.md)

~10 niveaux par zone, boss en fin de zone, mini-boss en milieu.

| # | Zone | Niveaux | Ambiance |
|---|---|---|---|
| 1 | Bois des Lucioles | 1–10 | Forêt mignonne, lumineuse |
| 2 | Collines d'Ambre | 10–20 | Champs, villages |
| 3 | Marais Murmurants | 20–30 | Brume, poison |
| 4 | Pics Gelés | 30–40 | Glace, nains |
| 5 | Désert de Verre | 40–50 | Soleil, ruines |
| 6 | Forêt Cendrée | 50–60 | Feu, dragons |
| 7 | Cité Engloutie | 60–70 | Abysses, reptiliens |
| 8 | Terres Brisées | 70–80 | Chaos arcanique |
| 9 | Royaume d'Ombre | 80–90 | Sombre, morts-vivants |
| 10 | Cœur du Surge | 90–100 | Final, cosmique |

## 10. Ennemis (catégories)
Bêtes, Morts-vivants, Démons, Élémentaires, Créatures arcaniques, Humanoïdes (bandits, cultistes),
Dragons, Boss. Chaque catégorie a faiblesses/résistances élémentaires → stratégie de choix de sorts.

## 11. Narration
> Canon : [`design/00-lore.md`](design/00-lore.md) · Choix, fins, compagnons, saison 2 : [`design/07-narration.md`](design/07-narration.md)

- Lore principal : l'**Arcane Surge**, déferlement de magie brute qui fracture le monde.
- Dialogues entre niveaux, PNJ dans le hub.
- **Choix à conséquences** (effet papillon) : modifient niveaux, alliés, boss, fins.
- **« Changer le futur »** : retour à un point de choix en conservant la progression du personnage,
  avec avertissement narratif. Le monde se réécrit à partir de ce point.

## 12. Plateformes & formats
iOS (iPhone 16 Pro Max, iPad), Android, PC (16:9, 16:10).
**Orientation au choix du joueur** (réglage + détection) :
- **Portrait** : arène verticale, HUD compact (sorts en bas, jauge Surge en haut).
- **Paysage** : arène élargie + panneaux latéraux (stats des bots, file de sorts, journal de combat, minimap).
- Même logique de jeu ; seule la caméra et le layout UI changent (UI responsive par conteneurs Godot).

## 13. Décisions techniques (validées)
| Sujet | Choix |
|---|---|
| Moteur | **Godot 4** (GDScript) |
| Plateforme initiale | **Web-app** (export Godot web mono-thread) hébergée depuis le repo GitHub (GitHub Pages). Stores iOS / Google Play plus tard |
| Style visuel | **2.5D isométrique pixel-art** haute densité, éclairage atmosphérique (brume, lueurs magiques, lune). Réf. : `docs/art/style-reference-01.jpg` |
| Performance | **60 fps cible, 40 fps plancher** stable ; pooling d'unités, batching, particules GPU |
| Animations | Pixel-art fluide : sprites 8–12 frames + interpolation/tweens, VFX shaders (glow, distorsion) |
| Économie | Gratuit au lancement → plus tard F2P **cosmétiques uniquement**. **Zéro pub forcée** ; pubs récompensées **optionnelles** (bonus loot/XP, relance) |
| Sauvegarde | Compte + sauvegarde cloud **Supabase**, mode hors-ligne avec synchro différée |
| Backend | Projet Supabase partagé `academie-cmd-powershell` (même login que les apps Académie) ; table `public.profiles` réutilisée, tables du jeu préfixées `arcane_` avec RLS |

### Direction artistique (d'après la référence)
- Palette nuit : violets, bleus profonds, verts mousse ; accents cyan/violet pour la magie, ambre pour les torches.
- Décors : ruines envahies de végétation, brume en couches, profondeur par parallaxe.
- Contraste lisibilité : unités et projectiles plus saturés que le décor.
- Chaque zone décline sa propre palette (zone 1 lumineuse/douce → zones finales sombres/saturées en violet-noir).

## 13 bis. Durée & profil (validés)
| Sujet | Choix |
|---|---|
| Durée de partie | Indicative : **2–4 min** standard, **5–6 min** boss de zone, **10 min et plus** boss extrêmes. **Aucune limite, aucune défaite liée au temps** |
| Profil joueur | **Pseudo et profil communs** avec les apps Académie (`public.profiles`) ; données de jeu dans tables `arcane_` liées par `user_id` |

## 14. Feuille de route des étapes
1. ✅ Vision (ce document)
2. ✅ Décisions techniques (moteur, style, économie)
3. ✅ Combat détaillé : formules, portails, IA des bots
4. ✅ Classes & races : stats, arbres de compétences (+ bible du lore)
5. ✅ Équipement, runes, crafting, rareté
6. ✅ Monde : zones, niveaux, ennemis, boss
7. ✅ Narration : lore, arbre de choix, « Changer le futur »
8. ✅ UI/UX : écrans, formats d'écran — [`design/08-ui-ux.md`](design/08-ui-ux.md), maquettes : `mockups/`
9. ✅ Prototype jouable (combat seul) — [`design/09-prototype.md`](design/09-prototype.md)
10. Itérations :
    - 10.1 ✅ boucle de jeu, compte Académie et sauvegarde, Havre-Aube, carte, équipement et Forge, 10 niveaux de la zone 1 avec boss — [`design/11-boucle-de-jeu.md`](design/11-boucle-de-jeu.md) ; sprites : [`design/10-sprites.md`](design/10-sprites.md)
    - 10.2 ✅ narration de la zone 1 : prologue, 20 dialogues avec portraits, choix et fils du destin, répliques de combat — [`design/12-narration-zone1.md`](design/12-narration-zone1.md)
    - 10.2 bis ✅ 7 sorts en combat (3 nouveaux), Pluie de givre et Racines sur la durée, Boule de feu élargie, animation de chaque sort et pouvoir — [`design/13-sorts.md`](design/13-sorts.md)
    - 10.2 ter ✅ refonte de l'interface (concept UI) : cadres à coins coupés, icônes au trait, une icône par objet et par sort — [`design/14-interface.md`](design/14-interface.md)
    - 10.3 ✅ Entraînement (arbre du Mage), Bibliothèque (deck et sorts à apprendre), Cercle (réglages de Brann et Sylwen) — [`design/15-competences-bibliotheque-cercle.md`](design/15-competences-bibliotheque-cercle.md)
11. Acte 2 :
    - 11.1 ✅ zone 2 jouable, Collines d'Ambre : 10 niveaux (niveaux 11 à 20), bestiaire orc, Varg et Gharok, vent des steppes, pylônes d'ambre, décor de jour — [`design/16-zone2.md`](design/16-zone2.md)
    - 11.2 ✅ narration de l'acte 2 : 20 dialogues, choix du Traité d'Ambre et ✦ Gharok, Krag 3e compagnon (2 compagnons actifs au Cercle) — [`design/17-narration-zone2.md`](design/17-narration-zone2.md)
    - 11.3 ✅ 42 sorts élémentaires en 7 rangs (Novice → Interdit), 6 écoles, Bibliothèque filtrée — [`design/18-rangs-des-sorts.md`](design/18-rangs-des-sorts.md)
    - 11.4 ✅ terrain interactif : sols laissés par les sorts, réactions entre éléments, piliers destructibles, murs, séismes ; école Terre et 13 nouveaux sorts — [`design/19-terrain-interactif.md`](design/19-terrain-interactif.md)
    - 11.5 ✅ préparation avant combat : Deck (7 sorts) ou Tiroir (tous les sorts par école, appui maintenu et glisser) — [`design/20-tiroir-de-sorts.md`](design/20-tiroir-de-sorts.md)
12. Acte 3 :
    - 12.1 ✅ zone 3 jouable, Marais Murmurants : 10 niveaux (21 à 30), morts du marais, brume, mares de poison, Crocodile-liche et Hydre des brumes — [`design/21-zone3.md`](design/21-zone3.md)
    - 12.2 ✅ narration de l'acte 3 : 20 dialogues, Nyx 4ᵉ compagne, choix 3-9 (Corvin) et ✦ 3-10 (Aube ou Cendres), branche « Voie du Surge » — [`design/22-narration-zone3.md`](design/22-narration-zone3.md)
13. Héros, races et classes (rattrapage de l'ébauche, étape 4) :
    - 13.1 ✅ création du personnage et Miroir : race, classe, apparence, portrait et sprite générés — [`design/23-creation-personnage.md`](design/23-creation-personnage.md)
    - 13.2 ✅ races : passifs, Don racial en combat (bouton DON), arbre d'héritage et points d'héritage — [`design/24-races.md`](design/24-races.md)
    - 13.3a ✅ 7 classes jouables : invocation, Champion, Ultime, arme du héros, 2 branches d'arbre et Clés de voûte par classe — [`design/25-classes.md`](design/25-classes.md)
    - 13.3b ✅ Voies du Surge des 6 nouvelles classes : 3ᵉ branche, sort et Clés Aube ou Cendres — [`design/25-classes.md`](design/25-classes.md)
    - 13.3c ✅ animations propres à chaque sort (84 signatures : projectiles, impacts, zones, glyphes) — [`design/26-animations-des-sorts.md`](design/26-animations-des-sorts.md)
    - 13.5 ✅ grimoires de classe : ~60 techniques par classe, de Novice à Interdit, en 8 disciplines — [`design/29-grimoires-de-classe.md`](design/29-grimoires-de-classe.md)
        - ✅ Archer : 60 techniques (Tir, Volées, Pièges, Traque, Bêtes, Poisons, Éléments, Astral), renforts, pièges, bêtes, animations par recettes
        - ✅ Épéiste : 60 techniques (Taille, Estoc, Danse, Garde, Spectres, Tempête, Saignée, Acier), saignement, riposte et vol de vie en renfort, lames spectrales
        - ✅ Clerc : 60 techniques (Soins, Châtiment, Bénédictions, Sanctuaires, Purification, Anges, Rayons, Égides), soins de Barrière sur la durée, zones qui soignent les invocations, anges
        - ✅ Nécromancien : 60 techniques (Os, Morts-vivants, Maléfices, Fléaux, Âmes, Ténèbres, Sang, Nécropole), affaiblissement, cimetières, morts relevés, sacrifices qui soignent
        - ✅ Chevalier : 60 techniques (Boucliers, Charges, Étendards, Forteresse, Ordre, Justice, Défi, Serments), étendards qui renforcent les invocations, murs, provocations, l'Ordre
        - ✅ Berserker : 60 techniques (Haches, Fureur, Assauts, Cris de guerre, Totems, Carnage, Clan, Séismes), totems qui accélèrent les invocations, séismes, le clan
    - 13.6 ✅ Options (clé à molette de Havre-Aube) : Deck ou Tiroir ; écoles élémentaires pour toutes les voies ou réservées au Mage ; 6 difficultés, de Facile à Impossible (vitesse et dégâts ennemis, PV du Nexus, XP et butin) — [`design/30-options.md`](design/30-options.md)
    - 13.7 ✅ ambiance des menus (option « Enrichie », par défaut) : rayons et brume en shader, particules par salle, illustration qui respire, panneaux en relief, titres dorés ; Havre-Aube à l'heure réelle, icônes à halo, faisceaux de rareté sur le butin, carte animée (ambiance par zone, chemins, brume) ; éclat au toucher en option ; même mise en page — [`design/31-ambiance.md`](design/31-ambiance.md)
    - 13.4 ✅ Salle de méditation (Sœur Aelis : voies du héros et des compagnons, 3 configurations, réinitialisation, Harmonie) ; compagnons avec niveau et XP propres, équipement et classe changeable — [`design/27-meditation-compagnons.md`](design/27-meditation-compagnons.md)
14. Acte 4 :
    - 14.1 ✅ zone 4 jouable, Pics Gelés : 10 niveaux (31 à 40), bêtes des montagnes et élémentaires de givre, glace qui fait glisser, avalanches, Portes naines FORGE, Sentinelle runique et Colosse runique (runes corporelles) — [`design/28-zone4.md`](design/28-zone4.md)
    - 14.2 ✅ narration de l'acte 4 : 20 dialogues, Durgan, Ysolde et le spectre du Thane Orrin, la vérité sur le scellement de la forteresse Forgecœur ; feu de camp, choix 4-9 (Portes : [Nain] ou [Brann · loyauté 60], sinon option verrouillée) et ✦ 4-10 (reprogrammer le Colosse ou forger l'Enclume-Cœur) ; honneur du clan et titre de Brann ; effets en combat sur la zone 4 — [`design/32-narration-zone4.md`](design/32-narration-zone4.md)
15. Acte 5 :
    - 15.1 ✅ zone 5 jouable, Désert de Verre : 10 niveaux (41 à 50), cycle soleil/lune (Feu ou Givre +25 %), mirages, miroirs qui renvoient les tirs, Scarabée-soleil et Sphinx de verre (énigmes du lore, Couronne de l'Énigme) — [`design/33-zone5.md`](design/33-zone5.md)
    - 15.2 ✅ narration de l'acte 5 : 20 dialogues, Thalren et le Sphinx de verre, le Journal de « M. », Liriel, le reflet qui sourit ; choix 5-7 (les élèves), 5-9 (lire ou brûler le Journal : Fragment de Morvaen ou bouclier de Thalren) et ✦ 5-10 (révéler son Sceau ou mentir) — [`design/34-narration-zone5.md`](design/34-narration-zone5.md)
16. Saison 2 : zones 11–15, niveau max 150, L'Ourdisseur (fils semés en saison 1)
