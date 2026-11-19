# Historique des versions

## 1.9.0 - 2026-11-19

- Raccourcis globaux entièrement facultatifs et sans affectation par défaut : profil suivant/précédent, afficher/masquer l'overlay, ouvrir ClickFlow, accéder au Test CPS. Chaque action possède son bouton "Aucun" ; touche d'arrêt d'urgence conservée.
- Capture clavier intégrée, contrôle des collisions avec les touches d'activation de tous les profils, l'arrêt d'urgence et les autres actions globales. Préférences persistantes dans settings.ini.
- Sauvegarde complète : export de settings.ini et de tous les profils en un ZIP. Validation stricte de la structure et de la taille avant restauration, sauvegarde temporaire et restauration de secours en cas d'échec, rechargement des profils et raccourcis après succès.
- Overlay : trois tailles optionnelles (mini, standard, grande) et possibilité de montrer le nom du profil sous la ligne de statut. La taille mini et le nom caché restent les valeurs par défaut.
- Paramètres réorganisés en six sections repliables : Général, Overlay, Raccourcis globaux, Raccourcis Windows, Sauvegarde complète et Maintenance.
- Tests Windows et JavaScript couvrant les raccourcis facultatifs, les conflits, l'export/import ZIP, les données rejetées, les tailles d'overlay et l'organisation des préférences.

## 1.8.2 - 2026-11-19

- Ajout du réglage "Période CPS moyens" dans Paramètres > Overlay : durée personnalisée de 1 à 60 secondes, valeur par défaut 5 secondes.
- Calcul de la moyenne glissante et nettoyage des clics en mémoire adaptés à la durée sélectionnée, sans modifier le rythme du profil.
- Préférence sauvegardée dans settings.ini et rechargée automatiquement au démarrage.
- Tests AutoHotkey pour 1, 5, 10 et 60 secondes, valeurs invalides et persistance ; contrôle JavaScript du champ et de ses limites.

## 1.8.1 - 2026-11-19

- Correction du texte coupé dans l'overlay sur certains écrans Windows et DPI élevés : statut et CPS moyens tiennent maintenant sur une seule ligne.
- Format volontairement très compact, 216 x 34 pixels physiques, avec une police réduite adaptée à la mise à l'échelle Windows (100, 125, 150 ou 200 %).
- Coins de l'overlay légèrement arrondis (rayon visuel de 6 pixels), en conservant la transparence réglable et les clics traversants.
- Tests Windows supplémentaires de placement réel des champs texte, taille constante avec le DPI et arrondi de la fenêtre.

## 1.8.0 - 2026-11-19

- Remplacement de l'ancienne mini-fenêtre par un overlay AutoHotkey léger, sans courbe, fenêtre de titre ni boutons, affichant le statut et les CPS moyens des 5 dernières secondes.
- Overlay transparent aux clics (Windows), visible pendant l'activité et masqué environ 2 secondes après l'arrêt, avec option d'affichage permanent.
- Six positions prédéfinies : haut gauche/milieu/droite et bas gauche/milieu/droite. Choix de l'écran, marge réglable, déplacement libre à la souris en mode placement temporaire et mémorisation de la position.
- Transparence entièrement personnalisable de 0 à 100 %, au pourcentage près, avec prévisualisation du placement et possibilité de revenir aux positions proposées.
- Démarrage de la fenêtre principale centré et limité à la surface visible de l'écran choisi, même après changement de résolution ou retrait d'un moniteur.
- Migration de la préférence d'activation de l'ancienne mini-fenêtre, sans modification des profils ou des raccourcis. Suppression de l'ancien dessin GDI de la courbe flottante.
- Tests Windows de la transparence, des positions, du déplacement, de la sauvegarde, des CPS moyens et du centrage.

## 1.7.3 - 2026-11-19

- Corrige le crash au lancement "Object has no property named floatChart" : les messages Windows WM_PAINT peuvent arriver avant la création de la mini-fenêtre. Les callbacks ignorent les contrôles non initialisés.
- Optimise le moniteur CPS du tableau de bord (étendu et compact) : aucun échantillonnage ni redessin Canvas lorsqu'aucun clic n'est envoyé. Le graphique s'active aux premiers clics, s'arrête au retour à 0 CPS et conserve le total des clics affiché.
- Des indicateurs "En veille" remplacent les courbes vides. Aucun nouvel enregistrement de données CPS.
- Tests de régression AutoHotkey pour le dessin Windows avant initialisation, et tests JavaScript des phases repos / activité / arrêt / graphique désactivé.

## 1.7.2 - 2026-11-19

- Correction de l'agrandissement involontaire de la mini-fenêtre après fermeture et réouverture : sauvegarde/restauration d'un seul rectangle extérieur, avec migration de la taille enregistrée par les versions précédentes.
- La courbe CPS de la mini-fenêtre réagit maintenant aux clics réellement envoyés par AutoHotkey, rafraîchie pendant l'activité et masquée quand il n'y a aucun clic récent.
- Graphique redessiné directement avec GDI dans la surface disponible, sans mini-bitmap figé : tracé adaptatif même lors des premières secondes et après redimensionnement.
- Les boutons Courbe et STOP sont maintenant des contrôles Windows simples avec fond coloré natif, sans les anciennes barres Progress qui débordaient lors d'un redimensionnement.
- Dimensions indépendantes pour les fenêtres principales Compacte et Étendue, restaurées lors des changements de mode et conservées après fermeture.
- Aides au survol et au focus clavier pour les modes Fixe, Aléatoire et Naturel, dans les deux interfaces.
- Tests Windows renforcés : plusieurs fermetures/réouvertures sans croissance, tracé CPS alimenté par les événements réels du moteur, arrêt du tracé au repos, dimensions et boutons.

