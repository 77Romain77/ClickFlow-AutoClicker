# Historique des versions

## 1.3.0 - 2026-11-19

- Nouvel onglet Test CPS manuel : durées 2, 5, 10, 30 et 60 secondes.
- CPS actuels, moyens, pic sur une seconde, total de clics et barre de progression.
- Courbe CPS en direct et animation discrète au point de clic.
- Affichage du dernier résultat terminé uniquement, sans historique ni sauvegarde des scores.
- Tests automatisés JavaScript du chronométrage, des clics et du dernier résultat.

## 1.2.0 - 2026-11-19

- Un fichier INI indépendant par profil enregistré dans `%APPDATA%\ClickFlow\profiles`.
- Import et export d'un profil individuel, y compris depuis la liste des profils.
- Migration automatique des profils existants depuis `settings.ini`, sans perte des réglages globaux et des copies de sécurité.
- Gestion des noms déjà utilisés lors de l'import et validation du format des fichiers.
- Tests Windows de la migration, de l'import, de la sauvegarde isolée et du rechargement.

## 1.1.0 - 2026-11-19

- Boutons dans "À propos" pour ouvrir les dossiers locaux de ClickFlow et des profils personnels.
- Deux modes de désinstallation : supprimer le programme en conservant les profils, ou effacer aussi les profils et leurs sauvegardes.
- Confirmation de la désinstallation et saisie de SUPPRIMER pour l'effacement complet.
- Désinstallateur AutoHotkey temporaire qui attend la fermeture propre de la fenêtre avant de supprimer les fichiers.
- Suppression limitée aux dossiers et raccourcis appartenant à ClickFlow ; aucun exécutable supplémentaire.

## 1.0.2 - 2026-11-19

- Gestion indépendante des raccourcis du Bureau et du menu Démarrer dans l'onglet "À propos".
- Présence des raccourcis relue depuis Windows, y compris après une suppression manuelle.
- Suppression de la restauration automatique des raccourcis lors du lancement.
- Compatibilité avec les anciens raccourcis ClickFlow, sans supprimer ceux d'autres programmes.
- Conservation du fichier unique, des profils et de toutes les fonctionnalités v1.0.1.

## 1.0.1 - 2026-11-18

- Une seule instance active : relancer ClickFlow remet la fenêtre existante au premier plan.
- Suppression du conflit WebView2 entre deux instances qui causait une erreur de lecture/écriture mémoire.
- Nettoyage des anciens dossiers `Runtime-X.Y.Z` après démarrage réussi, en conservant la version active.
- Profils, paramètres, raccourcis et données WebView2 toujours préservés.

## 1.0.0 - 2026-11-18

Première version stable de **ClickFlow - AutoCliker** sur AutoHotkey v2 et WebView2.

- Fichier unique `.ahk` avec extraction locale automatique, sans application `.exe`.
- Interface moderne, modes de clics, profils sauvegardés et raccourcis personnalisables.
- Arrêt d'urgence configurable (F12 par défaut) et interface compacte ou étendue.
- Correction de la détection du bouton de souris physiquement maintenu.
- Fermeture propre de la fenêtre Windows.
- Icône personnalisée et raccourcis Bureau / menu Démarrer.
- Nouveau workflow de validation et publication à partir de `main`.
- Ancien projet `.exe` archivé dans `archive/dotnet-wpf`.

## 0.3.0 à 0.3.7 - Prototypes WebView2

Développement progressif de l'interface, du moteur, des tests Windows, du fichier unique et des raccourcis.

## 0.1.0 - Prototype C#/WPF

Première tentative Windows avec Velopack et compilation `.exe`. Conservée comme référence historique ; n'est plus maintenue.
