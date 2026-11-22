# Historique des versions

## 1.9.31 - 2026-11-22

- Supprime le hook Windows WH_MOUSE_LL ajouté par le banc de test Réception réelle, suspecté de bloquer SendInput environ 300 ms à intervalles irréguliers.
- Lit désormais les appuis et relâchements de souris physiques via Raw Input (WM_INPUT), indépendamment des messages de clic injectés et sans hook bas niveau supplémentaire.
- Ignore les messages WM_INPUT à périphérique nul, effectivement générés par SendInput dans la CI Windows, pour qu'une injection ne simule jamais le relâchement physique.
- Active l'abonnement Raw Input uniquement pendant la fenêtre native et le désactive à la fermeture, y compris lors des erreurs.
- Conserve les protections de focus et de zone, la distinction clic physique/injecté, les diagnostics détaillés et le moteur normal inchangé.
- Ajoute des tests Windows du branchement Raw Input, des boutons gauche/droit/milieu, du déclenchement et de la désinscription. Essai sur souris physique toujours nécessaire.


## 1.9.30 - 2026-11-22

- Remplace le second timer actif d'envoi de clics dans la fenêtre **Réception réelle** par un watchdog non-injectant de 250 ms ; seule la boucle de haute précision peut désormais dispatcher un clic.
- Ajoute un verrou anti-réentrée par test et réserve la prochaine échéance avant SendInput.
- Empêche les clics immédiatement rapprochés après un SendInput long, sans inventer de clics de rattrapage et sans accélérer le profil.
- Diminue les actualisations de la fenêtre Windows et les notifications WebView2 pendant la mesure.
- Ajoute des diagnostics séparés de durée maximale SendInput, retard de la planification, délai d'envoi WebView2 et réentrées empêchées.
- Étend les tests Windows AutoHotkey et JavaScript. Le moteur normal est inchangé ; la validation de la cadence sur les PC des utilisateurs reste nécessaire.


## 1.9.29 - 2026-11-21

- Ajoute une mesure indépendante par horloge haute précision (QPC) pour chaque clic réellement envoyé par le moteur de la fenêtre native.
- Compare sur le graphique des intervalles la chronologie d'envoi (orange) à celle des messages reçus/traités par la fenêtre (vert), afin d'identifier une file Windows retardée sans confondre cela avec une pause de génération.
- Ajoute un diagnostic lisible après le test : intervalle moyen, intervalle maximal, pauses de 200 ms ou plus et événements regroupés à moins de 5 ms pour chaque chronologie.
- Réduit la fréquence des mises à jour visuelles de la fenêtre native/WebView2 pour limiter leur surcharge, sans modifier la vitesse du moteur ni la détection du maintien physique.
- Assure la transmission et la récupération de l'ensemble des horodatages en continu et dans le message de résultat final, même lors d'une confirmation retardée.
- Tests de régression JavaScript/Windows dédiés. Aucune mesure dans une application externe et aucun résultat conservé sur disque.


## 1.9.28 - 2026-11-21

- Corrige la disparition des résultats du test **Réception réelle** : un délai de confirmation ne remet plus les compteurs et les graphiques à zéro.
- Demande explicitement au moteur Windows de renvoyer le résultat final lorsqu'une confirmation tarde ; le dernier résultat natif est conservé en mémoire pour récupération après fermeture de la fenêtre.
- Si le moteur ne confirme toujours pas la fin ou si la fenêtre est interrompue, conserve les mesures reçues en les signalant comme **incomplètes**, plutôt que de les présenter comme un test validé.
- Accepte une confirmation tardive et remplace automatiquement le résultat provisoire par la mesure complète.
- Clarifie dans l'onglet **Test CPS** où consulter les résultats ; ajoute des régressions JavaScript et AutoHotkey dédiées.
- Ne modifie pas le moteur général de clics et ne sauvegarde aucun score sur disque.


## 1.9.27 - 2026-11-21

- Corrige le démarrage inopérant de la réception réelle : la zone statique ne transmettait pas de façon fiable les messages de bouton physique.
- Installe un hook souris bas niveau uniquement pendant le test, filtrant les événements SendInput injectés afin de ne pas confondre relâchement artificiel et vrai relâchement du maintien.
- Prend en charge le premier clic qui active la fenêtre avant le démarrage ; réappui après relâchement sans relancer l'application.
- Actualise la fenêtre Windows : barre de titre native sombre lorsque disponible, panneaux contrastés, statut visible, compteurs séparés pour appuis physiques, clics envoyés, clics reçus, temps restant et bouton de fermeture.
- Conserve la réception réelle des clics Windows, la précision du moteur et les contrôles de sécurité sur le focus et la zone. Aucun changement au moteur général.
- Étend les tests natifs avec appui/relâchement physiques simulés, protection contre les événements injectés sur le même bouton, reprise et sortie de zone.


