# ClickFlow - Prototype WebView2 v0.3.0

Cette branche est un essai d'interface moderne. Le projet AutoHotkey fonctionnel reste intact dans `experimental/autohotkey`. La branche `main` (C#) n'est pas modifiée.

## Pour tester

1. Télécharger **ClickFlow-WebView2-Preview-win-x64.zip** depuis la release de prévisualisation sur GitHub.
2. Extraire **tout** le ZIP dans un dossier (ne pas lancer le script directement dans le ZIP).
3. Vérifier qu'**AutoHotkey v2 64 bits** est installé.
4. Ouvrir le dossier `webview2-preview` et double-cliquer sur `Ouvrir-interface.ahk` pour tester tout de suite le nouveau design dans le navigateur.
5. Pour essayer l'intégration dans une fenêtre Windows WebView2, lancer `ClickFlow-WebView2.ahk`. Cette intégration est encore expérimentale et son démarrage n'est pas validé automatiquement.

Aucune installation de ClickFlow ou compilation n'est nécessaire. Le runtime WebView2 est normalement inclus dans Windows 11. L'archive inclut le composant **WebView2Loader.dll provenant du package officiel Microsoft**. Smart App Control peut toutefois bloquer une DLL ou un script inconnu : ne pas désactiver la protection pour ce test.

## Ce que permet ce prototype

- Vérifier le nouveau design sombre, la taille et le comportement de la fenêtre Windows.
- Manipuler les sliders CPS, les champs numériques et les modes Fixe / Aléatoire / Naturel.
- Tester l'apparence de la capture de touche, des boutons Hold / Toggle et des options.
- Créer, renommer, dupliquer et supprimer des profils **de démonstration en mémoire**.
- Afficher un état actif **simulé**, sans envoyer le moindre clic.
- Tester un message de liaison HTML vers AutoHotkey (onglet À propos).

**Attention : ce prototype ne génère aucun clic, ne lit pas et ne modifie pas les profils réels** (`%APPDATA%\ClickFlow\settings.ini`). Les profils de démonstration ne sont pas sauvegardés. La logique AutoHotkey sera raccordée après la validation visuelle et la vérification de compatibilité sur ton PC.

## En cas de blocage WebView2

- Si Windows affiche une erreur de composant, envoyer la capture exacte.
- Le fichier `ui/index.html` peut aussi être ouvert dans un navigateur : l'interface visuelle reste utilisable pour le test du design, mais le pont AutoHotkey n'est pas actif.
- Notre version AutoHotkey actuelle reste disponible dans la branche `experimental/autohotkey`.

## Fichiers

- `ClickFlow-WebView2.ahk` : lanceur WebView2 expérimental.
- `Ouvrir-interface.ahk` : lanceur simple du prototype visuel dans le navigateur par défaut.
- `ui/index.html` : interface HTML, CSS et JavaScript sans ressources externes.
- `lib/WebView2/WebView2.ahk` : bibliothèque de thqby sous licence MIT.
- `lib/Promise.ahk`, `lib/ComVar.ahk` : dépendances de la même bibliothèque (MIT).
- `lib/WebView2/64bit/WebView2Loader.dll` : DLL officielle Microsoft, injectée dans l'archive par GitHub Actions, non stockée dans le code source.

Les sources de la bibliothèque thqby proviennent de https://github.com/thqby/ahk2_lib . Sa licence MIT est conservée dans `lib/LICENSE-thqby`.
