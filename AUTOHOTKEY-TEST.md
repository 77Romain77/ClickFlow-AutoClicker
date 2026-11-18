# ClickFlow AutoHotkey v2 - version experimentale 0.2.4

**Cette branche est independante de `main`.** La version C# et sa release v0.1.0 restent inchangees.

## Installation et mise a jour

1. Installer AutoHotkey v2 depuis https://www.autohotkey.com/ (une seule fois).
2. Ouvrir [ClickFlow-test-v0.2.4.ahk](ClickFlow-test-v0.2.4.ahk), cliquer sur **Raw**, puis enregistrer le fichier avec son extension `.ahk`.
3. Fermer l'ancienne fenetre ClickFlow si elle est encore ouverte, puis double-cliquer sur `ClickFlow-test-v0.2.4.ahk`.
4. Pour les prochaines mises a jour, recuperer le nouveau script puis fermer l'ancien. Les reglages sont sauvegardes dans `%APPDATA%\ClickFlow\settings.ini`.

Aucune compilation et aucun installateur ClickFlow ne sont necessaires. Ne pas desactiver Smart App Control.

## Ce qui fonctionne dans cette version

- **Fixed** : cadence fixe reglee avec la valeur minimum.
- **Random** : nouvelle cadence entre minimum et maximum.
- **Natural** : variations progressives, niveaux Low / Medium / High.
- Sliders avec retour de valeur **en direct pendant le glissement** et champs de saisie numerique entre 1 et 100 CPS.
- **Profils nommes** : nouveau, renommer, dupliquer, supprimer (en conservant au moins un profil).
- **Sauvegarde par profil** : valeurs CPS, modes, raccourcis et boutons restent enregistres au prochain lancement.
- Le profil actif est restaure automatiquement ; les anciens reglages 0.2.x sont importes dans le profil **Principal**.
- Interface sombre reorganisee en quatre sections : Profils, Cadence, Activation et Etat.
- Trois zones statistiques separees : CPS reels, clics envoyes, touche d'activation.
- Statut colore : vert quand actif, orange en attente du bouton souris, gris quand inactif.
- Bandeau de sauvegarde automatique et meilleurs alignements des boutons.
- Clic gauche, droit ou central, au curseur.
- Bouton **Touche** : capturer une touche clavier ou souris (LButton, RButton, MButton, Mouse 4 et Mouse 5).
- **Hold** : clics tant que la touche est maintenue.
- **Toggle** : un appui active, le suivant desactive.
- Option de maintien supplementaire d'un bouton de souris.
- **Arret au changement de fenetre**, active par defaut.
- **F12** : arret d'urgence, touche reservee.
- Compteur de clics et CPS reels des 1 000 dernieres millisecondes.
- Reglages enregistres automatiquement dans un fichier INI.
- Les clics manuels ne sont pas volontairement interceptes : ils peuvent s'ajouter aux clics generes.

Les touches d'activation sont transmises normalement aux autres applications.

## Premier test recommande

1. Ouvrir un outil de test de clics ou une application de test sur ton PC.
2. Dans ClickFlow, choisir **Fixed**, 5 CPS, bouton **Gauche** et mode **Hold**.
3. Cliquer dans la fenetre de test (pas dans ClickFlow), puis **maintenir F6**.
4. Relacher F6 : les clics doivent s'arreter. Appuyer sur F12 si necessaire.
5. Essayer **Toggle** puis les modes **Random** et **Natural**.
6. Verifier que les clics s'arretent quand tu changes de fenetre.
7. Tester le bouton de capture avec une touche clavier ou Mouse 4 / Mouse 5.

**Attention :** les clics interagissent vraiment avec ce qui se trouve sous le curseur. Commencer avec une cadence basse dans une fenetre de test, jamais sur un bouton dangereux (achat, suppression, validation).

## Limites connues

- La personnalisation graphique avancee et les mises a jour depuis l'interface seront ajoutees plus tard.
- AutoHotkey utilise la precision des minuteries Windows : la cadence mesuree peut etre inferieure a la valeur demandee, notamment vers 60-100 CPS.
- Certains jeux ne reconnaissent pas les clics simules, ou les interdisent dans leurs regles. Aucune garantie d'indetectabilite.
- Pas de prise en charge des applications lancees avec des privileges plus eleves que le script.
- La syntaxe du script est verifiee automatiquement sur Windows par GitHub Actions, mais les interactions avec une souris physique et une application reelle doivent encore etre testees.

## Probleme ?

Si une erreur s'affiche au lancement, envoyer une capture du message et son numero de ligne. Si la fenetre s'ouvre mais que les clics ne partent pas, indiquer le mode, la touche et l'application cible utilises.

## Verification automatique

Le workflow [Validate AutoHotkey v2](.github/workflows/validate-ahk.yml) telecharge l'interpreteur officiel, verifie la syntaxe des scripts et tente un lancement de l'interface sans produire de clics.

Le nom `ClickFlow-test-v0.2.4.ahk` permet de distinguer ce fichier de l'ancienne version en cache ou deja telechargee.

## Tester la persistance

1. Cliquer sur **Nouveau**, donner un nom (exemple : Test 12 CPS).
2. Configurer Fixed, 12 CPS, Toggle et une touche de son choix.
3. Cliquer sur **Dupliquer**, puis **Renommer** sur la copie et changer ses CPS.
4. Basculer entre les profils : leurs valeurs doivent etre independantes.
5. Fermer ClickFlow et rouvrir le nouveau script : le dernier profil actif et toutes les valeurs doivent etre conserves.
6. Supprimer le profil de test puis verifier qu'il ne revient pas au prochain lancement.

Le fichier de sauvegarde est situe dans `%APPDATA%\ClickFlow\settings.ini` sous les sections `[Profiles]` et `[Profile_ID]`. Les anciennes donnees `[ClickFlow]` ne sont pas effacees par la migration.