## 1.9.26 - 2026-11-21

- Ajoute une troisième source **Réception réelle** dans Test CPS : une fenêtre native Windows reçoit réellement les clics SendInput générés à partir d'un profil sélectionné.
- Marque les événements d'injection du test avec MOUSEINPUT.dwExtraInfo et compte uniquement les messages Windows reçus dans la zone de test ; les clics physiques de déclenchement ne sont pas comptés.
- Affiche côte à côte le nombre de clics envoyés et reçus, la cadence effectivement reçue et les intervalles entre messages reçus dans les graphiques existants.
- Réutilise le cadenceur haute précision, les variations du profil et le déclenchement par bouton conditionnel, avec le clic gauche comme bouton par défaut.
- Empêche les envois hors du focus et hors de la zone contrôlée ; ferme le test au changement de fenêtre, à la sortie de zone, à l'arrêt d'urgence ou à la fin du temps.
- Ajoute une régression native Windows avec véritable SendInput marqué, vérification du message reçu et des protections de zone, et un test JavaScript de l'intégration au Test CPS.
- Le test mesure la réception Windows dans ClickFlow, pas les événements reçus par un jeu. Aucun score enregistré, pas de changement au moteur général.


## 1.9.25 - 2026-11-21

- Corrige la dérive cumulative de la cadence : échéances ancrées à la chronologie prévue plutôt que recalculées depuis chaque réveil Windows légèrement en retard.
- Conserve les fractions de milliseconde introduites en v1.9.24 pour plus de précision sur les CPS au dixième.
- En cas de pause longue, réinitialise la phase et impose un intervalle sûr avant de reprendre, sans aucun clic de rattrapage.
- Les premiers clics de chaque activation ou nouvel appui conditionnel restent immédiats.
- Le Test CPS utilise désormais exactement cette même planification pour ses graphiques et mesures.
- Ajoute un test Windows simulant 30 secondes à 12,3 CPS avec 0,9 ms de retard et vérifiant l'absence de rafales après une pause.
- Aucun changement de la détection souris Raw Input, des profils, ni des raccourcis.


## 1.9.24 - 2026-11-21

- Introduit un accumulateur de fractions de milliseconde pour le calcul des intervalles de clics, afin d'améliorer la cadence moyenne à CPS décimaux sans surcoût de polling, attente active ou clics de rattrapage.
- Réinitialise cet accumulateur à chaque session/test ; conserve le premier clic immédiat, le maximum de 100 CPS et les mécanismes de détection/sécurité existants.
- Ajoute dans le Test CPS une chronologie glissante de 3 s des clics, une courbe des 60 derniers intervalles et leur moyenne, minimum et maximum en millisecondes.
- Les graphiques utilisent les horodatages du Test CPS (profil ou clics manuels), pas des clics injectés dans d'autres applications ; aucun score sauvegardé.
- Ajoute des tests Windows pour la précision 12,3/12,4 CPS et les profils, et des tests UI pour le calcul et l'affichage des intervalles.


## 1.9.23 - 2026-11-21

- Étend les variations Personnalisé de Rapide naturel : 0-50 % entre les rafales et 0-25 % entre les clics, toujours par pas de 0,5 %.
- Met à jour les limites côté backend, les champs des interfaces complète et compacte ainsi que l'éditeur du Test CPS ; les anciennes valeurs restent valides.
- Les plages théoriques de CPS se recalculent automatiquement avec les nouvelles valeurs et respectent la borne 1-100 CPS.
- Étend les tests UI et AHK : rafales à 50 %, micro-variations à 25 %, sauvegarde, édition rapide et refus des valeurs hors limite.
- Aucun changement au moteur de clic, à la détection souris, aux préréglages ou au calcul RPM.


## 1.9.22 - 2026-11-21

- Autorise le réglage des CPS au dixième (pas de 0,1 CPS) dans les modes Fixe, Aléatoire et Naturel.
- Applique ce pas aux sliders, champs numériques du tableau de bord, au panneau compact et à l'éditeur du Test CPS.
- Valide les limites décimales dans le backend et conserve les décimales dans les profils INI, les imports, les exports et les duplications, sans casser les anciens profils entiers.
- Ajoute des tests Windows et Node sur le moteur, le calcul des intervalles, la sauvegarde et les contrôles UI.
- Aucun changement aux modes Rapide naturel et détection souris.


