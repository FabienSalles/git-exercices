# Exercice Collaboration sans forge

Cet exercice simule une équipe de deux personnes, **Alice** et **Bob**, qui
travaillent sur le même projet à travers un dépôt de partage. Tout se passe
sur un seul poste, sans réseau, sans compte GitHub, sans GitLab.

Le « serveur » sera un simple dossier : un **dépôt nu** (_bare_). C'est
exactement ce qu'est un dépôt GitHub, sans l'interface web.

## Comment jouer

Deux façons, au choix :

- **En binôme** : une personne tient le poste d'Alice, l'autre celui de Bob,
  sur la même machine, chacun dans un terminal.
- **En solo** : ouvrir **deux terminaux**, un par poste, et ne jamais les
  mélanger. Le prompt affiche le dossier courant : c'est votre garde-fou.

Dans tout l'énoncé, la balise **[ALICE]** ou **[BOB]** indique dans quel
terminal taper la commande.

**Les SHA affichés dans cet énoncé** (`65fe95c`, `d6ba0d6`…) sont ceux d'une
session de référence. Les commits étant créés sur votre poste, **les vôtres
seront différents** : un SHA dépend aussi de l'auteur et de la date. Seules la
**forme** du graphe et les messages doivent correspondre. Les chemins sont
abrégés en `.../atelier/...` : vous verrez votre chemin complet.

## Récupérer l'énoncé

```bash
git clone -b 09-collab-local https://github.com/FabienSalles/git-exercices.git 09-collab-local
cd 09-collab-local
```

Sans réseau, le formateur fournit ce dossier sur clé USB ou sur un partage.

Un script `rattrapage.sh` est fourni : il reconstruit tout l'atelier jusqu'à
la fin de l'étape 4. À n'utiliser qu'en cas de blocage.

---

## Étape 1 : fabriquer le serveur

Créer le dossier de l'atelier puis le dépôt de partage.

```bash
mkdir atelier
cd atelier
git init --bare -b main central.git
```

Sortie attendue :

```
Initialized empty Git repository in .../atelier/central.git/
```

Regarder ce que contient ce dépôt :

```bash
ls central.git
```

```
config		description	HEAD		hooks		info		objects		refs
```

Il n'y a **aucun fichier du projet** : un dépôt nu ne contient que ce qui se
trouve d'habitude dans le dossier `.git`. Personne n'y travaille, on ne fait
qu'y pousser et en tirer.

L'option `-b main` fixe le nom de la branche par défaut. Sans elle, Git
utiliserait `master` et afficherait un avertissement.

> **Question** : pourquoi un dépôt de partage n'a-t-il pas besoin d'espace de
> travail ?

---

## Étape 2 : le poste d'Alice

**[ALICE]** Cloner le dépôt de partage :

```bash
git clone central.git alice
cd alice
```

```
Cloning into 'alice'...
warning: You appear to have cloned an empty repository.
done.
```

L'avertissement est normal : le dépôt de partage est vide.

Déclarer l'identité d'Alice **dans ce dépôt uniquement** (option `--local`,
qui est le défaut de `git config` dans un dépôt) :

```bash
git config user.name "Alice"
git config user.email "alice@exemple.fr"
```

Créer le premier fichier du projet, `yaml/contact.yaml` :

```
contact:
  prenom: Jean
  nom: Dupont
  ville: Paris
```

Avec un éditeur, ou en une commande :

```bash
mkdir yaml
cat > yaml/contact.yaml <<'EOF'
contact:
  prenom: Jean
  nom: Dupont
  ville: Paris
EOF
```

Puis committer et pousser :

```bash
git add yaml/contact.yaml
git commit -m "feat: contact.yaml"
git push -u origin main
```

```
To .../atelier/central.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Vérifier le lien qui vient d'être créé :

```bash
git branch -vv
```

```
* main 65fe95c [origin/main] feat: contact.yaml
```

`[origin/main]` est la **branche de suivi** : la branche locale `main` sait
désormais à quelle branche distante elle correspond. C'est ce que fait
l'option `-u` (`--set-upstream`).

> **Question** : que se passerait-il si l'identité avait été déclarée avec
> `--global` au lieu de `--local` ?

---

## Étape 3 : le poste de Bob

**[BOB]** Dans un **second terminal**, revenir dans le dossier `atelier` :

```bash
git clone central.git bob
cd bob
git config user.name "Bob"
git config user.email "bob@exemple.fr"
```

Cette fois le clone récupère le travail d'Alice :

```bash
ls yaml
```

```
contact.yaml
```

Inspecter le lien avec le dépôt distant :

```bash
git remote -v
```

```
origin	.../atelier/central.git (fetch)
origin	.../atelier/central.git (push)
```

```bash
git remote show origin
```

```
* remote origin
  Fetch URL: .../atelier/central.git
  Push  URL: .../atelier/central.git
  HEAD branch: main
  Remote branch:
    main tracked
  Local branch configured for 'git pull':
    main merges with remote main
  Local ref configured for 'git push':
    main pushes to main (up to date)
