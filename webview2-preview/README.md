# ClickFlow - AutoClicker Windows v0.3.6

ClickFlow est une application à fenêtre Windows, avec interface WebView2 et moteur AutoHotkey v2. **Aucun exécutable ClickFlow n'est créé.** La branche `main` (C#) et les anciennes versions AutoHotkey ne sont pas modifiées.

## Lancer ClickFlow avec un seul fichier

1. Vérifier qu'**AutoHotkey v2 64 bits** est installé : https://www.autohotkey.com/.
2. Télécharger `ClickFlow-v0.3.6.ahk` depuis la release `v0.3.6-windows-shortcuts`.
3. Fermer les anciennes fenêtres ClickFlow puis double-cliquer sur le fichier téléchargé.
4. Accepter ou refuser la proposition de création des raccourcis sur le **Bureau** et dans le **menu Démarrer**.

Le fichier unique extrait ses composants sous `%LOCALAPPDATA%\ClickFlow\Runtime-0.3.6` puis ouvre la fenêtre Windows, sans navigateur externe. Il installe aussi une copie stable du fichier unique à l'adresse `%LOCALAPPDATA%\ClickFlow\ClickFlow.ahk` et une icône `ClickFlow.ico`. Les raccourcis (si acceptés) pointent vers cette copie stable et peuvent donc continuer à fonctionner après la suppression du fichier téléchargé.

## Une icône ClickFlow

- Une nouvelle icône est utilisée dans les raccourcis, la fenêtre et la zone de notification Windows.
- Sur le bureau, le raccourci `ClickFlow.lnk` présente cette icône. Le fichier `.ahk` lui-même conserve l'icône de son association Windows.
- Le menu Démarrer contient une entrée **ClickFlow** accessible via la recherche Windows.
- Dans **À propos**, les boutons **Créer / actualiser les raccourcis** et **Supprimer les raccourcis** permettent de revenir sur le choix initial.

Aucun programme exécutable ClickFlow n'est installé. Les raccourcis ouvrent le script à l'aide de l'interpréteur AutoHotkey déjà présent sur le PC.

## Mises à jour

Chaque version utilisera un numéro différent. Si une future v0.3.7 est téléchargée et lancée, elle remplacera la copie locale stable `ClickFlow.ahk` et rafraîchira les raccourcis existants. Les composants seront extraits dans un dossier correspondant au nouveau numéro de version.

Cette version **ne vérifie pas les mises à jour automatiquement**.

## Fonctionnalités conservées

- CPS fixes, aléatoires ou naturels, réglages numériques et curseurs.
- Raccourci d'activation libre, modes Maintenir et Basculer.
- Conditionnement à un bouton physique de souris, avec les hooks souris.
- Arrêt au changement de fenêtre, touche d'arrêt d'urgence personnalisable (F12 par défaut).
- Affichage compact ou étendu, choix sauvegardé.
- Profils personnalisés conservés et sauvegardés.

Les profils et réglages continuent d'être enregistrés dans `%APPDATA%\ClickFlow\settings.ini` : créer ou supprimer les raccourcis ne modifie pas ce fichier.

## Alternative en ZIP

`ClickFlow-WebView2-v0.3.6-win-x64.zip` reste disponible. Extraire le ZIP et lancer `ClickFlow-WebView2.ahk` pour utiliser le logiciel sans créer de raccourcis.

## Tests et limites

GitHub Actions vérifie le démarrage du moteur, la communication WebView2, la fermeture de la fenêtre, l'extraction du fichier unique et la création des raccourcis avec leur icône. Les clics physiques et le rendu visuel final doivent toujours être vérifiés sur le PC de l'utilisateur.

Smart App Control peut aussi bloquer un composant inconnu ; ne pas désactiver la sécurité Windows pour tester ClickFlow. Aucun nouveau fichier `.exe` ClickFlow n'est produit.

Bibliothèque WebView2 de thqby sous licence MIT, composant Microsoft WebView2Loader officiel empaqueté dans l'archive de distribution.