## 1.9.21 - 2026-11-21

- Corrige l'absence de bouton actif lors du choix Précision, Équilibré, Souple ou Personnalisé dans Rapide naturel (attributs HTML data-rapid-preset et data-compact-rapid).
- Restaure aussi la sélection active des boutons en vue compacte utilisant des attributs composés, avec aria-pressed mis à jour.
- Ajoute les deux plages CPS recalculées immédiatement selon la cible et les variations : base par rafale et totale théorique par clic, dans les vues complète et compacte.
- Borne les estimations à 1-100 CPS, comme le moteur, et avertit qu'elles ne tiennent pas compte de l'arrondi de timing Windows.
- Tests UI automatiques pour la sélection des quatre niveaux et les plages CPS ; moteur et détection souris inchangés.


## 1.9.20 - 2026-11-21

- Ajoute Rapide naturel, quatrième mode pour rafales courtes : CPS cible unique (précision 0,1), nouvelle cadence à chaque maintien, micro-variations par clic et aucune hésitation volontaire.
- Ajoute Précision (2 % / 1 %), Équilibré (4 % / 2 %), Souple (6 % / 3 %) et Personnalisé (0-10 % / 0-5 %, pas de 0,5 %).
- Ajoute le calcul RPM arme -> CPS théorique par le bouton Calculer le CPS (60-6000 RPM) et conserve la source RPM dans le profil. Toute modification manuelle du CPS cible retire la source RPM.
- Conserve les modes Fixe, Aléatoire et Naturel et la détection souris inchangés ; enregistre les réglages par profil, duplication, import et export.
- Intègre le mode rapide au tableau de bord, panneau compact et Test CPS, avec édition non destructive et simulation du moteur sans clic Windows.
- Étend les tests de cadence des rafales, conversion RPM, sauvegarde INI, contrôle UI et Tests CPS.


## 1.9.19 - 2026-11-21

- Clarifie les trois modes : Classique vérifie régulièrement le bouton ; Automatique tente de réduire le délai du premier clic et garde un secours classique ; Événementielle utilise le démarrage rapide sans secours.
- Raccourcit les libellés du sélecteur pour qu'ils restent lisibles.
- Corrige le diagnostic détaillé : les états Raw Input, GetKeyState et périphérique suivi sont décrits sans évoquer l'ancienne sécurité retirée en v1.9.18.
- Distingue la dernière mesure de réaction Raw Input et sa moyenne sur 10 activations au maximum, et précise qu'il ne s'agit pas de la latence depuis l'appui matériel ni d'une comparaison directe avec le mode Classique.
- Aucun changement apporté au moteur de clic ni au filtrage matériel validé sur la v1.9.18 ; adaptation des tests d'interface et de la documentation.


## 1.9.18 - 2026-11-20

- Corrige la confusion entre le maintien physique et les clics injectés lorsque le bouton de condition et le bouton généré sont identiques.
- Traite les événements Raw Input par identifiant matériel hDevice : les événements sans identité et les autres périphériques ne changent pas l'état suivi dans ce cas.
- Un vrai relâchement du périphérique suivi coupe la condition, même si GetKeyState signale encore DOWN. Un nouveau DOWN du même périphérique réarme le moteur.
- Retire les sécurités GetAsyncKeyState apparues en 1.9.16-1.9.17 qui arrêtaient incorrectement le maintien.
- Conserve le mode Classique et le comportement habituel avec deux boutons différents.
- Diagnostics opt-in : compteurs d'événements sans périphérique ignorés et état du bouton matériel suivi.
- Tests simulant une rafale d'événements sans périphérique à 10 et 50 CPS puis un vrai relâchement et un vrai nouvel appui.


## 1.9.17 - 2026-11-20

- Corrige les arrêts intempestifs sous maintien en mode Événementielle et Automatique observés sur PC réel dans la v1.9.16.
- Lors d'un désaccord persistant Raw Input UP / GetKeyState DOWN / GetAsyncKeyState UP, suspend d'abord l'envoi de clics, puis réévalue l'état de Windows sans SendInput avant toute décision d'arrêt.
- La vérification est déclenchée après 12 ms de désaccord continu et dure jusqu'à 50 ms sans injection ; le maintien peut reprendre si GetAsyncKeyState reconfirme le bouton enfoncé.
- Si le relâchement persiste après cette pause, le profil est arrêté pour éviter les clics fantômes. Le mode Classique est inchangé.
- Le diagnostic facultatif conserve explicitement le motif d'arrêt de sécurité lorsque le moteur est au repos.
- Ajoute des tests de désaccord transitoire, de pause, de reprise, d'arrêt et de désarmement, sans nouvel hook global.
- À confirmer sur une vraie souris : les tests du runner ne simulent pas les effets des pilotes et des clics SendInput pendant un maintien physique.