```

`origin` n'est qu'un **nom** donné à une URL. Ici l'URL est un chemin de
fichier : c'est le transport _filesystem_.

> **Question** : `git remote -v` et `git remote show origin` ne coûtent pas la
> même chose. Laquelle des deux interroge le dépôt distant ?

---

## Étape 4 : `fetch` n'est pas `pull`

**[BOB]** Ajouter le fichier `yaml/societe.yaml` :

```bash
cat > yaml/societe.yaml <<'EOF'
societe:
  nom: Orange
  ville: Guyancourt
EOF
git add yaml/societe.yaml
git commit -m "feat: societe.yaml"
git push
```

```
To .../atelier/central.git
   65fe95c..d6ba0d6  main -> main
```

**[ALICE]** Ne rien faire d'autre que récupérer :

```bash
git fetch
```

```
From .../atelier/central
   65fe95c..d6ba0d6  main       -> origin/main
```

```bash
ls yaml
```

```
contact.yaml
```

Le fichier de Bob **n'est pas là**. `git fetch` a téléchargé les commits et
déplacé `origin/main`, mais n'a touché ni à la branche locale ni aux fichiers.

```bash
git status
```

```
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

```bash
git log --oneline --graph --all --decorate
```

```
* d6ba0d6 (origin/main, origin/HEAD) feat: societe.yaml
* 65fe95c (HEAD -> main) feat: contact.yaml
```

Intégrer maintenant, hors ligne, sans rien retélécharger :

```bash
git merge origin/main
```

```
Updating 65fe95c..d6ba0d6
Fast-forward
 yaml/societe.yaml | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 yaml/societe.yaml
```

`git pull` aurait fait les deux d'un coup : `git fetch` puis `git merge`.

> **Question** : dans quelle situation réelle a-t-on intérêt à séparer le
> `fetch` du `merge` ?

---

## Étape 5 : le push refusé

Les deux postes vont travailler **en même temps**, chacun de son côté.

**[BOB]** Ajouter `yaml/voiture.yaml` et pousser :

```bash
cat > yaml/voiture.yaml <<'EOF'
voiture:
  marque: Renault
  modele: Clio
EOF
git add yaml/voiture.yaml
git commit -m "feat: voiture.yaml"
git push
```

**[ALICE]** Sans rien récupérer, modifier la ville dans `yaml/contact.yaml`
(`Paris` devient `Bordeaux`), committer, puis tenter de pousser :

```bash
git commit -am "fix(contact): ville"
git push
```

```
To .../atelier/central.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '.../atelier/central.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

**C'est l'incident numéro un en entreprise.** Git refuse parce que le push
ferait disparaître le commit de Bob. Il faut d'abord intégrer.

```bash
git fetch
git status
```

```
On branch main
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

```bash
git log --oneline --graph --all --decorate
```

```
* 2c5ff22 (HEAD -> main) fix(contact): ville
| * a229c12 (origin/main, origin/HEAD) feat: voiture.yaml
|/
* d6ba0d6 feat: societe.yaml
* 65fe95c feat: contact.yaml
```

Tenter un `git pull` nu :

```bash
git pull
```

```
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
...
fatal: Need to specify how to reconcile divergent branches.
```

Depuis Git 2.27, Git refuse de choisir à votre place. Choisir le rebase, qui
garde l'historique linéaire :

```bash
git pull --rebase
```

```
Successfully rebased and updated refs/heads/main.
```

```bash
git log --oneline --graph --all --decorate
```

```
* d4dded5 (HEAD -> main) fix(contact): ville
* a229c12 (origin/main, origin/HEAD) feat: voiture.yaml
* d6ba0d6 feat: societe.yaml
* 65fe95c feat: contact.yaml
```

Le commit d'Alice a été **rejoué par-dessus** celui de Bob : plus de
divergence, plus de commit de fusion. Le push passe maintenant :

```bash
git push
```

```
To .../atelier/central.git
   a229c12..d4dded5  main -> main
```

**[BOB]** Se remettre à jour :

```bash
git pull
```

