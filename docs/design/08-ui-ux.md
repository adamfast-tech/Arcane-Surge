# Étape 8 — Interface et ergonomie

> Maquettes visuelles (canvas) : https://claude.ai/artifact/PgrFpvQ8gufqyuhiG6DhmF

## 1. Principes
- **Une seule main en portrait** : les actions fréquentes (sorts, Champion, Ultime) sont à portée du pouce, dans le tiers bas de l'écran. Les informations consultées (Nexus, Surge) sont en haut.
- **Zones tactiles d'au moins 44 pt**. Le jeu respecte les zones sûres (encoche, Dynamic Island, barre d'accueil).
- **Lisibilité avant tout** : le décor est désaturé, les unités, portails et sorts sont saturés. Les nombres importants (portails ×N, PV) sont en police pixel, en grand.
- **Typographie** : *Pixelify Sans* pour les titres, les nombres et le HUD ; *Inter* pour les textes longs (dialogues, Codex, infobulles).
- **Couleurs de l'interface** :

| Rôle | Couleur |
|---|---|
| Fond | `#120E22` |
| Panneaux | `#1E1838`, `#2A2150` |
| Bordures | `#4A3D7A` |
| Texte | `#ECE8FF` |
| Texte secondaire | `#A99FD0` |
| Accent or (actions principales) | `#F2C46B` |
| Accent cyan (magie, mana, Surge) | `#4FE3D2` |

- **Raretés** : chaque rareté a une **couleur et une lettre** (C, R, É, L, M, A), pour rester lisible par les daltoniens.

| Rareté | Couleur |
|---|---|
| Commun | `#B8B8C8` |
| Rare | `#5AA9FF` |
| Épique | `#B07CFF` |
| Légendaire | `#F2C46B` |
| Mythique | `#FF6B6B` |
| Arcanique | `#7CFFE1` |

## 2. Navigation

```
Titre → Connexion (compte Académie) → [1re fois] Prologue → Création du personnage
                                                     ↓
                    ┌──────────── HUB : Havre-Aube ────────────┐
   Barre du bas :   Carte · Équipement · Capacités · Cercle · Boutique (plus tard)
                    └──────┬───────────────────────────────────┘
                           ↓
   Carte du monde → Niveau → Préparation → Dialogue d'intro → COMBAT → Résultats → Dialogue de fin → HUB
```

| Onglet | Contenu |
|---|---|
| **Carte** | 10 zones, niveaux, étoiles, Défis, Héroïque, Failles |
| **Équipement** | Mannequin d'équipement et inventaire. Raccourcis vers Forge, Sanctum, Laboratoire, Atelier runique, Ménagerie |
| **Capacités** | Arbres, deck de sorts. Raccourcis vers Entraînement, Rituel, Méditation, Bibliothèque, Observatoire |
| **Cercle** | Compagnons et mercenaires : configuration, loyauté, Veillées, apparence |
| **Boutique** | Cosmétiques uniquement (à venir) |

Le hub s'affiche en **vue citadelle** : une illustration isométrique dont on touche les salles. Une **vue liste** existe aussi, pour l'accessibilité et la rapidité.

## 3. Combat : disposition selon l'écran

| Format | Rapport largeur/hauteur | Disposition |
|---|---|---|
| Téléphone portrait | < 0,65 | HUD compact : Nexus et Surge en haut ; médaillons des bots, mana, Champion, potions, 4 sorts et Ultime en bas |
| Tablette portrait | 0,65–1,0 | Comme le téléphone, plus une colonne latérale fine (Échos actifs) |
| Paysage PC (16:9, 16:10) | 1,0–1,9 | Arène au centre. **Panneau gauche** : bots, ordres, Échos. **Panneau droit** : mini-carte, sorts, journal de combat |
| Téléphone paysage | > 1,9 | Comme le paysage, avec des panneaux compacts et repliables |

- **Orientation** : réglage *Auto / Portrait / Paysage*.
  - Natif : verrouillage par `DisplayServer.screen_set_orientation`.
  - Web : le jeu adapte sa disposition à la taille de la fenêtre.
- **Godot** :
  - Résolutions de base : 1080×1920 en portrait, 1920×1080 en paysage.
  - Mise à l'échelle : `stretch = canvas_items`, `aspect = expand`.
  - Le HUD de combat existe en 2 scènes (portrait et paysage), les autres écrans s'adaptent avec des conteneurs.
  - Zones sûres : `DisplayServer.get_display_safe_area()`.

## 4. Écrans clés (voir les maquettes)
| Écran | Points clés |
|---|---|
| Combat portrait | Barre de PV du Nexus et jauge Surge en haut · ligne de Barrière visible · 3 lanceurs · sorts avec coût et recharge visibles · ordre donné au bot affiché sous son médaillon |
| Combat paysage | Cartes des bots avec boutons d'ordre directs · journal de combat · mini-carte · Échos actifs |
| Hub | Vue citadelle, salles verrouillées avec l'acte qui les débloque · bouton principal « Continuer » · Veillée disponible |
| Préparation | Puissance recommandée comparée à la tienne · aperçu des ennemis (Soigneurs signalés) · le Cercle sur 3 positions · deck de 4 sorts + Don racial · 3 potions · option solo (+25 % d'XP) |
| Équipement | Changement de personnage (toi ou un bot) · mannequin à 10 emplacements · stats · fiche d'objet (rareté, iLvl, +N, élément, affixes, runes, histoire, comparaison) · inventaire filtrable |
| Arbre | Onglets des 3 branches (la 3e verrouillée jusqu'à l'acte 3) · paliers P1 à P5 avec leurs seuils · compteur de Clés de voûte (x/2) · fiche du nœud et bouton « Investir » |
| Fils du destin | Frise des ✦ avec les options inexplorées en « ? » et les lignes abandonnées en grisé · avertissement avec la liste Perdu / Conservé · confirmation en maintenant 2 s |
| Dialogue | Portrait, nom dans la couleur de la faction, bulle · choix ✦ marqués « Fil du destin » · Auto, Historique, Passer |

## 5. Retours visuels et sensoriels
- Nombres flottants : dégâts, `+N` et `×N` qui apparaissent aux portails.
- Ralenti au moment du choix d'Écho.
- Tremblement d'écran léger (désactivable) et retour haptique sur le natif.
- Annonce des attaques de boss : zone qui pulse, au moins 1,2 s à l'avance.
- Changement de palette quand la Barrière passe sous 25 %.

## 6. Réglages et accessibilité
- Orientation, taille du texte (de 80 à 150 %), mode daltonien (formes et lettres en plus des couleurs).
- Réduction des flashs et du tremblement d'écran, tir automatique du Flux, disposition miroir pour les gauchers.
- Volumes (musique, effets, bips vocaux), langue, vitesse des dialogues, pubs récompensées (activées ou désactivées).
- Raccourcis clavier sur PC (étape 3, §13).