## 1.9.16 - 2026-11-20

- Ajoute une protection contre les clics persistants dans les modes Automatique et Événementielle : un désaccord prolongé entre Raw Input (UP), GetKeyState (DOWN) et GetAsyncKeyState (UP) déclenche l'arrêt complet de la session.
- Le désaccord doit persister plus de 35 ms pour limiter les faux positifs pendant SendInput. Cet arrêt de sécurité empêche le mode Automatique de redémarrer sur un état AHK resté bloqué.
- Le mode Classique reste inchangé ; aucun hook WH_MOUSE_LL supplémentaire n'est installé.
- Ajoute GetAsyncKeyState aux diagnostics détaillés facultatifs pour comprendre les désaccords entre sources.
- Corrige les deux libellés de version figés sur 1.9.14 en pied de page, maintenant affichés comme 1.9.16.
- Cette protection nécessite validation avec la souris réelle ; un déclenchement de sécurité pendant un vrai maintien indique un faux positif à analyser.


## 1.9.15 - 2026-11-20

- Ajoute un interrupteur indépendant pour les diagnostics détaillés de détection souris, désactivés par défaut.
- Arrête les compteurs Raw Input et les vérifications physiques supplémentaires destinées aux diagnostics lorsque cette option est désactivée ; la détection souris et le maintien restent actifs.
- Retire les mentions "expérimental" dans l'interface et explique les modes Classique, Automatique et Événementielle.
- Recommande Automatique (Raw Input avec secours classique), sans modifier le choix sauvegardé de l'utilisateur.
- Étend les tests de régression et conserve l'option de mesure de latence indépendante.


## 1.9.14 - 2026-11-20

- Corrige la contradiction observée sur le PC de test : Raw Input signale UP pendant que GetKeyState confirme que le bouton conditionnel est toujours maintenu.
- Le premier événement Raw DOWN autorise la condition, puis l'état physique confirmé prend le relais pour le maintien et le relâchement ; UP Raw discordant ne coupe plus prématurément la cadence.
- Une confirmation très courte (8 ms maximum) traite les clignotements physiques pendant SendInput ; un RAW DOWN orphelin ne peut pas maintenir la rafale après relâchement confirmé.
- Ajoute un compteur de RAW UP reçus pendant un maintien physique, visible dans Test CPS et Paramètres ; tests déterministes ciblés sur les désaccords, le secours Auto et l'arrêt.
- Classique reste stable et sélectionné par défaut. Raw Input demeure expérimental jusqu'à confirmation matérielle.


## 1.9.13 - 2026-11-20

- Corrige l'arrêt des clics répétés pendant qu'un bouton conditionnel Raw Input reste maintenu : ne combine plus chaque DOWN Raw Input avec GetKeyState pouvant fluctuer pendant SendInput.
- Le premier UP Raw Input reprend la priorité absolue pour stopper les clics ; Automatique conserve la méthode physique de secours tant qu'aucun événement Raw Input n'a été reçu.
- Ajoute une comparaison visible Raw Input / GetKeyState / décision du moteur, utile pour distinguer blocage du déclenchement et relâchement détecté.
- Régression Windows légère : 2 clics successifs après DOWN simulé, aucun après UP ; modes Auto et Événementielle ; aucune modification au mode Classique.
- Reste expérimental : aucun test du runner ne reproduit à lui seul les signaux de la souris physique de l'utilisateur.


## 1.9.12 - 2026-11-20

- Correctif expérimental de la condition souris Raw Input v1.9.11 qui ne déclenche pas sur certaines machines.
- Raw Input reçu sur une fenêtre AHK privée et invisible au lieu de la fenêtre principale WebView2.
- Compteurs visibles des messages Raw Input, appuis et relâchements reconnus, état physique et dernière erreur d'enregistrement : distingue inscription réussie et vrais événements reçus.
- Nettoyage complet de la fenêtre dédiée, de l'inscription Raw Input et du callback à l'arrêt du profil.
- Tests légers sur la séparation de HWND et les compteurs d'appui/relâchement, sans nouveau workflow GitHub Actions.
- Classique reste stable et sélectionné par défaut ; aucune réactivation de WH_MOUSE_LL. Essai matériel réel encore nécessaire.


