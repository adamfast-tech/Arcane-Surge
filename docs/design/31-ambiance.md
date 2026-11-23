# Ambiance des menus (étape 13.7)

> Code :
> - `scripts/ui/ambience.gd` ;
> - `shaders/ui_ambience.gdshader`, `ui_vignette.gdshader`, `ui_title_shine.gdshader` ;
> - `RuneBox.rich` ;
> - `UiTheme.backdrop` (paramètre `mood`), `UiTheme.title`, `UiTheme.section` ;
> - `Profile.ambience_on`.

Les menus gardent la même mise en page : mêmes écrans, mêmes boutons, mêmes textes. L'option **Ambiance des menus : Enrichie** (Options, clé à molette) leur ajoute de la vie. Le combat ne change pas.

## Ce qui change

| Élément | Effet |
|---|---|
| Illustration de fond | Elle « respire » : zoom de 4 à 7 % et dérive de quelques pixels, très lents. |
| Lumière (shader) | Des rayons partent d'une source hors champ, en haut, et ondulent ; ils éclairent l'illustration et s'éteignent avant les panneaux. Une brume lumineuse dérive au pied de l'illustration. |
| Particules | Elles dépendent de la salle et flottent surtout dans l'illustration. |
| Vignette | Les bords s'assombrissent pour recentrer le regard. |
| Panneaux (`RuneBox`) | Fond en dégradé (éclairé d'en haut), reflet sous l'arête, double liseré, rivets aux biseaux. Le bouton principal (Continuer) a un halo doré. |
| Titres | Halo, contour sombre, et un reflet doré qui traverse lentement le texte (shader). |
| Sections | Un losange devant, un filet qui s'efface derrière. |
| Écrans | Chaque écran apparaît en fondu (0,25 s). |

## Ambiances par salle

| Salle | Ambiance | Particules |
|---|---|---|
| Havre-Aube, Options | Aube (sarcelle et or) | Lucioles qui clignotent |
| Bibliothèque | Arcane (violet, lueur de bougie) | Poussière arcanique |
| Salle de méditation, Création | Lune (argent et violet) | Éclats de lune |
| Équipement | Forge (orange) | Braises qui montent |
| Le Cercle | Feu de camp | Braises |
| Carte, Préparation | Brume (sarcelle) | Lucioles |
| Entraînement | Or | Poussière dorée |

## Coût

- Un shader plein écran léger (bruit à 4 octaves), un second pour la vignette, et 26 à 90 particules sur le processeur selon la taille de l'écran.
- L'option **Sobre** rend les menus d'origine, pour les vieux téléphones.

## Aperçu

Ajouter `&fx=1` à l'adresse (par exemple `?room=hub&fx=1`) active l'ambiance sans toucher à la sauvegarde.
