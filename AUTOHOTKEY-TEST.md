# ClickFlow AutoHotkey v2 - version experimentale 0.2

**Cette branche est independante de `main`.** La version C# et sa release v0.1.0 restent inchangees.

## Installation et mise a jour

1. Installer AutoHotkey v2 depuis https://www.autohotkey.com/ (une seule fois).
2. Ouvrir [ClickFlow.ahk](ClickFlow.ahk), cliquer sur **Raw**, puis enregistrer le fichier `ClickFlow.ahk`.
3. Fermer l'ancienne fenetre ClickFlow si elle est encore ouverte, puis double-cliquer sur le nouveau `ClickFlow.ahk`.
4. Chaque nouvelle version du script remplace simplement l'ancien fichier. Les reglages sont sauvegardes dans `%APPDATA%\ClickFlow\settings.ini`.

Aucune compilation et aucun installateur ClickFlow ne sont necessaires. Ne pas desactiver Smart App Control.

## Ce qui fonctionne dans cette version

- **Fixed** : cadence fixe reglee avec la valeur minimum.
- **Random** : nouvelle cadence entre minimum et maximum.
- **Natural** : variations progressives, niveaux Low / Medium / High.
- Sliders et champs de saisie numerique entre 1 et 100 CPS.
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

- Les **profils multiples**, la personnalisation graphique avancee et les mises a jour depuis l'interface seront ajoutes plus tard.
- AutoHotkey utilise la precision des minuteries Windows : la cadence mesuree peut etre inferieure a la valeur demandee, notamment vers 60-100 CPS.
- Certains jeux ne reconnaissent pas les clics simules, ou les interdisent dans leurs regles. Aucune garantie d'indetectabilite.
- Pas de prise en charge des applications lancees avec des privileges plus eleves que le script.
- La syntaxe du script est verifiee automatiquement sur Windows par GitHub Actions, mais les interactions avec une souris physique et une application reelle doivent encore etre testees.

## Probleme ?

Si une erreur s'affiche au lancement, envoyer une capture du message et son numero de ligne. Si la fenetre s'ouvre mais que les clics ne partent pas, indiquer le mode, la touche et l'application cible utilises.

## Verification automatique

La workflow [Validate AutoHotkey v2](.github/workflows/validate-ahk.yml) telecharge l'interpreteur officiel et lance `/Validate` sur le script a chaque modification.