## 1.7.1 - 2026-11-19

- Mini-fenêtre réellement compacte : plus de deux grands boutons en bas. Deux petits boutons colorés "CPS" et "STOP" restent visibles en haut, avec double-clic sur le nom pour ouvrir l'interface.
- Correction de la courbe Windows vide : contrôle graphique SS_BITMAP correct (affichage du bitmap vérifié automatiquement), courbe de 30 secondes visible dès une petite taille, activée par défaut sur les nouvelles installations.
- Dimensions par défaut réduites (310 x 150), redimensionnement et sauvegarde de la position/taille conservés ; aucune modification de taille forcée pour les utilisateurs qui ont déjà personnalisé leur mini-fenêtre.
- Nouveau panneau compact WebView2 autonome, en petits blocs avec police plus petite : profil, état, CPS et total côte à côte, STOP, mode, CPS min/max, intensité Naturel, raccourcis et courbe optionnelle.
- Ligne CPS des cartes de profil incluant désormais l'intensité Naturel ; ligne Activation réservée au raccourci.
- Barre de titre Windows native harmonisée au thème sombre avec DWM (si le système prend ces attributs en charge), tout en conservant les boutons Windows et le redimensionnement.
- Tests supplémentaires : association effective du bitmap à son contrôle Windows, apparence des boutons, interactions compactes et régressions AutoHotkey/WebView2.

## 1.7.0 - 2026-11-19

- Mini-fenêtre flottante redimensionnable en tirant les bords ou les coins, avec largeur, hauteur et position restaurées au prochain démarrage.
- Affichage adapté à sa taille : nom du profil sur deux lignes, état/CPS/STOP toujours accessibles, courbe CPS GDI native sur 30 secondes affichée facultativement lorsque la fenêtre est assez grande.
- Bouton "Interface" en remplacement de "Ouvrir" : restaure l'application principale sans démarrer une deuxième instance.
- Options de mini-fenêtre dans Paramètres : courbe, toujours au premier plan et opacité (70/80/90/100 %).
- Menu de la zone de notification simplifié : uniquement les noms de profils choisis par l'utilisateur, sans numéros internes.
- Cartes de profils : flèches haut/bas de dimensions fixes dans un pied de carte distinct, meilleur rendu aux petites largeurs et intitulés accessibles.
- Mode compact entièrement réorganisé en panneau de commande rapide : profil, état/STOP, CPS, mode, min/max, intensité Naturel, raccourcis et moniteur CPS optionnel.
- Historique CPS de la mini-fenêtre seulement en mémoire, sans écriture disque ; compatibilité avec les profils et préférences des versions précédentes.
- Tests de redimensionnement/restauration, GDI, opacité, menus, UI responsive et régressions Windows.

## 1.6.0 - 2026-11-19

- Moniteur CPS sur le tableau de bord : courbe glissante des 30 dernières secondes, état et CPS réels en direct. Désactivable depuis Paramètres ; données en mémoire seulement.
- Réglages rapides du Test CPS : modifier un brouillon de mode, minimum/maximum et intensité pour n'importe quel profil. Boutons Appliquer et Annuler, validation des plages et modification atomique du profil choisi.
- Mini-fenêtre Windows flottante au premier plan, indépendante de WebView2, avec profil actif, état, CPS, clics, Ouvrir et Stop.
- Icône de notification Windows : ouvrir/restaurer ClickFlow, arrêt, choix du profil et quitter proprement.
- Profils sous forme de cartes avec favoris et ordre personnalisable, persistés dans chaque fichier .ini individuel. Boutons Activer, Tester et Exporter.
- Nouvel onglet Paramètres pour l'affichage, les préférences de réduction/fermeture vers la zone de notification, les raccourcis Windows, le stockage et la désinstallation.
- Les options de masquage sont désactivées par défaut : le bouton X quitte toujours sauf choix explicite. Les relancements restaurent désormais l'application même masquée.
- Tests Windows et JavaScript complémentaires pour le moteur, les paramètres, la persistance et les nouvelles commandes.

## 1.5.0 - 2026-11-19

- Mode Naturel renforcé : variations progressives beaucoup plus visibles, avec un niveau Faible proche de l'ancien niveau Élevé.
- Micro-irrégularités partiellement corrélées entre les clics, courtes accélérations et rares hésitations selon Faible / Moyen / Élevé.
- Les délais ordinaires restent dans les limites CPS min/max, mais une hésitation ponctuelle peut ralentir sous le minimum sans rattrapage artificiel.
- Cadence identique dans le moteur réel et le Test CPS des profils ; les modes Fixe et Aléatoire restent inchangés.
- Texte explicatif des trois intensités et tests automatisés des distributions de délais sous Windows.

## 1.4.0 - 2026-11-19

- Le test CPS mesure désormais le profil ClickFlow sélectionné en réutilisant son cadenceur AutoHotkey (Fixe, Aléatoire ou Naturel).
- Mode de test manuel toujours disponible ; choix direct du profil dans l'onglet Test CPS.
- Léger retour sonore synthétique à chaque clic du test, activé par défaut et désactivable.
- Test sans clic Windows pour protéger les autres fenêtres ; arrêt d'urgence, annulation et gestion des changements d'onglet.
- Chronologie des déclenchements pour la courbe et le dernier résultat, sans sauvegarde des scores.
- Tests de non-régression JavaScript et AutoHotkey sur Windows.

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
