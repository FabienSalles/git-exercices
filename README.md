# Cherry-pick et revert : propager un correctif en production, annuler proprement ce qui est déjà publié

> Un correctif fait en développement doit partir en production tout de suite sans emmener le reste du travail en cours, et dans la foulée un commit déjà poussé sur la production s'avère fautif et doit être annulé sans réécrire l'historique de personne.

**Niveau** : intermédiaire | **Durée estimée** : 55 min

## Prérequis

- Jour 1 terminé : branches, `git switch`, merge fast-forward / `--no-ff` / true merge, résolution d'un conflit avec les marqueurs et `git add`
- Savoir lire `git log --oneline --graph --branches` et désigner un commit par son empreinte courte ou par `HEAD~1`
- Un éditeur configuré (`core.editor`), vu au chapitre `day-1/slides/03-configuration.md`
- Git >= 2.23 pour `git switch` ; testé sur Git 2.54.0
- Accès réseau à github.com pour le clone, ou la variante hors ligne décrite plus bas

## 0. Récupérer le dépôt et se repérer

Un correctif urgent a été fait sur la branche de développement. Il doit partir en production tout de suite, sans emmener le reste du travail en cours. Par ailleurs, un commit déjà publié sur la production s'avère fautif et devra être annulé.

Deux branches sont fournies : `06-cherry-pick-revert/main` est la production, déjà publiée, que personne n'a le droit de réécrire ; `06-cherry-pick-revert/dev` est la branche de développement.

Cloner le dépôt, créer la branche locale de développement, puis revenir sur la production et regarder l'historique des deux branches.

Les empreintes citées dans cet énoncé sont celles du dépôt fourni : elles seront identiques chez vous. Les commits que vous créerez, eux, auront des empreintes différentes des exemples. Dans les sorties attendues, `xxxxxxx` remplace l'empreinte du commit `docs: ajoute l'enonce de l'exercice`, la seule qui ne soit pas figée puisqu'elle dépend du contenu de ce fichier.

```bash
git clone -b 06-cherry-pick-revert/main https://github.com/FabienSalles/git-exercices.git 06-cherry-pick-revert
cd 06-cherry-pick-revert
git switch 06-cherry-pick-revert/dev
git switch 06-cherry-pick-revert/main
git log --oneline --graph --branches
```

Résultat attendu :

```
* xxxxxxx (HEAD -> 06-cherry-pick-revert/main, origin/06-cherry-pick-revert/main) docs: ajoute l'enonce de l'exercice
* 07e9461 feat(voiture): ajoute la boite automatique
* fb168a5 fix(societe): corrige la ville du siege
| * 62befef (origin/06-cherry-pick-revert/dev, 06-cherry-pick-revert/dev) feat(societe): ajoute le siret
| * 16efbd6 fix(societe): corrige le nom
| * 2b3f153 feat(velo): ajoute le nombre de vitesses
| * 5ab49e9 fix(contact): corrige la ville
| * 10dd6e7 feat(velo): ajoute velo.yaml
|/
* 9c11c1e feat: societe.yaml
* 9b16e89 feat: voiture.yaml
* 779744d feat: contact.yaml
* 3377406 chore: commit initial

Les deux branches ont divergé au commit 9c11c1e.
```

> **Question** : Sur quel commit les deux branches se séparent-elles, et comment le lit-on sur ce graphe ? Si on fusionnait maintenant `dev` dans `main`, combien de commits partiraient en production ?

## 1. Propager un seul commit avec git cherry-pick

Lister d'abord ce que la production n'a pas encore. La notation `A..B` se lit « ce qui est dans B et pas dans A ».

Le correctif urgent est `5ab49e9 fix(contact): corrige la ville`. C'est le seul qui doit partir. Rester sur `06-cherry-pick-revert/main` et le reprendre.

Comparer ensuite l'empreinte du commit créé avec celle de `5ab49e9`, puis regarder qui en est l'auteur et qui en est le committeur.

```bash
git log --oneline 06-cherry-pick-revert/main..06-cherry-pick-revert/dev
git cherry-pick 5ab49e9
git log -1 --format='auteur : %an / %ad%ncommitteur : %cn / %cd' --date=short
cat yaml/contact.yaml
```

