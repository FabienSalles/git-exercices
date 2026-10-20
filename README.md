# Exercice Stash et Reflog

Vous travaillez tranquillement sur une nouvelle fonctionnalité. Rien n'est
terminé, rien n'est commité. Le téléphone sonne : une faute de frappe est
partie en production, il faut la corriger tout de suite.

Cet exercice apprend à mettre son travail de côté, à le retrouver intact,
à réparer un commit posé sur la mauvaise branche, et à récupérer un travail
que l'on croyait perdu.

## Récupérer l'exercice

`git clone -b 05-stash-reflog/main https://github.com/FabienSalles/git-exercices.git 05-stash-reflog`

Puis se placer dans le dossier et vérifier son identité Git :

```bash
cd 05-stash-reflog
git config user.name
git config user.email
git log --oneline --graph --branches
```

L'historique de départ contient 5 commits.

## 1. Commencer un travail, sans le terminer

Créer le fichier `yaml/velo.yaml` avec le contenu suivant :

```
velo:
  marque: Look
  modele: 576
```

Ajouter la ligne `  couleur: rouge` à la fin de `yaml/voiture.yaml`.

Ne rien indexer, ne rien commiter. Vérifier l'état :

```bash
git status
```

Un fichier est `modified`, l'autre est `untracked`. Retenir cette différence,
la suite en dépend.

## 2. Le hotfix tombe : mettre le travail de côté

```bash
git stash push -m "wip: velo et couleur voiture"
git status --short
```

Le fichier `yaml/velo.yaml` est **toujours là** :

```
?? yaml/velo.yaml
```

`git stash` ne met de côté que les fichiers **suivis par Git**. Un fichier
non suivi reste sur le disque.

Reprendre le travail, puis recommencer avec l'option `-u` (_untracked_) :

```bash
git stash pop
git stash push -u -m "wip: velo et couleur voiture"
git status --short
ls yaml
```

Cette fois `git status --short` n'affiche plus rien et `yaml/velo.yaml` a
disparu du dossier. Le répertoire de travail est propre.

## 3. Regarder ce qu'il y a dans le stash

```bash
git stash list
git stash show stash@{0}
git stash show -p stash@{0}
git stash show -p -u stash@{0}
```

Sorties attendues :

```
stash@{0}: On 05-stash-reflog/main: wip: velo et couleur voiture
```

```
 yaml/voiture.yaml | 1 +
 1 file changed, 1 insertion(+)
```

Attention : sans `-u`, `git stash show` n'affiche pas les fichiers non suivis
qui sont pourtant bien dans le stash. Comparer les deux dernières commandes.

## 4. Corriger le hotfix

Dans `yaml/contact.yaml`, corriger la ville : `Boreaux` devient `Bordeaux`.

```bash
git add yaml/contact.yaml
git commit -m "fix(contact): ville Bordeaux"
```

## 5. Reprendre son travail

```bash
git stash pop
git status --short
git stash list
```

Sortie attendue :

```
 M yaml/voiture.yaml
?? yaml/velo.yaml
```

`git stash list` ne renvoie plus rien : `pop` applique **et** supprime le stash.

## 6. Mettre de côté un seul fichier

Mettre de côté uniquement la modification de `yaml/voiture.yaml` :

```bash
git stash push -m "wip: couleur voiture" -- yaml/voiture.yaml
git status --short
```

Sortie attendue, seul le vélo reste dans le répertoire de travail :

```
?? yaml/velo.yaml
```

Puis récupérer avec `apply` au lieu de `pop` :

```bash
git stash apply
git stash list
```

Le stash est appliqué **et** toujours présent dans la liste. C'est la
différence entre `apply` et `pop`.

Relancer `git stash apply` une seconde fois :

```
error: Your local changes to the following files would be overwritten by merge:
	yaml/voiture.yaml
Please commit your changes or stash them before you merge.
Aborting
```

Un stash appliqué deux fois entre en conflit avec lui-même. Le supprimer :

```bash
git stash drop
git stash list
```

## 7. Repartir du stash sur une branche dédiée