## 1.9.11 - 2026-11-20

- Ajout expérimental de la réception souris Raw Input (WM_INPUT + RIDEV_INPUTSINK) sans hook WH_MOUSE_LL bloquant. Compatibilité de fond avec les fenêtres cibles.
- Méthodes Classique (stable et par défaut), Automatique (Raw Input avec secours physique) et Événementielle Raw Input (sans repli silencieux). Conservation du réglage.
- Détection séparée de l'appui et du relâchement pour les 5 boutons. Croisement avec l'état physique pour limiter les clics qui continuent après relâchement.
- Inscription Raw Input uniquement pendant l'activation conditionnée, retrait à l'arrêt ; attente native interrompue par QS_RAWINPUT, sans cadenceur actif supplémentaire au repos.
- Nouveau diagnostic logiciel haute précision après réception de WM_INPUT ; les anciennes moyennes estimées avec l'horloge Windows ne sont pas comparables.
- Tests Windows Raw Input intégrés aux scripts existants sans nouveau workflow ni matrice.


## 1.9.10 - 2026-11-20

- Correctif urgent de stabilité : désactive entièrement le hook souris global `WH_MOUSE_LL` supplémentaire à l'origine probable de freezes et de clics persistants.
- Force le mode Classique au démarrage, y compris pour les configurations précédentes Automatique/Événementielle ; options suspendues affichées en grisé, requêtes anciennes refusées.
- Restaure l'attente classique du cadenceur avec contrôle physique `GetKeyState`, sans revenir au timer CPS de basse précision.
- Remet à zéro les horodatages de callback pour supprimer les mesures aberrantes (plusieurs minutes) et indique leur indisponibilité en mode Classique.
- Tests Windows courts de non-installation du hook, du contrôle conditionnel, du nettoyage et du changement de mode ; pas de nouveau workflow.
- Refonte future envisagée via Windows Raw Input après validation ; le hook actuel reste suspendu.


## 1.9.9 - 2026-11-20

- Ajoute trois choix globaux de détection du bouton conditionnel : Automatique (événement + secours), Événementielle uniquement, Classique uniquement.
- Affiche dans Test CPS et Paramètres la méthode ayant réellement déclenché le dernier clic et l'état actuel du hook, même si les diagnostics de latence sont coupés.
- Corrige les clics persistants après relâchement du bouton conditionnel en conservant la détection événementielle pendant toute la session. L'overlay s'appuie sur le même état effectif que le moteur. Hook libéré à l'arrêt.
- Conserve le mode choisi entre les lancements ; changement de méthode appliqué après arrêt de la session en cours.
- En mode Classique, aucun hook événementiel supplémentaire n'est installé ; en Événementielle uniquement, l'indisponibilité du hook est affichée sans déclenchement de secours implicite.
- Régressions intégrées aux tests Windows existants, sans nouvelle matrice ni workflow.


## 1.9.8 - 2026-11-20

- Détection événementielle de l'appui du bouton de souris conditionnel, sans injection de clic depuis le callback Windows.
- Attente du cadenceur interruptible par les messages `MsgWaitForMultipleObjectsEx` tant que la condition n'est pas remplie, avec repli polling si hook indisponible.
- Hook actif uniquement quand le bouton est attendu et retiré au clic/à l'arrêt ; filtrage des événements `SendInput`.
- Réinitialisation immédiate de l'échéance après l'appui conditionnel ; CPS et timers adaptatifs conservés.
- Diagnostics désactivables et moyenne d'estimation Windows v1.9.7 conservés ; tests rapides ajoutés au script existant.


## 1.9.7 - 2026-11-20

- Ajoute un interrupteur de diagnostics facultatifs et désactivés par défaut dans Test CPS et Paramètres, synchronisé et enregistré.
- Mesure le délai callback Windows -> premier clic (borne inférieure), ainsi qu'une estimation horodatée événement Windows -> envoi et sa moyenne sur 10 échantillons, avant toute optimisation.
- Mesure de référence conservée pour le premier clic immédiat ; aucune mesure coûteuse ni hook de diagnostic lorsque l'interrupteur est désactivé.
- Hook de diagnostic installé seulement pendant l'attente de la condition souris, libéré au premier clic, à l'arrêt et à la fermeture. Information d'indisponibilité si aucun événement n'a été horodaté.
- Régressions légères ajoutées aux tests Windows existants, sans nouveau workflow.