Résultat attendu :

```
62befef feat(societe): ajoute le siret
16efbd6 fix(societe): corrige le nom
2b3f153 feat(velo): ajoute le nombre de vitesses
5ab49e9 fix(contact): corrige la ville
10dd6e7 feat(velo): ajoute velo.yaml

[06-cherry-pick-revert/main 6260106] fix(contact): corrige la ville
 Author: ConveyCode Formation <formation@conveycode.fr>
 Date: Tue Jan 6 11:30:00 2026 +0100
 1 file changed, 1 insertion(+), 1 deletion(-)

auteur : ConveyCode Formation / 2026-01-06
committeur : Participant / 2026-08-11

contact:
  prenom: Jean
  nom: Dupont
  ville: Bordeaux

(6260106 est l'empreinte obtenue lors du test, la vôtre sera différente)
```

> **Question** : Le commit créé porte une empreinte différente de 5ab49e9 alors que le changement est identique. Pourquoi ? Et pourquoi l'auteur est-il resté celui d'origine alors que le committeur est vous ?

## 2. Tracer l'origine avec l'option -x

Le message du commit ne dit nulle part d'où il vient. Dans six mois, personne ne pourra relier le commit de production au commit de développement.

Comme ce commit n'a jamais été publié, il est encore légitime de le défaire avec `reset --hard`. Refaire ensuite le cherry-pick en traçant l'origine, puis afficher le message complet.

```bash
git reset --hard HEAD~1
git cherry-pick -x 5ab49e9
git show -s --format=%B HEAD
```

Résultat attendu :

```
HEAD is now at xxxxxxx docs: ajoute l'enonce de l'exercice

[06-cherry-pick-revert/main 607d8fd] fix(contact): corrige la ville
 Author: ConveyCode Formation <formation@conveycode.fr>
 Date: Tue Jan 6 11:30:00 2026 +0100
 1 file changed, 1 insertion(+), 1 deletion(-)

fix(contact): corrige la ville

(cherry picked from commit 5ab49e9b7ae3e6817dec4c34cac48e5fdd436665)
```

> **Question** : Le `reset --hard` vient d'être utilisé sans aucun danger. Qu'est-ce qui rend cette commande acceptable ici, et qu'est-ce qui la rendrait inacceptable trois commits plus loin dans cet exercice ?

## 3. Propager une plage de commits A..B et gérer le conflit

Les commits `16efbd6` et `62befef` forment un ensemble cohérent qui doit partir en bloc. Une plage `A..B` en Git est ouverte à gauche : `A` est exclu, `B` est inclus. Pour reprendre `16efbd6` et `62befef`, il faut donc désigner comme borne gauche leur prédécesseur `2b3f153`.

Le cherry-pick va s'arrêter sur un conflit : la production a modifié la ville du siège, le développement a modifié le nom, sur des lignes voisines. Éditer `yaml/societe.yaml` pour garder les deux corrections, c'est-à-dire le nouveau nom et la ville de production, puis marquer le conflit résolu et poursuivre.

En cas de doute à tout moment : `git cherry-pick --abort` remet tout dans l'état d'avant, `git cherry-pick --skip` abandonne le commit en cours et passe au suivant.

```bash
git cherry-pick -x 2b3f153..62befef
git status
cat yaml/societe.yaml
# éditer yaml/societe.yaml pour obtenir :
#   societe:
#     nom: Orange Business
#     ville: Montrouge
#     effectif: 75000
#     activite: telecom
#     pays: France
git add yaml/societe.yaml
git cherry-pick --continue --no-edit
```

Résultat attendu :