```
Updating a229c12..d4dded5
Fast-forward
 yaml/contact.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Ici `git pull` ne pose aucune question : il n'y a pas de divergence, c'est un
simple _fast-forward_.

> **Question** : le SHA du commit d'Alice a changé après le `pull --rebase`.
> Pourquoi, et pourquoi cela n'a-t-il posé aucun problème ici ?

---

## Étape 6 : le conflit

Les deux postes vont modifier **la même ligne** du même fichier.

**[BOB]** Remplacer `prenom: Jean` par `prenom: Eric` dans
`yaml/contact.yaml`, puis :

```bash
git commit -am "fix(contact): prenom Eric"
git push
```

**[ALICE]** Sans rien récupérer, remplacer `prenom: Jean` par
`prenom: Marie`, puis :

```bash
git commit -am "fix(contact): prenom Marie"
git push
```

Le push est refusé, comme à l'étape 5. Intégrer :

```bash
git pull --rebase
```

```
From .../atelier/central
   d4dded5..a0d03f1  main       -> origin/main
Auto-merging yaml/contact.yaml
CONFLICT (content): Merge conflict in yaml/contact.yaml
error: could not apply c020c56... fix(contact): prenom Marie
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
```

```bash
git status
```

```
interactive rebase in progress; onto a0d03f1
...
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   yaml/contact.yaml
```

Ouvrir `yaml/contact.yaml` :

```
contact:
<<<<<<< HEAD
  prenom: Eric
=======
  prenom: Marie
>>>>>>> c020c56 (fix(contact): prenom Marie)
  nom: Dupont
  ville: Bordeaux
```

**Attention au sens de lecture.** Pendant un rebase, `HEAD` désigne la base
sur laquelle on rejoue, donc **le travail de Bob**, et le bloc du bas est
**votre propre commit**. C'est l'inverse de l'intuition, et l'inverse d'un
merge classique.

Choisir la version retenue (ici `Marie`), supprimer les trois lignes de
marqueurs, puis :

```bash
git add yaml/contact.yaml
git rebase --continue
```

L'éditeur configuré au jour 1 s'ouvre pour confirmer le message du commit.
Enregistrer et quitter sans rien changer.

```
[detached HEAD e84d7b4] fix(contact): prenom Marie
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/main.
```

La mention `detached HEAD` est normale pendant un rebase : la ligne suivante
confirme que `main` a bien été mise à jour.

```bash
git push
```

```
To .../atelier/central.git
   a0d03f1..e84d7b4  main -> main
```

En cas de panique, `git rebase --abort` ramène exactement à l'état d'avant le
`pull --rebase`. Rien n'est perdu.

> **Question** : pourquoi le conflit apparaît-il chez Alice et jamais chez
> Bob, alors qu'ils ont fait exactement la même chose ?

---

## Étape 7 : une branche partagée

**[ALICE]** Créer une branche de travail et tenter de la pousser :

```bash
git switch -c feat/velo
cat > yaml/velo.yaml <<'EOF'
velo:
  marque: Btwin
  modele: Riverside
EOF
git add yaml/velo.yaml
git commit -m "feat: velo.yaml"
git push
```

```
fatal: The current branch feat/velo has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feat/velo
```

La branche locale n'a pas de branche de suivi : Git ne devine pas où pousser.

```bash
git push -u origin feat/velo
```

```
To .../atelier/central.git
 * [new branch]      feat/velo -> feat/velo
branch 'feat/velo' set up to track 'origin/feat/velo'.
```

**[BOB]** Récupérer la branche de la collègue :

```bash
git fetch
git branch -r
```

```
  origin/HEAD -> origin/main
  origin/feat/velo
  origin/main
```

```bash
git switch feat/velo
```

```
Switched to a new branch 'feat/velo'
branch 'feat/velo' set up to track 'origin/feat/velo'.
```

Git a créé tout seul une branche locale reliée à la branche distante du même
nom. Ajouter une ligne `  taille: M` à la fin de `yaml/velo.yaml`, puis :

```bash
git commit -am "feat(velo): taille"
git push
```

**[ALICE]** Récupérer le travail de Bob, puis fusionner dans `main` :

```bash
git pull
git switch main
git merge --no-ff feat/velo -m "Merge branch 'feat/velo'"
git push
```

```bash
git log --oneline --graph --all --decorate
```

```
*   68ba666 (HEAD -> main, origin/main, origin/HEAD) Merge branch 'feat/velo'
|\
| * 729af6d (origin/feat/velo, feat/velo) feat(velo): taille
| * 4ce71cb feat: velo.yaml
|/
* e84d7b4 fix(contact): prenom Marie
* a0d03f1 fix(contact): prenom Eric
* d4dded5 fix(contact): ville
* a229c12 feat: voiture.yaml
* d6ba0d6 feat: societe.yaml
* 65fe95c feat: contact.yaml
```

> **Question** : Bob n'a jamais tapé `-u` pour `feat/velo`, et pourtant son
> `git push` a fonctionné. Pourquoi ?

---

## Étape 8 : supprimer une branche distante

La fonctionnalité est fusionnée, la branche partagée ne sert plus.

**[ALICE]**

```bash
git push origin --delete feat/velo
```

```
To .../atelier/central.git
 - [deleted]         feat/velo