Tout ce travail n'a rien à faire sur `05-stash-reflog/main`. Le remettre de
côté, puis demander à Git de créer une branche à partir du stash :

```bash
git stash push -u -m "wip: velo"
git stash branch 05-stash-reflog/feat/velo
```

Sortie attendue :

```
Switched to a new branch '05-stash-reflog/feat/velo'
...
	modified:   yaml/voiture.yaml
...
	yaml/velo.yaml
Dropped refs/stash@{0} (5fe5e4b...)
```

`git stash branch` crée la branche au commit où le stash a été fait, applique
le stash, et le supprime. Commiter :

```bash
git add yaml/velo.yaml yaml/voiture.yaml
git commit -m "feat: velo.yaml et couleur voiture"
git log --oneline --graph --branches
```

## 8. « J'ai oublié de faire une branche »

Retourner sur la branche principale et commiter par erreur deux commits qui
auraient dû aller sur une branche de fonctionnalité :

```bash
git switch 05-stash-reflog/main
```

Créer `yaml/moto.yaml` :

```
moto:
  marque: Yamaha
  modele: MT-07
```

```bash
git add yaml/moto.yaml
git commit -m "feat: moto.yaml"
```

Ajouter la ligne `  couleur: bleu` à la fin de `yaml/moto.yaml`, puis :

```bash
git commit -am "feat(moto): couleur"
git log --oneline --graph --branches
```

Deux commits sont sur la branche principale. Une branche n'est qu'une
étiquette : il suffit d'en poser une ici, puis de reculer la principale.

```bash
git branch 05-stash-reflog/feat/moto
git reset --soft HEAD~2
git status
```

Sortie attendue après le `reset --soft` : la branche principale est revenue
en arrière, mais les fichiers sont toujours là, indexés.

```
On branch 05-stash-reflog/main
Changes to be committed:
	new file:   yaml/moto.yaml
```

```bash
git switch 05-stash-reflog/feat/moto
git status
git log --oneline --graph --branches
```

Sortie attendue :

```
On branch 05-stash-reflog/feat/moto
nothing to commit, working tree clean
```

Les deux commits sont maintenant sur la bonne branche.

## 9. Le filet de sécurité : retrouver un commit après un `reset --hard`

Ajouter la ligne `  annee: 2021` à la fin de `yaml/moto.yaml`, puis :

```bash
git commit -am "feat(moto): annee"
git log --oneline -3
```

Se tromper volontairement de commande, en croyant seulement désindexer :

```bash
git reset --hard HEAD~1
git log --oneline -3
cat yaml/moto.yaml
```

Le commit a disparu du log, et la ligne `annee` a disparu du fichier.

Demander à Git ses dernières positions :

```bash
git reflog
```

Sortie attendue (les hashes seront différents) :

```
8fa6e65 HEAD@{0}: reset: moving to HEAD~1
fcc20f6 HEAD@{1}: commit: feat(moto): annee
8fa6e65 HEAD@{2}: checkout: moving from 05-stash-reflog/main to 05-stash-reflog/feat/moto
3abb77a HEAD@{3}: reset: moving to HEAD~2
```

Le commit perdu est la ligne `commit: feat(moto): annee`. Le récupérer en
utilisant **son hash**, celui affiché sur votre machine, plus sûr que la
notation relative qui se décale à chaque nouvelle action :

```bash
git reset --hard fcc20f6
git log --oneline -2
cat yaml/moto.yaml
```

## 10. Retrouver un commit après un `--amend` malencontreux

Ajouter la ligne `  poids: 182` à la fin de `yaml/moto.yaml`, puis se tromper
en écrasant le commit précédent au lieu d'en créer un nouveau :

```bash
git add yaml/moto.yaml
git commit --amend -m "feat(moto): annee et poids"
git log --oneline -2
```

Le commit `feat(moto): annee` n'existe plus : il a été remplacé.

```bash
git reflog
```

```
d51aefb HEAD@{0}: commit (amend): feat(moto): annee et poids
fcc20f6 HEAD@{1}: reset: moving to fcc20f6
```