```
Auto-merging yaml/societe.yaml
CONFLICT (content): Merge conflict in yaml/societe.yaml
error: could not apply 16efbd6... fix(societe): corrige le nom
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".

Contenu en conflit de yaml/societe.yaml :

societe:
<<<<<<< HEAD
  nom: Orange
  ville: Montrouge
=======
  nom: Orange Business
  ville: Guyancourt
>>>>>>> 16efbd6 (fix(societe): corrige le nom)
  effectif: 75000
  activite: telecom
  pays: France

Après résolution :

[06-cherry-pick-revert/main df55b84] fix(societe): corrige le nom
 1 file changed, 1 insertion(+), 1 deletion(-)
Auto-merging yaml/societe.yaml
[06-cherry-pick-revert/main 8b01db0] feat(societe): ajoute le siret
 1 file changed, 1 insertion(+)
```

> **Question** : Un seul des deux commits de la plage a produit un conflit, l'autre s'est appliqué tout seul. Pourquoi ? Et si la plage avait contenu dix commits dont cinq conflictuels, combien de fois faudrait-il taper `--continue` ?

## 4. Constater le duplicata au futur merge

Avant de fusionner, demander à Git ce qui est déjà présent en production. `git cherry` compare les changements et non les empreintes : `-` signifie « ce changement est déjà là », `+` signifie « il n'y est pas ».

Fusionner ensuite la branche de développement dans la production. Le même conflit qu'à l'étape 3 va revenir : le résoudre de la même façon en gardant `ville: Montrouge`, puis committer la fusion et regarder l'historique.

```bash
git cherry -v 06-cherry-pick-revert/main 06-cherry-pick-revert/dev
git merge --no-ff 06-cherry-pick-revert/dev
# résoudre yaml/societe.yaml en gardant nom: Orange Business et ville: Montrouge
# et en conservant la ligne siret
git add yaml/societe.yaml
git commit --no-edit
git log --oneline --graph --branches
```

Résultat attendu :

```
+ 10dd6e759270e0b1fd40396ce41139daf09b9362 feat(velo): ajoute velo.yaml
- 5ab49e9b7ae3e6817dec4c34cac48e5fdd436665 fix(contact): corrige la ville
+ 2b3f153fc6046224f2ece22feae89da17faac856 feat(velo): ajoute le nombre de vitesses
+ 16efbd67dab815a25748af5d6dc3fe85408b42be fix(societe): corrige le nom
- 62befefef9caee1647d94406aef151634956fe32 feat(societe): ajoute le siret

Auto-merging yaml/societe.yaml
CONFLICT (content): Merge conflict in yaml/societe.yaml
Automatic merge failed; fix conflicts and then commit the result.

Après résolution :

*   48981f5 (HEAD -> 06-cherry-pick-revert/main) Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main
|\
| * 62befef (origin/06-cherry-pick-revert/dev, 06-cherry-pick-revert/dev) feat(societe): ajoute le siret
| * 16efbd6 fix(societe): corrige le nom
| * 2b3f153 feat(velo): ajoute le nombre de vitesses
| * 5ab49e9 fix(contact): corrige la ville
| * 10dd6e7 feat(velo): ajoute velo.yaml
* | 8b01db0 feat(societe): ajoute le siret
* | df55b84 fix(societe): corrige le nom
* | 607d8fd fix(contact): corrige la ville
* | xxxxxxx (origin/06-cherry-pick-revert/main) docs: ajoute l'enonce de l'exercice
* | 07e9461 feat(voiture): ajoute la boite automatique
* | fb168a5 fix(societe): corrige la ville du siege
|/
* 9c11c1e feat: societe.yaml
* 9b16e89 feat: voiture.yaml
* 779744d feat: contact.yaml
* 3377406 chore: commit initial

Trois messages apparaissent deux fois dans l'historique. Le contenu, lui, n'est appliqué qu'une seule fois.
```

> **Question** : `16efbd6` est marqué `+` par `git cherry` alors qu'il a bien été cherry-piqué à l'étape 3. Qu'est-ce qui a changé son contenu au point que Git ne le reconnaisse plus ? Et quel est le lien direct entre cette réponse et le fait d'avoir dû résoudre deux fois le même conflit ?

## 5. Annuler un commit publié : reset ou revert ?

Le commit `07e9461 feat(voiture): ajoute la boite automatique` est fautif. Il est déjà publié sur `origin`.

Regarder d'abord ce que ferait un `reset`, sur une branche jetable pour ne rien casser. Puis revenir et supprimer cette branche de démonstration.

