# ClickFlow - AutoCliker

**Version d'essai 1.9.12 - AutoClicker pour Windows, sans application .exe à installer.**

ClickFlow est un auto-clicker Windows avec une interface graphique WebView2, un moteur AutoHotkey v2, plusieurs modes de CPS et des profils sauvegardés.

## Télécharger

Télécharger le fichier unique **[ClickFlow-v1.9.12.ahk](https://github.com/77Romain77/ClickFlow-AutoClicker/releases/tag/v1.9.12)** depuis les Releases GitHub.

**Prérequis :** Windows 10/11 64 bits, [AutoHotkey v2 64 bits](https://www.autohotkey.com/) et le runtime Microsoft WebView2 (présent sur la plupart des Windows récents).

1. Installer AutoHotkey v2 si nécessaire.
2. Télécharger `ClickFlow-v1.9.12.ahk`.
3. Double-cliquer sur ce fichier.
4. Dans l'onglet **Paramètres**, créer séparément les raccourcis Bureau et menu Démarrer si nécessaire.

Au premier lancement, ClickFlow extrait ses composants locaux dans `%LOCALAPPDATA%\ClickFlow\Runtime-1.9.12`. Aucun compilateur ni `.exe` ClickFlow n'est nécessaire. Il n'y a **pas de téléchargement automatique de mises à jour**.

Le ZIP source accompagné de l'ensemble des composants est fourni comme alternative dans les Releases.

## Fonctionnalités

- De 1 à 100 CPS, en modes **Fixe**, **Aléatoire** et **Naturel**.
- Mode **Naturel v1.5** : trois intensités Faible / Moyen / Élevé nettement différenciées, évolution progressive de la cadence, irrégularités entre clics, accélérations brèves et hésitations occasionnelles.
- Clic gauche, droit ou central, en complément des clics physiques.
- Déclenchement configurable par touche du clavier ou bouton de souris.
- Modes **Maintenir** et **Basculer**.
- Option **Conditionner à un bouton de souris** : déclencher les clics uniquement pendant le maintien physique d'un bouton.
- Arrêt au changement de fenêtre et arrêt d'urgence personnalisable, **F12 par défaut**.
- **Interface compacte ou étendue**, choix mémorisé.
- **Tableau de bord : mini-moniteur CPS** des 30 dernières secondes, état et CPS actuels, sans aucun historique disque.
- **Test CPS : réglages rapides** du profil sélectionné (mode, CPS min/max, intensité), avec brouillon modifiable, vérification puis Appliquer / Annuler.
- **Overlay de statut léger** en option : état ACTIF/EN ATTENTE/ARRÊTÉ et CPS moyens sur une période réglable de 1 à 60 secondes (5 secondes par défaut), transparent aux clics et positionnable sur plusieurs écrans.
- **Menu de l'icône de notification Windows** : ouvrir/restaurer, arrêter les clics, sélectionner un profil, afficher l'overlay et quitter.
- **Profils sous forme de cartes** avec favoris, ordre personnalisable, actions Activer / Tester / Exporter. Favoris et ordre sont conservés dans les fichiers des profils.
- **Onglet Paramètres dédié** pour les préférences, la gestion des raccourcis Windows, les dossiers et la désinstallation.
- Profils locaux : création, duplication, renommage et suppression. Chaque profil est enregistré dans un fichier indépendant.
- Importer ou exporter un profil individuellement au format `.ini` (menu **Profils** ou profil actif).
- Statistiques de CPS et de clics générés.
- **Onglet Test CPS** : teste directement la cadence du profil ClickFlow sélectionné ou tes clics manuels, sur 2, 5, 10, 30 ou 60 secondes.
- CPS glissants sur une seconde, CPS moyens, pic, total, progression et courbe en temps réel.
- Animation lumineuse et léger effet sonore sur les clics du test, avec bouton pour désactiver le son.
- Seul le **dernier résultat terminé** est affiché pendant la session. Aucun score ni historique n'est sauvegardé sur le disque.
- Icône dédiée et raccourcis Windows facultatifs. Le menu **À propos** permet de les gérer.

## Correction du déclenchement conditionnel Raw Input (v1.9.12)

Retour utilisateur : après l'essai de la v1.9.11, le conditionnement à un bouton de souris fonctionne en Classique mais pas en mode Raw Input. La v1.9.11 enregistrait directement les notifications WM_INPUT sur la fenêtre WebView2 principale sans compter les messages livrés. L'enregistrement API réussi ne prouve donc pas qu'un appui a été reçu par le moteur.

Cette révision isole l'abonnement souris Raw Input dans **une fenêtre AutoHotkey dédiée et invisible**, indépendante du contrôleur graphique WebView2, pendant les sessions conditionnées uniquement. Elle conserve une protection croisée avec GetKeyState lors de l'envoi. À l'arrêt, elle désinscrit les périphériques, supprime le handler et détruit la fenêtre de réception. Aucun hook WH_MOUSE_LL supplémentaire n'est réintroduit.

**Diagnostic visible sans activer les mesures de latence :** l'onglet Test CPS et les paramètres indiquent le nombre de messages WM_INPUT reçus, les appuis/relâchements du bouton sélectionné reconnus et la lecture du bouton physique. Si le nombre d'appuis reste à zéro malgré la pression réelle de la souris, l'interface distingue le cas « enregistré, mais aucun message reçu » du cas « messages reçus, mais aucun appui reconnu ». Une valeur d'erreur Windows est affichée si l'abonnement échoue.

Classique reste le choix stable par défaut. Les deux modes Raw Input restent **expérimentaux** : la nouvelle fenêtre de réception a passé les tests d'enregistrement et de décodage simulé, mais seul un essai physique en dehors d'un jeu avec protections pourra confirmer la réception des vrais événements sur le PC. En cas de non-déclenchement, repasser en Classique et relever les nouveaux compteurs.

## Détection Raw Input expérimentale sans hook bloquant (v1.9.11)

Cette version propose à nouveau trois méthodes dans Paramètres > Diagnostics et détection souris :

- **Classique (par défaut, recommandé)** : comportement stable de v1.9.10 avec GetKeyState et le cadenceur CPS haute précision, aucun enregistrement Raw Input supplémentaire.
- **Automatique (expérimental)** : écoute les messages souris WM_INPUT via Windows Raw Input (RIDEV_INPUTSINK) lorsque la condition souris est active ; si l'enregistrement échoue ou que l'appui n'a pas été reçu, la lecture physique classique sert de secours. L'interface distingue le dernier chemin réellement utilisé.
- **Événementielle Raw Input (expérimental)** : demande une notification Raw Input pour activer la condition, sans repli silencieux si l'enregistrement échoue. Si la touche était déjà maintenue au lancement, la relâcher puis appuyer de nouveau pour l'essai.

**Aucun hook global WH_MOUSE_LL additionnel** n'est installé : l'ancien mécanisme ayant provoqué des freezes reste définitivement retiré. Les messages de la souris sont envoyés par Windows à la fenêtre principale du programme, y compris quand elle est en arrière-plan. La surveillance est activée uniquement pendant une session conditionnée en mode Raw Input et supprimée à l'arrêt. Pendant l'activation, l'état du bouton physique GetKeyState est également consulté pour empêcher les clics si une notification de relâchement arrive tardivement. Le même état de condition pilote l'overlay.

La fonction MsgWaitForMultipleObjectsEx rend l'attente du timer réactive aux messages Raw Input, mais ne promet pas un délai fixe : les résultats dépendent de Windows, des périphériques et des logiciels. Si Raw Input devient indisponible, le mode Automatique se rabat sur Classique ; le mode Événementielle reste en attente. Les performances d'entrée et le bon fonctionnement dans un jeu doivent être validés sur la machine utilisateur. Tester d'abord dans une application autorisant les clics automatisés, avec l'arrêt d'urgence actif.

**Diagnostics :** la mesure après réception d'un message Raw Input utilise QueryPerformanceCounter, pas l'ancienne valeur horodatée par paliers de ~16 ms. La moyenne affichée n'est donc **pas comparable** à l'ancienne moyenne 6,2 ms des v1.9.7-1.9.9. Elle mesure seulement le temps logiciel depuis la réception du message jusqu'au début de SendInput, et pas le temps total depuis l'appui matériel.

## Correctif de stabilité de la souris (v1.9.10)

**Important : les modes Événementielle et Automatique sont temporairement suspendus.** Un retour utilisateur a identifié des clics persistants après relâchement et des freezes de souris en mode événementiel, alors que le mode Classique fonctionnait. Le hook global `WH_MOUSE_LL` était installé sur le même thread AutoHotkey que le cadenceur. La documentation Microsoft précise que le délai d'exécution d'un hook bas niveau peut bloquer le traitement des entrées, puis conduire Windows à supprimer silencieusement le hook. Le mode événementiel actuel ne doit plus être utilisé.

Ce correctif impose le mode **Classique** au démarrage, y compris si une configuration précédente demandait Automatique ou Événementielle. Le sélecteur conserve les deux modes visibles mais grisés pour expliciter cette restriction. Les tentatives de réglage via un ancien frontend sont également rejetées côté moteur. Aucun `WH_MOUSE_LL` supplémentaire n'est installé par ClickFlow. Le contrôle de la condition souris utilise le mécanisme physique classique `GetKeyState`, avec le cadenceur haute précision et la cadence CPS conservés. Les diagnostics de latence restent facultatifs, mais les mesures liées au callback ne sont plus possibles en mode Classique.

Le moteur remet à zéro tous les horodatages de hook au début et à la fin des sessions et n'utilise plus d'horodatage précédent pour calculer un délai impossible tel que 174805 ms. Le diagnostic du temps logiciel du premier clic reste actif si l'utilisateur choisit de le mesurer.

Ce correctif privilégie la fiabilité et la sécurité des entrées utilisateur à une optimisation de quelques millisecondes. Une future refonte indépendante pourra examiner la solution recommandée par Microsoft, **Raw Input** (`WM_INPUT`), après validation dans des applications de test autorisant l'automatisation. Ni les raccourcis, ni le CPS, ni l'arrêt d'urgence, ni l'overlay ne sont volontairement modifiés.

## Choix de la méthode de détection souris et preuve du chemin utilisé (v1.9.9)

Dans Paramètres > Diagnostics et détection souris, trois modes sont disponibles : **Automatique** (recommandé, hook Windows + contrôle physique de secours), **Événementielle uniquement** (si le hook échoue après l'attente, aucune bascule silencieuse : la condition reste en attente), ou **Classique uniquement** (vérification physique du bouton, sans hook événementiel supplémentaire). Le réglage est conservé dans settings.ini sous General/MouseDetectionMode. Tout changement de mode interrompt la session de clics en cours avant d'appliquer le nouveau choix.

Le panneau Test CPS et la page des paramètres affichent indépendamment de l'interrupteur des diagnostics le **dernier mécanisme ayant réellement permis le clic conditionné** : événement par hook, contrôle classique, secours classique, ou bouton déjà maintenu au démarrage. Ils indiquent également si un hook est installé pendant l'attente. La présence d'un hook ne prouve pas que le déclenchement vient de lui : le contrôle physique peut gagner la course en mode Automatique. Aucun clic conditionné n'est signalé lorsque le profil ne possède pas de condition.

En mode Classique, les mesures de latence liées au callback souris ne sont pas disponibles, puisqu'aucun hook événementiel supplémentaire n'est installé (AutoHotkey conserve son hook de lecture de l'état physique). Les mesures restent facultatives. Les choix de moteur ne contournent pas les protections des jeux, ne garantissent pas la compatibilité avec leurs anti-cheats et ne changent pas les règles d'utilisation de l'automatisation.

## Condition souris réactive aux événements (v1.9.8)

Si le profil est conditionné au maintien d'un bouton de souris et que ce bouton n'est pas tenu, ClickFlow installe temporairement un hook souris Windows. Le callback marque le nouvel appui physique, sans envoyer de clic à l'intérieur du hook. Le cadenceur de haute précision utilise alors une attente native sensible aux messages `MsgWaitForMultipleObjectsEx`, ce qui permet de sortir de l'attente au signal de la souris sans patienter jusqu'au prochain sondage de 8 ms. La première échéance est réinitialisée sur cet appui, tandis que les intervalles des clics suivants conservent le calcul des CPS existant.

Depuis la v1.9.9, le hook reste installé pendant toute l'activation conditionnée, y compris après le premier clic, pour détecter explicitement le relâchement physique. Il est retiré à l'arrêt du profil. L'événement de relâchement est prioritaire sur une éventuelle lecture physique de touche obsolète, ce qui empêche les clics de continuer lorsque le bouton est relâché. Si l'installation du hook échoue, le moteur conserve le contrôle physique de secours toutes les ~8 ms pendant l'attente ; l'option reste donc utilisable sans hook. Le callback ignore les événements injectés, notamment ceux produits par `SendInput`, et respecte le bouton choisi (gauche, droit, central, X1 ou X2). Le raccourci Basculer, l'overlay et l'arrêt d'urgence sont inchangés.

Les diagnostics v1.9.7 restent facultatifs et désactivés par défaut. **Même diagnostics désactivés, le hook de détection du bouton peut s'installer temporairement pendant l'attente** : c'est une partie du fonctionnement, pas une mesure de latence. L'installation d'un hook bas niveau peut être restreinte par certains jeux ou logiciels de protection, et la latence réelle dépend toujours de Windows, de la charge machine et du logiciel cible. Tester si possible hors des jeux avec anti-triche. Le CPU au repos ne change pas.

Pour comparer avant/après, référence initiale relevée par l'utilisateur sur v1.9.7 : **6,2 ms estimés en moyenne sur 10 activations**. Cette estimation est grossière (horloge Windows quantifiée) : interpréter plusieurs essais sur la nouvelle version et ne pas promettre un gain déterministe sur chaque appui.

## Diagnostic de la condition souris avant optimisation (v1.9.7)

Dans l'onglet Test CPS (et aussi dans Paramètres > Diagnostics), un interrupteur permet d'activer ou de désactiver les diagnostics. Ils sont désactivés par défaut, état conservé dans settings.ini. **Quand ils sont désactivés**, aucun hook Windows de mesure n'est installé et le premier clic n'est plus chronométré : la mesure n'ajoute donc pas de travail pendant le jeu. Le Test CPS, le moniteur et l'overlay continuent à fonctionner.

Lorsque les diagnostics sont activés, ClickFlow mesure le délai d'envoi logiciel du premier clic. Si le profil attend un bouton souris, un hook Windows est installé seulement durant cette attente et libéré dès le premier clic ou l'arrêt. Il horodate la **réception du callback souris par ClickFlow**, pas l'appui physique : la différence entre cette réception et le début de SendInput est une mesure indicative et une **borne inférieure** du délai de réaction complet. Une seconde mesure exploite l'horodatage de l'événement Windows pour estimer le temps événement -> envoi. Sa résolution pouvant être voisine de 15,6 ms, ClickFlow affiche également la moyenne des 10 dernières activations conditionnées, sans prétendre mesurer la latence matérielle exacte. Si aucun événement valide n'est observé, l'interface affiche « mesure indisponible » au lieu d'inventer une valeur.

Cette version **n'optimise pas encore la détection** : elle ajoute uniquement l'instrumentation facultative pour permettre un test avant/après sur le même PC. Le hook ne provoque pas le clic. Évite de laisser les diagnostics activés dans les jeux avec anti-triche.

## Stabilité du mode Basculer et de l'overlay (v1.9.6)

Le moteur haute précision vérifie en complément de la notification "Up" l'état physique de la touche d'activation pendant la session, afin de réarmer correctement le mode Basculer même si la notification de relâchement est retardée. L'overlay automatique est affiché dès l'activation, avant le démarrage de la boucle haute précision. Si Windows masque la fenêtre overlay malgré un état interne visible, ClickFlow la restaure au prochain rafraîchissement. Le mode "Toujours afficher" demeure facultatif.

Les tests de régression supplémentaires sont intégrés dans les scripts Windows existants, sans nouvelle matrice.

## Diagnostic du premier clic conditionné (v1.9.5)

Lorsque le profil utilise "Conditionner à un bouton de souris", le diagnostic mesure désormais le premier clic réellement envoyé après validation de cette condition. Sans condition, il conserve la mesure depuis la réception du raccourci. Avec condition, l'intervalle affiché commence à la détection par ClickFlow du bouton maintenu : l'attente volontaire avant le maintien n'est pas incluse. L'affichage indique le type de mesure et montre "En attente" tant qu'aucun clic n'a été envoyé.

## Précision du cadenceur et diagnostic (v1.9.4)

Le moteur passe d'un timer AutoHotkey périodique (arrondi par Windows à 10-15,6 ms) à une boucle coopérative utilisant un timer natif haute résolution Windows et l'horloge QueryPerformanceCounter, créé uniquement pendant les clics ou le Test CPS, puis fermé à l'arrêt. Cela évite de changer la résolution générale des timers. Sur les anciens systèmes où ce timer n'est pas disponible, le moteur utilise temporairement timeBeginPeriod(1) en secours. Aucun timer moteur actif au repos. Les raccourcis et l'interface restent traités entre de courtes attentes, normalement de 8 ms ou moins, sous réserve de la charge système.

Dans Test CPS, le dernier résultat d'un profil fixe indique la cible, l'écart mesuré et l'intervalle moyen, sans clics Windows. Le champ "Diagnostic du premier clic réel" mesure l'intervalle logiciel depuis la réception du raccourci jusqu'au retour de SendInput lors d'une activation réelle dans une autre fenêtre. Ce n'est **pas** une mesure du délai matériel ni de la réaction du jeu. Aucun diagnostic n'est enregistré sur disque.

La CI ajoute trois mesures courtes (10, 50 et 100 CPS) dans le job Windows existant, sans nouveau workflow.

## Performance et latence du premier clic (v1.9.3)

Le moteur AutoHotkey n'effectue plus de vérifications de clic toutes les 10 ms lorsqu'il est au repos. Il active ce timer uniquement pendant les clics ou un Test CPS, puis le désactive immédiatement à l'arrêt. Les statistiques sont actualisées toutes les 1000 ms au repos, contre 200 ms pendant une session active.

Le premier clic est envoyé directement dans le callback de la touche d'activation (Maintenir comme Basculer), une fois les contrôles de fenêtre et de condition souris validés, sans attendre le timer. Le clic suivant est programmé à partir de cet envoi, pour conserver les CPS du profil et éviter les doubles clics. Si la condition souris n'est pas remplie, aucun premier clic n'est injecté tant qu'elle n'est pas satisfaite.

L'overlay conserve son délai de disparition d'environ 2,2 s après l'arrêt. Les raccourcis globaux, les sauvegardes, les profils et les réglages ne changent pas. Un test Windows mesure l'activité CPU du moteur au repos et vérifie le départ immédiat, la cadence et les arrêts.

## Correction de la capture des raccourcis (v1.9.4)

Dans **Paramètres > Raccourcis globaux**, clique sur la touche d'une action puis appuie sur la touche souhaitée **dans la fenêtre ClickFlow**. La frappe est lue directement par l'interface WebView2 et transmise au moteur AutoHotkey pour vérification et sauvegarde. La liste ne reste plus bloquée sur "Appuyez...". Appuie sur **Échap** pour annuler, ou sur **Aucun** pour supprimer la touche. Pour l'arrêt d'urgence, ce dernier choix désactive réellement le raccourci et laisse les commandes d'arrêt de l'interface et de la zone de notification opérationnelles.

## Arrêt d'urgence facultatif (v1.9.4)

Dans **Paramètres > Raccourcis globaux**, l'arrêt d'urgence figure maintenant avec les autres actions. Sa touche initiale reste **F12** pour les installations existantes, mais le bouton **Aucun** permet de ne définir aucune touche. La modification est la même que celle affichée sur le tableau de bord, et la préférence est conservée après redémarrage et restauration d'une sauvegarde complète.

Attention : lorsque le raccourci d'urgence est désactivé, il reste possible d'arrêter les clics avec le bouton **Arrêter les clics** de l'interface, ou depuis l'icône ClickFlow dans la zone de notification Windows. Les autres raccourcis globaux restent facultatifs et non attribués par défaut.

## Nouveautés v1.9.4 : raccourcis, sauvegarde et organisation

Dans **Paramètres > Raccourcis globaux**, tu peux attribuer une touche à chacune des actions suivantes : profil suivant, profil précédent, basculer l'overlay, ouvrir l'interface et ouvrir le Test CPS. **Toutes les actions sont sur "Aucun" par défaut** et ne font rien tant que tu ne leur attribues pas une touche. Pour retirer une touche, clique sur **Aucun**. Échap annule la capture. ClickFlow refuse les collisions avec les autres actions et les touches des profils. L'arrêt d'urgence est affiché dans cette même section : F12 par défaut, mais il peut aussi être mis sur Aucun.

Dans **Paramètres > Sauvegarde complète**, clique sur **Sauvegarder tout (.zip)** pour exporter **settings.ini et les fichiers de tous les profils**, favoris et ordre compris. Pour récupérer les données sur un autre PC, clique sur **Restaurer une sauvegarde** et sélectionne le ZIP. ClickFlow arrête les clics et demande confirmation, vérifie les fichiers avant toute modification, puis recharge les réglages. Si une erreur intervient pendant le remplacement, il tente de restaurer automatiquement les données précédentes. Les programmes, caches WebView2 et fichiers d'installation ne font pas partie de cette sauvegarde.

Dans **Paramètres > Overlay**, les nouvelles options **Taille** (mini, standard, grande) et **Afficher le nom du profil** sont indépendantes de la transparence libre, de la durée CPS, de la position et du multi-écran. La taille mini (216 x 34 px) et le nom caché restent les valeurs par défaut.

L'onglet **Paramètres** est désormais réparti en six catégories repliables : Général, Overlay, Raccourcis globaux, Raccourcis Windows, Sauvegarde complète et Maintenance.

## Durée personnalisable des CPS moyens (v1.9.4)

Dans **Paramètres > Overlay**, le champ **Période CPS moyens** accepte une durée entière de **1 à 60 secondes**. La valeur initiale est de **5 secondes**. Elle est sauvegardée dans `settings.ini` et conservée entre les lancements. L'overlay affiche la moyenne calculée à partir des clics réellement envoyés sur la période choisie (ou depuis le début de l'activation si la session est plus courte).

Le réglage change uniquement le calcul de la moyenne dans l'overlay. Il ne modifie ni la cadence des profils, ni la taille de l'overlay, ni le moniteur CPS du tableau de bord. Les mesures restent en mémoire et ne sont pas archivées.

## Lisibilité de l'overlay (v1.9.4)

Le statut et les CPS moyens sont maintenant placés sur **une seule ligne compacte** (216 x 34 pixels). L'overlay a des coins discrètement arrondis et une police ajustée à la mise à l'échelle Windows, de façon à éviter les textes coupés sans augmenter inutilement sa taille. Les six positions, le déplacement libre, la transparence de 0 à 100 % et le comportement automatique sont inchangés.

## Overlay de statut (v1.9.4)

L'ancienne mini-fenêtre flottante et sa courbe GDI sont supprimées. À la place, ClickFlow propose un **overlay discret** sans barre de titre, visible au-dessus des fenêtres classiques et des jeux en mode fenêtré ou sans bordure (le plein écran exclusif n'est pas garanti). Il affiche uniquement le statut **ACTIF / EN ATTENTE / ARRÊTÉ** et les **CPS moyens sur les 5 dernières secondes**, calculés à partir des clics réellement envoyés par ClickFlow. Aucun score ni historique n'est conservé sur le disque.

L'overlay est **transparent aux clics** : il ne bloque pas la souris. Par défaut, il s'affiche pendant la période d'activation et disparaît environ 2 secondes après l'arrêt. Dans **Paramètres**, on peut activer l'affichage permanent.

Dans **Paramètres > Overlay**, tu peux :
- choisir l'une des **6 positions** : haut gauche, haut milieu, haut droite, bas gauche, bas milieu ou bas droite ;
- choisir le **moniteur**, lorsque plusieurs écrans sont connectés ;
- ajuster la **marge de 0 à 100 pixels** ;
- saisir **n'importe quelle transparence entière de 0 à 100 %** (0 % rend l'overlay invisible) ;
- cliquer sur **Déplacer librement l'overlay**, puis le glisser avec la souris à l'endroit exact souhaité et cliquer sur **Terminer le placement**. Cette opération réactive immédiatement la transparence aux clics. La position personnalisée est mémorisée.

L'icône de notification Windows permet toujours d'activer/désactiver l'overlay, changer de profil, arrêter les clics et ouvrir l'interface principale. Les profils existants sont conservés.

La fenêtre principale de ClickFlow **s'ouvre centrée** sur un moniteur disponible. Sa taille est limitée à la zone visible pour éviter une fenêtre à moitié hors écran après un changement de résolution ou de moniteur. Chaque mode compact/étendu conserve sa taille propre.

## Lancer ClickFlow plusieurs fois et nettoyer les caches

Si ClickFlow est déjà ouvert, un nouveau lancement **ne ferme plus l'application en cours** : la fenêtre existante est remise au premier plan. Ceci évite le crash WebView2 observé lors d'un lancement multiple avec v1.0.0.

Après un démarrage réussi d'une nouvelle version, ClickFlow supprime automatiquement les anciens dossiers de programme de la forme `Runtime-X.Y.Z` créés par son lanceur. Il conserve le dossier courant, les paramètres, les profils, `ClickFlow.ahk`, `ClickFlow.ico`, `shortcuts.ini` et les dossiers de données WebView2. Si une ancienne version est encore ouverte, ferme-la avant de démarrer la nouvelle pour permettre le nettoyage.

## Raccourcis indépendants

Dans l'onglet **Paramètres**, tu peux installer ou supprimer séparément :

- le raccourci du Bureau ;
- le raccourci du menu Démarrer.

L'interface lit directement la présence de chaque raccourci Windows. Elle actualise les états à chaque ouverture de cet onglet. Si tu supprimes manuellement un raccourci depuis l'Explorateur, il reste supprimé : ClickFlow ne restaure plus automatiquement les raccourcis lors d'un lancement ou d'une mise à jour. Il suffit de revenir dans **Paramètres** pour le réinstaller.

Les anciennes préférences `shortcuts.ini` (`Enabled=1`) n'imposent plus la création de deux raccourcis. Les raccourcis historiques sont reconnus et peuvent être gérés indépendamment, sans toucher aux autres raccourcis présents sur l'ordinateur.

## Dossiers et désinstallation

Dans l'onglet **Paramètres** (mode étendu), les boutons **Ouvrir les fichiers du programme** et **Ouvrir les profils et paramètres** ouvrent directement l'Explorateur Windows dans :

- `%LOCALAPPDATA%\\ClickFlow` pour le lanceur local, l'icône, les runtimes et les caches WebView2 ;
- `%APPDATA%\\ClickFlow` pour les profils (`profiles\profile-*.ini`) et paramètres (`settings.ini` et ses sauvegardes).

La désinstallation propose deux opérations distinctes, avec confirmation **dans ClickFlow** :

1. **Désinstaller - conserver les données** : supprime le programme local, les anciens runtimes et caches et les raccourcis ClickFlow, mais conserve l'ensemble des profils et paramètres dans `%APPDATA%\\ClickFlow`.
2. **Tout désinstaller et effacer** : effectue les mêmes suppressions puis supprime aussi le dossier personnel `%APPDATA%\\ClickFlow`. Cette option demande de saisir `SUPPRIMER` pour éviter une suppression accidentelle.

Un petit script AutoHotkey temporaire attend la fermeture complète de ClickFlow avant de commencer la désinstallation. Aucun nouveau `.exe` n'est généré. **Les fichiers `.ahk` téléchargés hors du dossier de ClickFlow, par exemple dans Téléchargements, ne sont pas supprimés**. Les autres fichiers éventuellement placés dans le dossier local sont conservés par précaution. AutoHotkey v2, installé indépendamment, n'est pas désinstallé.

## Profils et mises à jour

Depuis v1.9.4, les profils sont conservés dans un dossier `%APPDATA%\ClickFlow\profiles`, sous la forme `profile-1.ini`, `profile-2.ini`, etc. Le fichier `%APPDATA%\ClickFlow\settings.ini` contient les préférences globales (touche d'arrêt d'urgence, mode de fenêtre) et l'identifiant du profil sélectionné.

**Migration automatique :** les profils de la v1.1.0 et des anciennes versions sont lus une seule fois depuis `settings.ini`, puis enregistrés dans des fichiers indépendants. Les anciennes sections et les sauvegardes restent disponibles par précaution. Les fichiers exportés se réimportent individuellement, sans écraser les profils déjà présents. Si un nom existe déjà, ClickFlow ajoute un suffixe numérique.

Chaque version publiée possède un numéro et son cache de composants. Télécharger et lancer un nouveau fichier `.ahk` met à jour la copie locale utilisée par les raccourcis, sans supprimer les profils.

## Les variations du mode Naturel

Le mode Naturel ne se limite plus à déplacer lentement une cible de CPS. Il combine des variations progressives, de petites irrégularités dans le délai entre les clics, des accélérations sur quelques clics et de courtes hésitations :

- **Faible** : variations sensibles (proches de l'ancien niveau Élevé), petites irrégularités, rares hésitations.
- **Moyen** : variations plus marquées, cadence plus vivante, hésitations et accélérations occasionnelles.
- **Élevé** : variation plus nerveuse, micro-délais nettement moins réguliers, quelques accélérations et hésitations plus franches.

Pour les clics ordinaires, la cadence reste dans la plage min/max CPS configurée. Une hésitation exceptionnelle peut créer un intervalle plus long (donc un CPS observé inférieur au minimum), sans rafale artificielle de rattrapage. Si les CPS minimum et maximum sont égaux, les imperfections de timing peuvent encore être visibles. Les deux autres modes, Fixe et Aléatoire, conservent leur fonctionnement.

Dans l'onglet **Test CPS**, sélectionne un profil Naturel et teste-le sur 30 ou 60 secondes : c'est le même calcul de cadence que pour les clics réels, sans clic envoyé dans les autres fenêtres.

## Utiliser le test CPS

Depuis l'onglet **Test CPS**, choisis une durée de 2, 5, 10, 30 ou 60 secondes, puis sélectionne l'un des deux modes :

- **Profil ClickFlow** (mode par défaut) : sélectionne n'importe quel profil enregistré puis clique sur **Démarrer le test**. Le test utilise le vrai cadenceur AutoHotkey du profil (modes Fixe, Aléatoire et Naturel), avec ses réglages CPS minimum/maximum et intensité. Les événements de cadence sont transmis au graphique et au compteur sans produire de clics dans Windows. Pour ce test de vitesse, ni la touche d'activation ni la condition souris ne sont nécessaires.
- **Clics manuels** : clique avec le bouton gauche dans la grande zone bleue. Le premier clic démarre le chronomètre et compte dans les résultats.

Les deux modes affichent les CPS glissants sur la dernière seconde, les CPS moyens, le pic sur une seconde, le total, une barre de progression et une courbe en direct. Une petite animation et un clic sonore synthétique (Web Audio, sans fichier externe) accompagnent les clics. Le bouton **Son activé** permet de couper le son.

Le banc de test est séparé de l'injection Windows : il mesure les déclenchements du moteur, et non la réception de clics par un jeu ou une autre application. Les clics manuels ne sont comptabilisés que dans la zone de test. L'arrêt d'urgence et le changement d'onglet interrompent le test du profil.

**Seul le dernier essai terminé reste affiché** pendant la session. Aucun résultat ni record n'est enregistré dans les fichiers personnels.

## Code source

| Chemin | Rôle |
| --- | --- |
| `src/ClickFlow-WebView2.ahk` | Lanceur de fenêtre Windows |
| `src/ClickFlow-Backend.ahk` | Moteur CPS, raccourcis, profils, sauvegarde |
| `src/ClickFlow-ProfileStore.ahk` | Fichiers individuels, migration et import/export des profils |
| `src/lib/` | Dépendances WebView2/AutoHotkey et licence de thqby |
| `ui/index.html` | Interface HTML/CSS/JavaScript |
| `tools/build_single_ahk.py` | Création du fichier `.ahk` unique |
| `tools/make_icon.py` | Génération de l'icône Windows |
| `tests/` | Vérifications automatiques AutoHotkey |
| `.github/workflows/windows.yml` | Build, validation et publication Windows |

Pour reconstruire le fichier unique, consulter [CONTRIBUTING.md](CONTRIBUTING.md).

## Versions historiques

L'ancienne tentative en C#/WPF produisant un `.exe` a été déplacée dans la branche **[archive/dotnet-wpf](https://github.com/77Romain77/ClickFlow-AutoClicker/tree/archive/dotnet-wpf)**. Elle ne fait plus partie de `main` et ne sera plus compilée par le workflow officiel.

Les anciennes releases (notamment v0.1.0 et les prototypes v0.3.x) sont conservées pour l'historique. Voir [docs/ARCHIVES.md](docs/ARCHIVES.md).

## Sécurité et limites

ClickFlow ne contourne pas les anti-triches et ne garantit pas la compatibilité avec tous les jeux ou applications. Respecter leurs règles. Les clics simulés peuvent être ignorés par certains programmes et la fréquence réelle dépend des minuteries Windows. **Ne pas désactiver Smart App Control** pour installer ClickFlow.

Licence MIT : [LICENSE](LICENSE). La bibliothèque WebView2 de thqby possède sa licence propre dans `src/lib/LICENSE-thqby`.