```

La syntaxe historique `git push origin :feat/velo` fait exactement la même
chose.

```bash
git branch -d feat/velo
```

```
Deleted branch feat/velo (was 729af6d).
```

**[BOB]** Chez Bob, rien n'a bougé tant qu'il n'a pas récupéré :

```bash
git switch main
git fetch --prune
```

```
From .../atelier/central
 - [deleted]         (none)     -> origin/feat/velo
   e84d7b4..68ba666  main       -> origin/main
```

```bash
git branch -vv
```

```
  feat/velo 729af6d [origin/feat/velo: gone] feat(velo): taille
* main      a0d03f1 [origin/main: behind 4] fix(contact): prenom Eric
```

`gone` signale une branche locale dont la branche de suivi a disparu. Sans
`--prune`, la référence `origin/feat/velo` serait restée là indéfiniment.

Le nombre affiché après `behind` dépend de ce que Bob a déjà récupéré : 3 ou 4
selon votre parcours, ce n'est pas une erreur.

```bash
git pull
git branch -d feat/velo
```

```
Deleted branch feat/velo (was 729af6d).
```

`git branch -d` refuse de supprimer une branche non fusionnée. Ici il accepte
parce que `main` vient d'être mise à jour et contient déjà ce travail.

> **Question** : `git fetch --prune` supprime-t-il des commits ?

---

## Étape 9 : pourquoi un dépôt **nu**

Dernière manipulation, pour comprendre l'étape 1.

**[BOB]** Tenter de pousser directement vers le poste d'Alice. Depuis le
dossier `atelier` :

```bash
git clone alice copie
cd copie
git config user.name "Bob"
git config user.email "bob@exemple.fr"
echo "  pays: France" >> yaml/contact.yaml
git commit -am "test: push vers un depot non nu"
git push
```

```
remote: error: refusing to update checked out branch: refs/heads/main
remote: error: By default, updating the current branch in a non-bare repository
remote: is denied, because it will make the index and work tree inconsistent
remote: with what you pushed, and will require 'git reset --hard' to match
remote: the work tree to HEAD.
...
 ! [remote rejected] main -> main (branch is currently checked out)
error: failed to push some refs to '.../atelier/alice'
```

Un dépôt avec espace de travail refuse qu'on lui pousse sa branche courante :
ses fichiers ne correspondraient plus à son historique. **C'est exactement la
raison d'être du dépôt nu.**

Nettoyer :

```bash
cd ..
rm -rf copie
```

> **Question** : GitHub, GitLab et Bitbucket stockent-ils vos dépôts sous
> forme nue ?

---

## Résultat final attendu

Depuis `alice/` comme depuis `bob/`, après `git pull` :

```
*   68ba666 (HEAD -> main, origin/main, origin/HEAD) Merge branch 'feat/velo'
|\
| * 729af6d feat(velo): taille
| * 4ce71cb feat: velo.yaml
|/
* e84d7b4 fix(contact): prenom Marie
* a0d03f1 fix(contact): prenom Eric
* d4dded5 fix(contact): ville
* a229c12 feat: voiture.yaml
* d6ba0d6 feat: societe.yaml
* 65fe95c feat: contact.yaml
```

Vérifier que les deux postes ont bien produit deux auteurs distincts :

```bash
git log --format='%h %an <%ae> %s'
```

```
7df3571 Alice <alice@exemple.fr> Merge branch 'feat/velo'
a1e5252 Alice <alice@exemple.fr> fix(contact): prenom Marie
5694592 Bob <bob@exemple.fr> feat(velo): taille
c673c14 Bob <bob@exemple.fr> fix(contact): prenom Eric
d02e2e5 Alice <alice@exemple.fr> feat: velo.yaml
dbf0f50 Alice <alice@exemple.fr> fix(contact): ville
4d525e0 Bob <bob@exemple.fr> feat: voiture.yaml
48fddae Bob <bob@exemple.fr> feat: societe.yaml
a95ddb2 Alice <alice@exemple.fr> feat: contact.yaml
```

## Aller plus loin : deux vrais postes

Le même atelier fonctionne à deux machines, sans forge :

- **Partage réseau** : poser `central.git` sur un dossier partagé et cloner ce
  chemin. Sous Git Bash, l'URL d'un partage Windows s'écrit
  `//serveur/partage/central.git`.
- **SSH** : poser `central.git` sur une machine accessible, puis
  `git clone utilisateur@machine:/srv/git/central.git`. C'est le contenu du
  bonus « Git sur le serveur » du jour 2.
- **Clé USB** : `git bundle create projet.bundle --all` produit un fichier
  unique qui se clone comme un dépôt.

Dans les trois cas, **rien ne change** dans les commandes de l'exercice :
seule l'URL du remote change.