Annuler ensuite proprement, en ajoutant un commit qui défait le précédent.

```bash
git switch -c demo-reset
git reset --hard 07e9461~1
git log --oneline -3
cat yaml/voiture.yaml
git switch 06-cherry-pick-revert/main
git branch -D demo-reset
git revert 07e9461
cat yaml/voiture.yaml
git show -s --format=%B HEAD
```

Résultat attendu :

```
HEAD is now at fb168a5 fix(societe): corrige la ville du siege
fb168a5 fix(societe): corrige la ville du siege
9c11c1e feat: societe.yaml
9b16e89 feat: voiture.yaml

voiture:
  marque: Renault
  modele: Clio

Deleted branch demo-reset (was fb168a5).

[06-cherry-pick-revert/main d3c84fd] Revert "feat(voiture): ajoute la boite automatique"
 1 file changed, 1 deletion(-)

voiture:
  marque: Renault
  modele: Clio

Revert "feat(voiture): ajoute la boite automatique"

This reverts commit 07e9461691c5c72ed5532e471f06d7ea6c9a7e03.
```

> **Question** : Le `reset --hard` a effacé bien plus que le commit fautif : qu'a-t-il emporté au passage, et pourquoi ? Le revert produit exactement le même contenu de `voiture.yaml` : quelle est alors la seule différence, et pourquoi est-elle décisive sur une branche que trois collègues ont déjà clonée ?

## 6. Annuler une fusion avec git revert -m 1

Le responsable produit change d'avis : la fonctionnalité vélo ne doit pas partir. Il faut annuler le commit de fusion créé à l'étape 4 (remplacer `48981f5` par votre empreinte, lisible avec `git log --oneline --merges -1`).

Essayer d'abord sans option, lire l'erreur, puis désigner le premier parent.

```bash
git log --oneline --merges -1
git revert 48981f5
git revert -m 1 48981f5
ls yaml/
```

Résultat attendu :

```
error: commit 48981f52aef56a084b6ee562d617662c9a8e5a8e is a merge but no -m option was given.
fatal: revert failed

[06-cherry-pick-revert/main 22f0195] Revert "Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main"
 1 file changed, 4 deletions(-)
 delete mode 100644 yaml/velo.yaml

contact.yaml
societe.yaml
voiture.yaml
```

> **Question** : Le revert du merge n'a supprimé qu'un seul fichier, `velo.yaml`, alors que la branche `dev` contenait cinq commits. Pourquoi le reste n'a-t-il pas disparu ? Et que se serait-il passé avec `-m 2` au lieu de `-m 1` ?

## 7. Le piège : annuler l'annulation

Nouveau revirement, la fonctionnalité vélo repart. Tenter simplement de refusionner la branche de développement, constater le résultat, puis trouver la vraie solution.

```bash
git merge 06-cherry-pick-revert/dev
ls yaml/
git revert 22f0195
ls yaml/
cat yaml/velo.yaml
```

Résultat attendu :

```
Already up to date.

contact.yaml
societe.yaml
voiture.yaml

[06-cherry-pick-revert/main d1cdf30] Reapply "Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main"
 1 file changed, 4 insertions(+)
 create mode 100644 yaml/velo.yaml

contact.yaml
societe.yaml
velo.yaml
voiture.yaml

velo:
  marque: Look
  modele: 576
  vitesses: 22
```

> **Question** : Git répond `Already up to date.` alors que `velo.yaml` n'est pas là. Que regarde Git exactement pour décider qu'il n'a rien à fusionner ? Quelle règle d'équipe cet incident impose-t-il quand on annule une fusion sur une branche partagée ?

## 8. Bonus hors ligne : la preuve par le push

Cette partie ne nécessite ni compte ni réseau. Fabriquer un serveur Git local, y publier la production, puis comparer ce que `reset` et `revert` autorisent au moment de publier.

