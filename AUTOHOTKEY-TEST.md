# ClickFlow - Test AutoHotkey v2

Cette branche est experimentale. Elle **ne modifie pas** la version C# de `main`.

## But du premier test

Verifier que Windows 11 et Smart App Control autorisent **AutoHotkey v2** et l'ouverture d'une interface ClickFlow faite en script. Le prototype ne produit aucun clic, ne definit aucun raccourci global, n'envoie aucune donnee et ne modifie pas les reglages du PC.

## Etapes

1. Installer **AutoHotkey v2**, depuis le site officiel : https://www.autohotkey.com/
2. Ouvrir `ClickFlow.ahk` sur GitHub dans cette branche.
3. Cliquer sur **Raw**, enregistrer la page avec le nom exact `ClickFlow.ahk` (pas `.txt`).
4. Double-cliquer sur `ClickFlow.ahk`.
5. Si la fenetre s'affiche, essayer le curseur CPS et le bouton **Tester les controles**.

Si le fichier est ouvert dans le Bloc-notes, utiliser **Ouvrir avec > AutoHotkey v2**. Si Windows le bloque, noter le message exact. Ne pas desactiver Smart App Control pour ce test.

## Limites de ce prototype

- Ce n'est **pas encore un autoclicker fonctionnel**.
- L'interface AutoHotkey native est un premier apercu : le design final pourra etre plus soigne.
- Le CPS saisi est une valeur de demonstration uniquement.
- Une execution correcte du prototype ne garantit pas que les futures fonctions de clic seront acceptees dans tous les jeux.

## Plan si le test fonctionne

Construire progressivement les profils, les modes de clics, les raccourcis configurables et les variantes de CPS, sans toucher a `main` tant que la version AutoHotkey n'est pas validee.
