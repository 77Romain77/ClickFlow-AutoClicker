# ClickFlow - AutoClicker Windows v0.3.5 beta

Le nouveau design WebView2 et le moteur AutoHotkey v2 sont reunis dans une version Windows. La branche `experimental/autohotkey` conserve la version classique 0.2.5, et la branche `main` reste intacte.

## Le fichier unique recommande

1. Installer **AutoHotkey v2 64 bits** une fois, si ce n'est pas deja fait : https://www.autohotkey.com/.
2. Telecharger **`ClickFlow-v0.3.5.ahk`** depuis la release v0.3.5-webview2-beta.
3. Fermer les anciennes fenetres ClickFlow, puis double-cliquer sur le fichier `.ahk`.
4. Le premier lancement extrait automatiquement les composants integres dans `%LOCALAPPDATA%\ClickFlow\Runtime-0.3.5`, puis ouvre ClickFlow dans sa propre fenetre Windows. Les lancements suivants reutilisent ces fichiers locaux.

Le fichier unique est **un script AutoHotkey**, pas un executable signe. Il ne demande pas de compilation, ne telecharge aucun composant au lancement et ne desactive aucune protection Windows. Le runtime WebView2 de Microsoft doit etre present (normalement inclus avec Windows 11).

**Alternative :** telecharger `ClickFlow-WebView2-v0.3.5-win-x64.zip`, extraire le dossier et lancer `ClickFlow-WebView2.ahk` comme dans la version precedente.

## Les nouveautes v0.3.5

- **Raccourci d'arret d'urgence configurable** : touche F12 par defaut, modifiable depuis le bouton d'arret d'urgence de l'interface, y compris une touche souris compatible.
- Cette touche est **globale pour tous les profils** et sauvegardee. Le logiciel refuse une touche deja utilisee pour l'activation d'un profil.
- **Mode compact / mode etendu** : bouton en haut de la fenetre, affichage reduit avec les commandes essentielles (profil, CPS, activation, touche d'urgence, statut et arret). Revenir au mode etendu pour les autres options.
- Le mode choisi et la touche d'urgence sont sauvegardes dans `[General]` dans `%APPDATA%\ClickFlow\settings.ini`.
- Les profils, boutons, CPS, modes Hold/Toggle et condition de bouton souris sont conserves comme avant.

## Test conseille

1. Choisir Fixe et 5 CPS dans une application de test sans action sensible.
2. Tester le raccourci d'activation, puis F12 pour arreter.
3. Definir une autre touche d'arret d'urgence, l'essayer, fermer et rouvrir ClickFlow pour verifier qu'elle reste enregistree.
4. Basculer en mode compact puis etendu, fermer et rouvrir afin de verifier que le mode d'affichage est memorise.
5. Verifier que les profils existants apparaissent et que l'option de maintien d'un bouton souris fonctionne toujours.

**Attention :** le test automatique Windows verifie le demarrage WebView2, l'echange de donnees avec AutoHotkey, la sauvegarde des parametres, la taille des fenetres et la fermeture avec la croix. Les raccourcis et clics physiques doivent etre verifies sur ton PC.

## Sauvegarde et fonctionnement

- Configuration : `%APPDATA%\ClickFlow\settings.ini`.
- Sauvegarde creee a la premiere utilisation de WebView2 : `settings.ini.backup-webview2`, si elle n'existe pas.
- Cache des composants du fichier unique : `%LOCALAPPDATA%\ClickFlow\Runtime-0.3.5`.
- Les versions dans un ZIP restent disponibles si l'extraction automatique est bloquee.
- Aucune promesse de compatibilite avec les jeux interdisant les clics automatises.

## Code et licences

- `ClickFlow-Backend.ahk` : moteur et sauvegarde.
- `ClickFlow-WebView2.ahk` : fenetre Windows.
- `ui/index.html` : interface graphique.
- `tools/build_single_ahk.py` : fabrication du fichier unique a partir du code source.
- Bibliotheque WebView2 AHK par thqby sous licence MIT et chargeur WebView2 officiel Microsoft, inclus dans les archives.