```bash
cd ..
git init --bare serveur.git
cd 06-cherry-pick-revert
git remote add serveur ../serveur.git
git push serveur 06-cherry-pick-revert/main
git switch -c test-reset
git reset --hard HEAD~1
git push serveur test-reset:06-cherry-pick-revert/main
git switch 06-cherry-pick-revert/main
git branch -D test-reset
git revert --no-edit HEAD
git push serveur 06-cherry-pick-revert/main
git reset --hard HEAD~1
git remote remove serveur
```

Résultat attendu :

```
Après le reset :

To ../serveur.git
 ! [rejected]        test-reset -> 06-cherry-pick-revert/main (non-fast-forward)
error: failed to push some refs to '../serveur.git'
hint: Updates were rejected because a pushed branch tip is behind its remote
hint: counterpart. If you want to integrate the remote changes, use 'git pull'
hint: before pushing again.

Après le revert :

To ../serveur.git
   d1cdf30..d769a81  06-cherry-pick-revert/main -> 06-cherry-pick-revert/main
```

> **Question** : Le push après reset est refusé avec la mention `non-fast-forward`. Quelle option permettrait de passer en force, et qu'est-ce qu'elle ferait perdre aux collègues qui ont déjà tiré la branche ? Pourquoi le revert, lui, passe-t-il sans aucune option ?

## Résultat final attendu

```
Sortie réelle obtenue en sandbox à la fin de l'étape 7 (`git log --oneline --graph --branches` puis `git status --short`) :

* d1cdf30 (HEAD -> 06-cherry-pick-revert/main) Reapply "Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main"
* 22f0195 Revert "Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main"
* d3c84fd Revert "feat(voiture): ajoute la boite automatique"
*   48981f5 Merge branch '06-cherry-pick-revert/dev' into 06-cherry-pick-revert/main
|\
| * 62befef (origin/06-cherry-pick-revert/dev, 06-cherry-pick-revert/dev) feat(societe): ajoute le siret
| * 16efbd6 fix(societe): corrige le nom
| * 2b3f153 feat(velo): ajoute le nombre de vitesses
| * 5ab49e9 fix(contact): corrige la ville
| * 10dd6e7 feat(velo): ajoute velo.yaml
* | 8b01db0 feat(societe): ajoute le siret
* | df55b84 fix(societe): corrige le nom
* | 607d8fd fix(contact): corrige la ville
* | 9e7445d (origin/06-cherry-pick-revert/main) docs: ajoute l'enonce de l'exercice
* | 07e9461 feat(voiture): ajoute la boite automatique
* | fb168a5 fix(societe): corrige la ville du siege
|/
* 9c11c1e feat: societe.yaml
* 9b16e89 feat: voiture.yaml
* 779744d feat: contact.yaml
* 3377406 chore: commit initial

`git status --short` ne renvoie rien : l'arbre de travail est propre.

Contenu final des quatre fichiers :

yaml/contact.yaml
contact:
  prenom: Jean
  nom: Dupont
  ville: Bordeaux

yaml/societe.yaml
societe:
  nom: Orange Business
  ville: Montrouge
  effectif: 75000
  activite: telecom
  pays: France
  siret: 38012986439999

yaml/velo.yaml
velo:
  marque: Look
  modele: 576
  vitesses: 22

yaml/voiture.yaml
voiture:
  marque: Renault
  modele: Clio

Les empreintes 5ab49e9, 2b3f153, 16efbd6, 62befef, 10dd6e7, 07e9461, fb168a5, 9c11c1e, 9b16e89, 779744d et 3377406 sont celles que tous les participants auront. Les empreintes 607d8fd, df55b84, 8b01db0, 48981f5, d3c84fd, 22f0195 et d1cdf30 sont celles créées pendant le test et seront différentes chez chacun.
```

## Critères de réussite

