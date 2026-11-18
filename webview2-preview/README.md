# ClickFlow - AutoClicker Windows v0.3.4 beta

Version expérimentale avec interface WebView2 et moteur AutoHotkey v2 fonctionnel. La branche `experimental/autohotkey` conserve la version classique 0.2.5. La branche `main` (C#) n'est pas modifiée.

## Lancement

1. Installer AutoHotkey v2 **64 bits** depuis https://www.autohotkey.com/ si ce n'est pas déjà fait.
2. Télécharger `ClickFlow-WebView2-v0.3.4-win-x64.zip` depuis la release GitHub.
3. Extraire tout le ZIP dans un nouveau dossier, distinct des anciennes versions.
4. Fermer les anciennes fenêtres ClickFlow.
5. Double-cliquer sur **`ClickFlow-WebView2.ahk`**.

Ne pas utiliser `Ouvrir-interface.ahk` : ce fichier lance uniquement la maquette dans un navigateur et n'envoie aucun clic.

## Test recommandé

1. Choisir **Fixe**, **5 CPS**, **Clic gauche**, **Maintenir**, touche **F6**.
2. Ouvrir une application de test sans action sensible, et y placer le curseur.
3. Maintenir F6 pour déclencher les clics, relâcher F6 pour arrêter.
4. Tester Basculer (Toggle), puis les modes Aléatoire et Naturel.
5. Vérifier l'arrêt en passant sur une autre fenêtre.
6. Utiliser **F12** à tout moment pour arrêter les clics.

Les clics manuels restent possibles et s'ajoutent aux clics générés.

## Fonctionnalités

- CPS de 1 à 100 avec sliders et saisie numérique.
- Modes Fixe, Aléatoire et Naturel, avec intensité de variation.
- Bouton généré gauche / droit / central.
- Raccourci personnalisable au clavier ou à la souris.
- Activation Maintenir ou Basculer.
- Option de maintien supplémentaire d'un bouton de souris.
- Arrêt au changement de fenêtre, activé par défaut.
- Arrêt d'urgence F12.
- Statistiques des CPS envoyés et du total de clics.
- Profils créables, renommables, duplicables, supprimables et sauvegardés.

Les réglages sont conservés dans **`%APPDATA%\ClickFlow\settings.ini`**, au même format que ClickFlow AutoHotkey 0.2.x. Au premier lancement, si un ancien fichier existe, une copie **`settings.ini.backup-webview2`** est créée, sauf si cette sauvegarde existe déjà.

## Correction v0.3.4 - maintien d'un bouton de souris

La version WebView2 précédente ne réinstallait pas les hooks clavier/souris de l'ancienne interface. Les clics simulés pouvaient modifier l'état logique d'un bouton maintenu, et donner l'impression que l'autoclicker ne faisait que 1 ou 2 clics. Cette version restaure `InstallKeybdHook()`, `InstallMouseHook()` et `SendMode("Input")` avant l'activation du moteur.

**Test conseillé :** sélectionner clic gauche généré, condition `Clic gauche`, mode Basculer et raccourci F6. Activer F6 dans une fenêtre de test, maintenir physiquement le clic gauche pendant 3 secondes, puis le relâcher. Les clics doivent se produire pendant toute la durée du maintien, s'interrompre au relâchement, et reprendre au maintien suivant sans réactiver F6. F12 arrête l'ensemble.

## Correction v0.3.4 - fermeture sans erreur

La fermeture de la fenêtre Windows arrête maintenant les clics, désactive les raccourcis et les timers, sauvegarde les profils, puis libère les objets WebView2. Un test automatique simule le bouton X via le message Windows WM_CLOSE et vérifie que le processus se termine sans erreur. Ce contrôle est distinct du test de démarrage.

## Limitations de la version beta

- WebView2 (runtime Windows) et `WebView2Loader.dll` doivent être autorisés par les protections de Windows. Ne pas désactiver Smart App Control pour ce test.
- Certaines applications, notamment des jeux, peuvent ignorer les clics simulés ou interdire leur usage.
- La fréquence réelle dépend des limites des minuteries de Windows.
- Ce lancement a été testé par GitHub Actions sur Windows, avec confirmation de la communication HTML <-> AutoHotkey. Les interactions avec une souris physique et les jeux doivent encore être vérifiées sur ton PC.
- Le fichier `Ouvrir-interface.ahk` reste une démonstration graphique séparée.

## Structure

- `ClickFlow-WebView2.ahk` : lanceur Windows.
- `ClickFlow-Backend.ahk` : moteur, raccourcis, profils et sauvegarde.
- `ui/index.html` : interface HTML/CSS/JavaScript.
- `lib/` : bibliothèque WebView2 AutoHotkey de thqby, sous licence MIT.
- `lib/WebView2/64bit/WebView2Loader.dll` : chargeur Microsoft fourni par le ZIP GitHub Actions.

Pour signaler un problème, joindre une capture, l'action qui l'a déclenché et le numéro de version.