## 1.9.6 - 2026-11-20

- Réarme le mode Basculer en contrôlant aussi le relâchement physique du raccourci pendant la session, afin que le deuxième appui puisse arrêter les clics.
- Affiche l'overlay automatique dès l'activation et restaure une fenêtre overlay masquée par Windows sans activer l'option permanente.
- Tests de régression étendus pour le deuxième appui et l'overlay d'activation, dans les scripts Windows déjà présents.
- Conserve le moteur haute précision, les performances au repos, les profils et les diagnostics.


## 1.9.5 - 2026-11-20

- Corrige la mesure du premier clic si l'activation est conditionnée au maintien d'un bouton de souris.
- La mesure commence après détection de la condition, sans inclure l'attente volontaire du bouton.
- Diagnostic explicite de l'état "En attente du bouton de souris" et origine de la mesure (activation / condition).
- Régression ajoutée au test Windows existant, sans nouveau job ni nouveau workflow.


## 1.9.4 - 2026-11-20

- Cadenceur haute précision : remplace la vérification AutoHotkey périodique par un timer Windows natif haute résolution et QueryPerformanceCounter, utilisés uniquement pendant l'activité et fermé immédiatement à l'arrêt (secours timeBeginPeriod uniquement si indisponible).
- Réduit la perte de CPS aux cadences rapides (notamment 50 et 100), tout en conservant le premier clic immédiat, les protections et la consommation minimale au repos.
- Diagnostic dans Test CPS : cible fixe, écart, intervalle moyen réel du cadenceur ; délai logiciel du premier clic réel mesuré via QueryPerformanceCounter, clairement distingué de la latence physique.
- Tests automatisés Windows courts aux cadences 10, 50 et 100 CPS, ajoutés au job existant.

## 1.9.3 - 2026-11-20

- Timers adaptatifs : le moteur de clics n'a plus de timer à 10 ms lorsqu'il est arrêté ; le timer est actif uniquement pendant les clics automatiques ou un Test CPS.
- Premier clic envoyé directement depuis l'événement d'activation (modes Maintenir et Basculer), sans attendre le premier tick de 10 ms ; calcul du délai avant le clic suivant depuis cet envoi pour éviter tout doublon.
- Rafraîchissement des statistiques réduit à une fois par seconde au repos, conservé à cinq fois par seconde pendant l'activité.
- Maintien des sécurités de focus, de relâchement de touche, de conditionnement souris, d'arrêt d'urgence et de l'affichage de l'overlay pendant 2,2 secondes après l'arrêt.
- Bench et tests Windows : latence réelle du premier clic, absence de double clic, cadence 5 CPS, réactivation, conditions de sécurité, timer du banc de test, arrêt des timers et temps CPU au repos.
- Aucun changement de l'interface, des profils ni de leur cadence cible.

## 1.9.2 - 2026-11-20

- Corrige la capture des raccourcis globaux qui restait bloquée sur "Appuyez..." : la touche est désormais récupérée par WebView2 (fenêtre qui possède le focus) et validée puis enregistrée par AutoHotkey.
- Nouvelle séquence de messages begin/set/cancel/clear, avec suspension des raccourcis pendant l'attribution et réponse de synchronisation de l'état après la modification.
- Corrige le bouton "Aucun" de l'arrêt d'urgence et des autres actions ; la touche vide est conservée dans les paramètres et l'affichage est mis à jour après confirmation du moteur.
- Échap annule la capture, les collisions entre raccourcis/profils sont refusées, et l'arrêt reste possible depuis le tableau de bord ou l'icône Windows.
- Tests Windows AutoHotkey des commandes réelles WebView2, et tests JavaScript simulant les frappes F9/F10, l'annulation, "Aucun" et la synchronisation du navigateur.

## 1.9.1 - 2026-11-20

- Arrêt d'urgence déplacé dans la liste des raccourcis globaux avec un bouton pour modifier la touche et un bouton "Aucun".
- F12 reste le réglage initial et les anciens raccourcis sont conservés ; l'utilisateur peut volontairement désactiver la touche d'urgence.
- L'absence de raccourci d'urgence est correctement persistée dans settings.ini et dans les sauvegardes ZIP, sans réactivation forcée au démarrage.
- Les commandes d'arrêt depuis l'interface et la zone de notification restent accessibles, même sans raccourci clavier.
- Tests Windows de désactivation, réaffectation, détection des conflits, persistance et restauration ZIP.

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