- `git log --oneline --graph --branches` montre un historique où trois messages apparaissent deux fois : `fix(contact): corrige la ville`, `fix(societe): corrige le nom` et `feat(societe): ajoute le siret`, une fois sur la ligne de `dev` et une fois sur celle de `main`
- Les trois commits repris sur `main` portent tous la ligne `(cherry picked from commit ...)` dans leur message, vérifiable par `git log --format='%h %s%n%b' -3 <sha_du_merge>^`
- Le commit de fusion est présent, avec deux parents, vérifiable par `git log --oneline --merges` qui renvoie exactement une ligne
- Les trois derniers commits de `main` sont, dans cet ordre du plus ancien au plus récent : `Revert "feat(voiture): ajoute la boite automatique"`, `Revert "Merge branch ..."`, puis un commit qui réapplique la fusion (`Reapply "Merge branch ..."` sur Git récent)
- Le commit fautif `07e9461 feat(voiture): ajoute la boite automatique` est toujours présent dans l'historique : rien n'a été réécrit
- `yaml/voiture.yaml` ne contient plus la ligne `boite: automatique`
- `yaml/societe.yaml` contient à la fois `nom: Orange Business`, `ville: Montrouge` et `siret: 38012986439999` : les deux corrections concurrentes ont été conservées
- `yaml/velo.yaml` existe et contient `vitesses: 22` : la fonctionnalité est bien revenue après le revert du revert
- `git status --short` ne renvoie rien : aucun conflit résiduel, aucun fichier oublié dans l'index
- Le participant sait répondre à l'oral : pourquoi `reset` est interdit ici et `revert` autorisé, et pourquoi `git merge` répond `Already up to date.` à l'étape 7

## Variantes

- Hors ligne complet, sans GitHub et sans compte : le formateur exécute `setup.sh` sur son poste, puis distribue le dépôt fabriqué. Deux façons de le faire. Soit par clé USB / partage réseau en copiant le dossier `06-cherry-pick-revert` produit par le script, chaque participant faisant ensuite `git clone <chemin_partage>/06-cherry-pick-revert mon-exercice` puis `git switch 06-cherry-pick-revert/dev` et `git switch 06-cherry-pick-revert/main`. Soit par un fichier unique avec `git bundle create 06-cherry-pick-revert.bundle --all` côté formateur, et `git clone -b 06-cherry-pick-revert/main 06-cherry-pick-revert.bundle mon-exercice` côté participant. Dans les deux cas, l'énoncé est intégralement jouable : rien dans l'exercice n'exige un serveur distant, et l'étape bonus fabrique son propre dépôt nu.
- Poste verrouillé, sans droit d'installation : aucun logiciel n'est nécessaire au-delà de Git lui-même. Aucun outil tiers, aucun `gh`, aucun accès à une forge. Le seul point d'attention est l'éditeur : si le poste n'a que le Bloc-notes, configurer `git config --global core.editor notepad` avant l'exercice, ou s'appuyer sur les `--no-edit` déjà présents dans l'énoncé.
- Groupe en avance, extension de 15 minutes : rejouer l'étape 3 en choisissant volontairement `git cherry-pick --skip` sur le commit conflictuel, constater que seul le commit `feat(societe): ajoute le siret` arrive et que `yaml/societe.yaml` se retrouve incohérent (siret présent, nom pas corrigé) ; puis `git reset --hard origin/06-cherry-pick-revert/main` et refaire proprement. Ajouter ensuite `git log --oneline --cherry-mark --left-right 06-cherry-pick-revert/main...06-cherry-pick-revert/dev` (trois points) et faire lire les marqueurs `=`, `<`, `>`.
- Groupe en retard ou séance comprimée à 35 minutes : supprimer les étapes 2 (option -x, à énoncer oralement) et 8 (bonus push, à faire en démonstration formateur en trois minutes), et fournir la résolution de conflit de l'étape 3 déjà écrite au tableau. Le cœur non négociable reste les étapes 3, 4, 5, 6 et 7.
- Groupe très débutant : jouer les étapes 5 à 7 en démonstration formateur au vidéoprojecteur, et ne laisser en autonomie que les étapes 0 à 4. La partie revert est celle qui demande le plus de recul sur le graphe et c'est aussi celle qui se démontre le mieux collectivement.
- Windows sans Git Bash, uniquement PowerShell : toutes les commandes fonctionnent telles quelles, à l'exception des blocs `cat > fichier <<'YAML'` de la correction, qui sont du shell POSIX. Remplacer l'écriture des fichiers par l'éditeur, ce que fait de toute façon le participant.