`HEAD@{1}` est la position juste avant l'amend. Revenir dessus en gardant
les modifications indexées :

```bash
git reset --soft HEAD@{1}
git log --oneline -2
git status --short
git diff --cached
```

Sortie attendue : le commit d'origine est de retour, et la ligne `poids`
est toujours indexée, prête à être commitée proprement.

```
M  yaml/moto.yaml
```

```bash
git commit -m "feat(moto): poids"
git log --oneline -3
```

## 11. Retrouver une branche supprimée

```bash
git switch 05-stash-reflog/main
git branch -d 05-stash-reflog/feat/moto
```

Git refuse :

```
error: the branch '05-stash-reflog/feat/moto' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D 05-stash-reflog/feat/moto'
```

Forcer la suppression :

```bash
git branch -D 05-stash-reflog/feat/moto
git branch
git log --oneline --graph --branches
```

Sortie attendue, avec le hash à retenir :

```
Deleted branch 05-stash-reflog/feat/moto (was 1a8110b).
```

La branche a disparu, les commits aussi du `git log`. Le reflog de la branche
supprimée n'existe plus non plus :

```bash
git reflog show 05-stash-reflog/feat/moto
```

```
fatal: ambiguous argument '05-stash-reflog/feat/moto': unknown revision or path not in the working tree.
```

Mais le reflog de `HEAD`, lui, est toujours là :

```bash
git reflog
```

```
3abb77a HEAD@{0}: checkout: moving from 05-stash-reflog/feat/moto to 05-stash-reflog/main
1a8110b HEAD@{1}: commit: feat(moto): poids
```

Recréer la branche sur ce commit, avec le hash affiché sur votre machine :

```bash
git switch -c 05-stash-reflog/feat/moto 1a8110b
git log --oneline --graph --branches
```

## Résultat attendu

```
* 1a8110b (HEAD -> 05-stash-reflog/feat/moto) feat(moto): poids
* fcc20f6 feat(moto): annee
* 8fa6e65 feat(moto): couleur
* 535919d feat: moto.yaml
| * d6bc9eb (05-stash-reflog/feat/velo) feat: velo.yaml et couleur voiture
|/
* 3abb77a (05-stash-reflog/main) fix(contact): ville Bordeaux
* 3e63cb1 (origin/05-stash-reflog/main) docs: enonce de l exercice
* 305a2d2 feat: societe.yaml
* b67c0e0 feat: voiture.yaml
* 7d8ee53 feat: contact.yaml
* 13c75d8 initial commit
```

Les hashes seront différents. La forme du graphe, elle, doit être identique :
deux branches de fonctionnalité qui partent du commit de hotfix, et une
branche principale qui ne contient que le hotfix.

Vérifier également que plus aucun stash ne traîne :

```bash
git stash list
```

## Bonus : un `stash pop` en conflit

Modifier la ville de `yaml/societe.yaml` en `Lyon`, mettre de côté, puis
modifier la même ligne en `Nantes` et commiter :

```bash
git stash push -m "wip: societe lyon"
git commit -am "fix(societe): ville Nantes"
git stash pop
```

```
Auto-merging yaml/societe.yaml
CONFLICT (content): Merge conflict in yaml/societe.yaml
...
The stash entry is kept in case you need it again.
```

Résoudre le conflit dans le fichier, puis :

```bash
git add yaml/societe.yaml
git stash list
```

Le stash est **toujours là** : quand `pop` échoue, Git ne supprime rien. Il
faut le supprimer à la main une fois la résolution vérifiée :

```bash
git stash drop
```

## À retenir

* `git stash` ignore les fichiers non suivis : penser à `-u`.
* `pop` = appliquer et supprimer, `apply` = appliquer et conserver.
* Un stash n'est pas une sauvegarde : il est local, non poussé, et sans nom
  si on oublie `-m`.
* Une branche n'est qu'une étiquette : on peut en poser une après coup.
* Tant qu'un commit a existé sur la machine, `git reflog` sait où il est,
  pendant 90 jours par défaut.
