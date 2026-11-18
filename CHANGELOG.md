# Historique des versions

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
