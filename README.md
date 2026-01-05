# Fabriquer un commit à la main : sous le capot du moteur Git

> Un collègue affirme qu'un commit "contient les fichiers modifiés". Vous allez ouvrir le capot, descendre du commit jusqu'au contenu d'un fichier, puis fabriquer vous-même un commit sans jamais taper `git commit`, pour découvrir qu'un commit ne contient rien du tout : il pointe.

**Niveau** : intermédiaire | **Durée estimée** : 60 min

## Prérequis

- Jour 1 complet : `git init`, `git add`, `git commit`, `git log`, `git status`, `git reset --hard`, notion d'index et de branche
- Jour 2 chapitre `02-clean` (les trois modes de reset) et chapitre `04-emergency` (reflog)
- Jour 2 chapitre `06-internals` vu en slides juste avant : objets, références, packfiles
- Git version 2.28 minimum (pour `git init -b main`), 2.54.0 utilisé pour la validation
- Un terminal Git Bash sur Windows, Terminal sur macOS ou Linux. Aucun outil supplémentaire à installer
- Accès à github.com pour le clone, ou le fichier `17-internals.bundle` distribué par le formateur si la salle est sans réseau

## 0. Récupérer l'exercice

Cloner la branche `17-internals` du dépôt d'exercices, puis déclarer une identité **locale au dépôt** (elle ne modifie pas la configuration globale du poste). Tout le reste de l'exercice se déroule dans un terminal : Git Bash sur Windows, Terminal sur macOS et Linux. Les commandes `ls`, `cat`, `find`, `printf` et `wc` utilisées ici sont celles de Git Bash, elles ne fonctionnent pas dans l'invite de commandes CMD de Windows.

```bash
git clone -b 17-internals https://github.com/FabienSalles/git-exercices.git 17-internals
cd 17-internals
git config user.name "Participant"
git config user.email "participant@exemple.fr"
```

Résultat attendu :

```
```
Cloning into '17-internals'...
```
Le dossier `17-internals` contient `.gitignore`, `README.md`, `yaml/` et le dossier caché `.git`.
```

> **Question** : Le dépôt distant a été copié en entier sur le poste. Quelle partie du dossier cloné contient réellement le dépôt, et laquelle n'est qu'une copie de travail que l'on pourrait effacer sans rien perdre ?

## 1. Ouvrir le capot : le contenu de .git

Lister le contenu du dossier `.git`, puis lire les deux fichiers texte qui définissent où vous êtes : `HEAD` et la référence de branche. Ne rien modifier à la main dans `.git`.

```bash
ls -a .git
cat .git/HEAD
cat .git/refs/heads/17-internals
git rev-parse HEAD
```

Résultat attendu :

```
```
.
..
config
description
HEAD
hooks
index
info
logs
objects
packed-refs
refs
```
`cat .git/HEAD` affiche exactement :
```
ref: refs/heads/17-internals
```
`cat .git/refs/heads/17-internals` affiche un hash de 40 caractères, et `git rev-parse HEAD` affiche **le même**. Ce hash est celui du commit `docs: enonce de l exercice` : il dépend du contenu de ce README, il n'est donc pas cité ici et il peut différer du poste voisin. Tous les autres hashes de cet énoncé, eux, sont identiques pour tout le monde.

À noter : `cat .git/refs/remotes/origin/17-internals` échoue avec `No such file or directory`. La référence existe pourtant, elle a simplement été empaquetée dans le fichier `.git/packed-refs`. La commande robuste pour lire une référence est `git rev-parse`, jamais `cat`.
```

> **Question** : `HEAD` est un fichier de 24 octets, et `refs/heads/17-internals` un fichier de 41 octets. Que se passe-t-il physiquement dans ces deux fichiers quand on tape `git switch autre-branche` puis `git commit` ?

## 2. Où sont les objets juste après le clone

Compter les objets du dépôt et regarder ce que contient réellement `.git/objects`.

```bash
git count-objects -vH
ls .git/objects
```

Résultat attendu :

```
```
count: 0
size: 0 bytes
in-pack: 18
packs: 1
size-pack: 3.10 KiB
prune-packable: 0
garbage: 0
size-garbage: 0 bytes
```
```
info
pack
```
Lecture : `count: 0` signifie zéro objet en vrac (loose). Les 18 objets du dépôt sont tous à l'intérieur d'un unique **packfile**, exactement comme décrit dans la slide *Les Packfiles*. C'est le serveur qui les a empaquetés avant de les envoyer sur le réseau. La valeur `size-pack` peut varier de quelques centaines d'octets selon la taille de ce README.
```

> **Question** : Il n'y a aucun fichier nommé `contact.yaml` dans `.git/objects`, et pourtant `git show HEAD:yaml/contact.yaml` fonctionne. Où est passé le contenu du fichier ?

## 3. Descendre la chaîne : commit vers tree

Interroger le commit `e34355d` (`feat: societe.yaml`) avec les trois options de `git cat-file` : `-t` pour le type, `-s` pour la taille en octets, `-p` pour le contenu déchiffré (*pretty print*). Un hash peut toujours être abrégé tant qu'il reste sans ambiguïté, 7 caractères suffisent ici.

```bash
git cat-file -t e34355d
git cat-file -s e34355d
git cat-file -p e34355d
```

Résultat attendu :

```
```
commit
```
```
239
```
```
tree 2d349c4d19313cf1d15d9f1936504b4dfd6827e5
parent fe8d2eb4299094df8cdf4cd8c5c55a7acbe5b5b6
author ConveyCode <formation@conveycode.fr> 1767600900 +0100
committer ConveyCode <formation@conveycode.fr> 1767600900 +0100

feat: societe.yaml
```
Ces valeurs sont identiques sur tous les postes de la salle.
```

> **Question** : Un commit fait 239 octets. Le dépôt contient quatre fichiers YAML. Le commit contient-il ces fichiers ? Que contient-il exactement, et où est le mot `societe.yaml` dans ces 239 octets ?

## 4. Descendre la chaîne : tree vers sous-tree vers blob

Suivre le pointeur `tree` du commit précédent, puis le pointeur du sous-dossier `yaml`, puis le blob de `societe.yaml`. Chaque hash affiché est celui à taper à la ligne suivante.

```bash
git cat-file -p 2d349c4
git cat-file -p 31f7b8e
git cat-file -t 1b41749
git cat-file -s 1b41749
git cat-file -p 1b41749
```

Résultat attendu :

```
Le tree racine :
```
100644 blob ed165585d6fa4105b277dafc671a5ec50e00d39d	.gitignore
040000 tree 31f7b8e99a0718d31d357754882a8b4b88d12bda	yaml
```
Le tree `yaml` :
```
100644 blob 7f71ffe10892a53d5b42bef4b31016c56e7ad958	contact.yaml
100644 blob 1b417497ef2a02bb852e01f0380c34306d398a2f	societe.yaml
100644 blob b06cf04ba7b539fad6c0f85a17e8b7210129f95b	voiture.yaml
```
Le blob :
```
blob
```
```
43
```
```
societe:
  nom: Orange
  ville: Guyancourt
```
Raccourci équivalent, à essayer pour vérifier :
```
git rev-parse e34355d^{tree}
git rev-parse e34355d:yaml
git rev-parse e34355d:yaml/societe.yaml
```
qui affiche `2d349c4d...`, `31f7b8e9...` et `1b417497...`.
```

> **Question** : Le nom `societe.yaml` et la permission `100644` figurent dans le tree, pas dans le blob. Quelle conséquence cela a-t-il si l'on renomme un fichier de 50 Mo sans en changer une ligne : combien d'octets Git doit-il stocker en plus ?

## 5. Combien d'objets crée un commit ordinaire

Créer un nouveau fichier avec la commande `printf` donnée (et pas avec un éditeur, pour garantir des fins de ligne LF), faire un commit normal, puis recompter les objets.

```bash
printf 'velo:\n  marque: Look\n  modele: 576\n' > yaml/velo.yaml
git add yaml/velo.yaml
git commit -m "feat: velo.yaml"
git count-objects -vH
```

Résultat attendu :

```
```
count: 4
size: 16.00 KiB
in-pack: 18
packs: 1
size-pack: 3.10 KiB
```
Quatre objets en vrac viennent d'apparaître. Les identifier :
```
git cat-file -t HEAD                  -> commit
git cat-file -t HEAD^{tree}           -> tree
git cat-file -t HEAD:yaml             -> tree
git cat-file -t HEAD:yaml/velo.yaml   -> blob
```
Un commit, deux trees (la racine et `yaml`, tous deux modifiés puisqu'ils listent un fichier de plus), un blob. Les blobs de `contact.yaml`, `voiture.yaml` et `societe.yaml` n'ont **pas** été recréés :
```
git rev-parse HEAD:yaml/contact.yaml
git rev-parse e34355d:yaml/contact.yaml
```
les deux affichent `7f71ffe10892a53d5b42bef4b31016c56e7ad958`.
```

> **Question** : Le dépôt contient maintenant deux commits qui pointent chacun vers un état complet du projet, et pourtant un seul blob a été ajouté. Git stocke-t-il des snapshots complets ou des différences ?

## 6. Le hash ne dépend que du contenu

Vérifier que `git hash-object` calcule toujours le même identifiant pour le même contenu, quel que soit le nom du fichier, puis reproduire la formule à la main. Sur macOS, si `sha1sum` n'existe pas, utiliser `shasum` à la place.

```bash
printf 'bonjour\n' | git hash-object --stdin
printf 'bonjour\n' > a.txt
printf 'bonjour\n' > b.txt
git hash-object a.txt
git hash-object b.txt
printf 'blob 8\0bonjour\n' | sha1sum
rm a.txt b.txt
```

Résultat attendu :

```
Les quatre commandes affichent le même hash :
```
1cd909e05d33f0f6bc4ea1caf19b5749b434ceb3
```
La dernière ligne prouve la formule complète : Git préfixe le contenu par le mot `blob`, un espace, la taille en octets et un octet nul, puis passe le tout dans SHA-1. Rien d'autre. Ni le nom du fichier, ni la date, ni l'auteur n'entrent dans le calcul.

À noter : `git hash-object` sans `-w` calcule mais n'écrit rien dans la base.
```

> **Question** : Si deux développeurs dans deux entreprises différentes créent chacun un fichier contenant le même texte, quel est le hash du blob de chacun ? Qu'est-ce que cela permet lors d'un `git push` ou d'un `git fetch` ?

## 7. Ouvrir un dépôt neuf pour fabriquer un commit à la main

Revenir dans le dossier parent et créer un dépôt vierge, séparé, dans lequel personne ne risque rien. Y déclarer une identité et **figer les dates** avec deux variables d'environnement : c'est ce qui rendra le commit fabriqué rigoureusement identique sur tous les postes.

```bash
cd ..
mkdir moteur
cd moteur
git init -b main
git config user.name "Formation Git"
git config user.email "formation@exemple.fr"
export GIT_AUTHOR_DATE="2026-01-05T09:00:00+0100"
export GIT_COMMITTER_DATE="2026-01-05T09:00:00+0100"
mkdir yaml
printf 'logs/\n*.tmp\n' > .gitignore
printf 'contact:\n  prenom: Jean\n  nom: Dupont\n  ville: Paris\n' > yaml/contact.yaml
git status --short
```

Résultat attendu :

```
```
Initialized empty Git repository in .../moteur/.git/
```
```
?? .gitignore
?? yaml/
```
Contrôle obligatoire avant de continuer, les deux commandes doivent afficher exactement ces hashes :
```
git hash-object .gitignore
-> ed165585d6fa4105b277dafc671a5ec50e00d39d
git hash-object yaml/contact.yaml
-> 7f71ffe10892a53d5b42bef4b31016c56e7ad958
```
Si les valeurs diffèrent, les fichiers ont été créés avec des fins de ligne CRLF et `core.autocrlf` est à `false` : les recréer avec les commandes `printf` ci-dessus, dans Git Bash, sans passer par un éditeur.
```

> **Question** : Ce dépôt est vide, il n'a jamais rien vu du dépôt d'exercice. Pourquoi le hash de son `.gitignore` est-il déjà celui de l'autre dépôt ?

## 8. Fabriquer les blobs

Écrire les deux fichiers dans la base d'objets avec `git hash-object -w`. Le `-w` (write) est ce qui distingue le simple calcul de l'écriture réelle. Rien n'est ajouté à l'index à ce stade.

```bash
git hash-object -w .gitignore
git hash-object -w yaml/contact.yaml
find .git/objects -type f | sort
git status --short
```

Résultat attendu :

```
```
ed165585d6fa4105b277dafc671a5ec50e00d39d
7f71ffe10892a53d5b42bef4b31016c56e7ad958
```
```
.git/objects/7f/71ffe10892a53d5b42bef4b31016c56e7ad958
.git/objects/ed/165585d6fa4105b277dafc671a5ec50e00d39d
```
Les deux premiers caractères du hash servent de nom de dossier, les 38 suivants de nom de fichier. Le fichier sur disque est compressé en zlib : `wc -c` sur lui donne un nombre différent de `git cat-file -s`.

`git status --short` affiche toujours `?? .gitignore` et `?? yaml/` : les contenus sont dans la base, mais l'index est encore vide.
```

> **Question** : Les contenus sont stockés, `git status` ne les voit pas, `git log` non plus. Que manque-t-il pour qu'ils fassent partie du projet ?

## 9. Remplir l'index à la main

Déclarer dans l'index quel blob correspond à quel chemin, avec `git update-index --add --cacheinfo <mode> <hash> <chemin>`. Le mode `100644` signifie fichier ordinaire non exécutable (`100755` pour un exécutable, `120000` pour un lien symbolique). C'est exactement le travail que `git add` fait en une seule commande.

```bash
git update-index --add --cacheinfo 100644 ed165585d6fa4105b277dafc671a5ec50e00d39d .gitignore
git update-index --add --cacheinfo 100644 7f71ffe10892a53d5b42bef4b31016c56e7ad958 yaml/contact.yaml
git ls-files -s
git status --short
```

Résultat attendu :

```
```
100644 ed165585d6fa4105b277dafc671a5ec50e00d39d 0	.gitignore
100644 7f71ffe10892a53d5b42bef4b31016c56e7ad958 0	yaml/contact.yaml
```
`git status --short` affiche maintenant `A  .gitignore` et `A  yaml/contact.yaml`.

Si une ligne affiche `AM` au lieu de `A`, le hash saisi ne correspond pas au fichier présent sur le disque : reprendre l'étape 7.
```

> **Question** : L'index est le fichier `.git/index`. Il vient d'être rempli sans que le contenu des fichiers y soit copié. Que contient-il donc, et pourquoi la slide parle-t-elle de la « pâte à modeler » ?

## 10. Figer l'index en arbre

Transformer l'état de l'index en objets `tree` avec `git write-tree`. La commande retourne le hash du tree racine.

```bash
git write-tree
git cat-file -p 1a9f90bd705223b4590e7b30e1713a02fa733489
find .git/objects -type f | sort
```

Résultat attendu :

```
```
1a9f90bd705223b4590e7b30e1713a02fa733489
```
```
100644 blob ed165585d6fa4105b277dafc671a5ec50e00d39d	.gitignore
040000 tree 885f6b538f79a16ca6039228963ba59a756e99be	yaml
```
```
.git/objects/1a/9f90bd705223b4590e7b30e1713a02fa733489
.git/objects/7f/71ffe10892a53d5b42bef4b31016c56e7ad958
.git/objects/88/5f6b538f79a16ca6039228963ba59a756e99be
.git/objects/ed/165585d6fa4105b277dafc671a5ec50e00d39d
```
Deux objets `tree` ont été créés d'un coup, un par niveau de dossier.

Démonstration à faire, de retour dans le premier dépôt : `git rev-parse 0134e2e^{tree}` y affiche également `1a9f90bd705223b4590e7b30e1713a02fa733489`. Le tree fabriqué ici à la main est **le même objet** que celui produit par le commit `feat: contact.yaml` de l'exercice, sans qu'aucune donnée n'ait circulé entre les deux dépôts.
```

> **Question** : Deux dépôts sans aucun lien produisent le même hash de tree. Sur quoi repose alors la déduplication lors d'un `git fetch`, et pourquoi cloner deux fois le même projet coûte-t-il deux fois la place ?

## 11. Fabriquer le commit, et constater qu'il est invisible

Créer l'objet commit avec `git commit-tree`, qui prend un tree et un message et retourne un hash. Puis, **avant toute autre commande**, demander l'historique.

```bash
git commit-tree 1a9f90bd705223b4590e7b30e1713a02fa733489 -m "feat: commit fabrique a la main"
git log --oneline
git fsck
git cat-file -p a420e713f070341d0ac7b7513510538943728e49
```

Résultat attendu :

```
```
a420e713f070341d0ac7b7513510538943728e49
```
Ce hash est le même pour toute la salle, à condition d'avoir bien exporté les deux variables de date à l'étape 7.

`git log --oneline` répond :
```
fatal: your current branch 'main' does not have any commits yet
```
Ce n'est pas une erreur de manipulation, c'est le résultat attendu.

`git fsck` :
```
dangling commit a420e713f070341d0ac7b7513510538943728e49
```
`git cat-file -p` :
```
tree 1a9f90bd705223b4590e7b30e1713a02fa733489
author Formation Git <formation@exemple.fr> 1767600000 +0100
committer Formation Git <formation@exemple.fr> 1767600000 +0100

feat: commit fabrique a la main
```
Le commit existe, il est complet, il est lisible. Simplement, aucune référence ne pointe dessus.
```

> **Question** : Le commit est dans la base et `git log` ne le voit pas. Qu'est-ce que `git log` parcourt exactement pour construire un historique ?

## 12. Poser la branche

Faire pointer la branche `main` sur ce commit avec `git update-ref`, puis vérifier que Git considère désormais le projet comme normal.

```bash
git update-ref refs/heads/main a420e713f070341d0ac7b7513510538943728e49
cat .git/refs/heads/main
git log --oneline --stat
git status
```

Résultat attendu :

```
```
a420e713f070341d0ac7b7513510538943728e49
```
```
a420e71 feat: commit fabrique a la main
 .gitignore        | 2 ++
 yaml/contact.yaml | 4 ++++
 2 files changed, 6 insertions(+)
```
```
On branch main
nothing to commit, working tree clean
```
Un commit complet vient d'être fabriqué sans avoir jamais tapé `git add` ni `git commit`. La commande qui l'a rendu visible a écrit 41 octets dans un fichier texte.
```

> **Question** : Une branche est donc un fichier contenant un hash. Que fait alors réellement `git branch feat/x`, `git reset --hard HEAD~1`, et `git switch` ?

## 13. Un deuxième commit à la main, avec parent

Recommencer le cycle complet en modifiant `contact.yaml`, et cette fois passer le commit précédent en parent avec l'option `-p`. Penser à avancer la date pour rester reproductible.

```bash
export GIT_AUTHOR_DATE="2026-01-05T09:05:00+0100"
export GIT_COMMITTER_DATE="2026-01-05T09:05:00+0100"
printf 'contact:\n  prenom: Jean\n  nom: Dupont\n  ville: Bordeaux\n' > yaml/contact.yaml
git hash-object -w yaml/contact.yaml
git update-index --add --cacheinfo 100644 ea30014d2c050ccd8a9be230f8a139513cd65b8b yaml/contact.yaml
git write-tree
git commit-tree 4f6813b80a3af4534abb0246fb0bf511e0a327e2 -p a420e713f070341d0ac7b7513510538943728e49 -m "fix(contact): ville"
git update-ref refs/heads/main 67b81c540038d5e3b4ec73d0205e6f7c9781c115
git log --oneline --graph
git show HEAD
git status --short
```

Résultat attendu :

```
Les hashes intermédiaires, identiques pour tout le monde :
```
ea30014d2c050ccd8a9be230f8a139513cd65b8b   (le nouveau blob)
4f6813b80a3af4534abb0246fb0bf511e0a327e2   (le nouveau tree racine)
67b81c540038d5e3b4ec73d0205e6f7c9781c115   (le nouveau commit)
```
```
* 67b81c5 fix(contact): ville
* a420e71 feat: commit fabrique a la main
```
`git show HEAD` affiche un vrai diff :
```
diff --git a/yaml/contact.yaml b/yaml/contact.yaml
index 7f71ffe..ea30014 100644
--- a/yaml/contact.yaml
+++ b/yaml/contact.yaml
@@ -1,4 +1,4 @@
 contact:
   prenom: Jean
   nom: Dupont
-  ville: Paris
+  ville: Bordeaux
```
`git status --short` n'affiche rien : l'arbre de travail est propre.
```

> **Question** : Aucun diff n'a été stocké : les deux commits pointent chacun vers un tree complet. D'où vient alors le diff affiché par `git show` ?

## 14. Un objet orphelin : le blob jamais commité

Revenir dans le dépôt d'exercice et écrire un contenu dans la base sans jamais l'ajouter à l'index.

```bash
cd ../17-internals
printf 'brouillon jamais commite\n' > brouillon.txt
git hash-object -w brouillon.txt
git fsck
```

Résultat attendu :

```
```
65099588c4ec6588f32bcf4901b2a308c0bba09b
```
```
dangling blob 65099588c4ec6588f32bcf4901b2a308c0bba09b
```
Le blob est dans la base, aucun tree ne le référence : `git fsck` (file system check) le qualifie de *dangling*, littéralement pendant dans le vide.
```

> **Question** : Que signifie exactement « atteignable » pour Git, et à partir de quels points de départ la vérification part-elle ?

## 15. Un commit orphelin, et pourquoi fsck ne le voit pas tout de suite

Créer un vrai commit, le supprimer avec `git reset --hard`, et observer que `git fsck` ne signale rien. Puis vider le journal des références et refaire le test.

```bash
printf 'moto:\n  marque: Honda\n' > yaml/moto.yaml
git add yaml/moto.yaml
git commit -m "feat: moto.yaml"
git rev-parse HEAD
git reset --hard HEAD~1
git fsck
git reflog
git reflog expire --expire=now --expire-unreachable=now --all
git fsck
```

Résultat attendu :

```
Noter le hash affiché par `git rev-parse HEAD` avant le reset, il sera différent d'un poste à l'autre.

Après le `reset --hard`, `git fsck` ne signale que le blob de l'étape précédente :
```
dangling blob 65099588c4ec6588f32bcf4901b2a308c0bba09b
```
Le commit supprimé n'apparaît pas, parce qu'il est encore atteignable par le reflog :
```
fb02a1c HEAD@{0}: reset: moving to HEAD~1
2de7401 HEAD@{1}: commit: feat: moto.yaml
fb02a1c HEAD@{2}: commit: feat: velo.yaml
833c522 HEAD@{3}: clone: from https://github.com/FabienSalles/git-exercices.git
```
Après expiration du reflog :
```
dangling blob 65099588c4ec6588f32bcf4901b2a308c0bba09b
dangling commit 2de7401acb0e1448b825ed0326ad1b8e976b65c6
```
À noter : `git reflog` sur un journal vide affiche `notice: No default references` et rien d'autre.
```

> **Question** : Le reflog est donc une racine d'atteignabilité au même titre que les branches. En quoi cela explique-t-il qu'un `git reset --hard` malheureux soit récupérable, et pendant combien de temps par défaut ?

## 16. Récupérer les objets orphelins

Demander à `git fsck` d'écrire les objets orphelins dans un dossier lisible, puis rattacher le commit perdu à une branche.

```bash
git fsck --lost-found
find .git/lost-found -type f | sort
cat .git/lost-found/other/65099588c4ec6588f32bcf4901b2a308c0bba09b
git branch recuperation "$(ls .git/lost-found/commit/)"
git log --oneline --graph --branches
git fsck
```

Résultat attendu :

```
```
dangling blob 65099588c4ec6588f32bcf4901b2a308c0bba09b
dangling commit 2de7401acb0e1448b825ed0326ad1b8e976b65c6
```
```
.git/lost-found/commit/2de7401acb0e1448b825ed0326ad1b8e976b65c6
.git/lost-found/other/65099588c4ec6588f32bcf4901b2a308c0bba09b
```
```
brouillon jamais commite
```
Pour un commit, le fichier créé est vide et c'est son **nom** qui porte le hash. Pour les autres objets, le fichier contient le contenu.

Après la création de la branche, l'historique complet est de retour :
```
* 2de7401 feat: moto.yaml
* fb02a1c feat: velo.yaml
* 833c522 docs: enonce de l exercice
* e34355d feat: societe.yaml
* fe8d2eb feat: voiture.yaml
* 0134e2e feat: contact.yaml
* 8252000 chore: initial commit
```
Et `git fsck` ne signale plus que le blob : le commit est redevenu atteignable.
```

> **Question** : Rattacher le commit a suffi à faire disparaître l'alerte, sans copier un seul octet. Pourquoi ?

## 17. Le ramasse-miettes : gc, packfile, verify-pack

Compter les objets, lancer le ramasse-miettes avec suppression immédiate des objets inatteignables, recompter, puis inspecter le packfile produit.

```bash
git count-objects -vH
git gc --prune=now
git count-objects -vH
ls .git/objects/pack
git verify-pack -v .git/objects/pack/*.idx | head -20
git verify-pack -v .git/objects/pack/*.idx | tail -4
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
git fsck
git cat-file -t 65099588c4ec6588f32bcf4901b2a308c0bba09b
```

Résultat attendu :

```
Avant :
```
count: 9
size: 36.00 KiB
in-pack: 18
packs: 1
```
Après :
```
count: 0
size: 0 bytes
in-pack: 26
packs: 1
size-pack: 3.86 KiB
```
Un seul packfile, trois fichiers sur disque :
```
pack-ce16d32f....idx
pack-ce16d32f....pack
pack-ce16d32f....rev
```
`git verify-pack -v` liste chaque objet. Les colonnes sont : hash, type, taille réelle, taille dans le pack, position dans le pack, puis pour les objets stockés en delta la profondeur de chaîne et le hash de l'objet de base.
```
fb02a1cc0dae5ca6180fcd9fd57e2dcf0ad9cc6f commit 236 156 12
ed165585d6fa4105b277dafc671a5ec50e00d39d blob   12 21 1087
84c9ce4a3209da687998a2a683289f11a69245be tree   9 20 1630 1 33011a917c6d3ee1cee9c052f5616756586b1541
```
Et le bilan des deltas :
```
non delta: 21 objects
chain length = 1: 4 objects
chain length = 2: 1 object
.git/objects/pack/pack-ce16d32f....pack: ok
```
L'inventaire par type :
```
   7 blob
   7 commit
  12 tree
```
`git fsck` n'affiche plus rien, et le blob orphelin a disparu :
```
fatal: git cat-file: could not get object info
```
Attention : `git gc` **sans** `--prune=now` n'aurait pas détruit le blob. Il l'aurait déplacé dans un second packfile dit *cruft*, où les objets inatteignables sont conservés deux semaines par défaut.
```

> **Question** : Vingt-six objets, sept blobs seulement pour un projet de quatre fichiers YAML modifiés plusieurs fois. Où sont passées les versions intermédiaires, et pourquoi y a-t-il presque deux fois plus de trees que de commits ?

## 18. Le mot de la fin

Répondre par écrit, en une phrase chacun, aux trois questions suivantes, puis comparer avec le voisin.

```bash
# Aucune commande. Trois phrases a ecrire.
# 1. Que contient un commit ?
# 2. Que contient une branche ?
# 3. Que detruit un git reset --hard ?
```

Résultat attendu :

```
Les trois réponses attendues :

1. Un commit contient un pointeur vers un tree, zéro, un ou plusieurs pointeurs vers des commits parents, deux identités avec deux dates, et un message. Il ne contient aucun fichier et aucun diff. Taille observée : 239 octets pour un projet de quatre fichiers.
2. Une branche contient un hash de 40 caractères, dans un fichier texte de 41 octets. Rien d'autre.
3. `git reset --hard` déplace un pointeur et écrase l'arbre de travail. Il ne détruit aucun objet. Les commits abandonnés restent dans `.git/objects`, atteignables par le reflog, jusqu'à ce que `git gc --prune` passe.

Et la chaîne complète, dans l'ordre où elle a été fabriquée :
```
blob  (hash-object -w)   le contenu, sans nom
  ^
tree  (write-tree)       les noms, les modes, les sous-dossiers
  ^
commit (commit-tree)     le tree, le parent, l'auteur, le message
  ^
ref   (update-ref)       41 octets qui rendent tout cela visible
```
```

> **Question** : Sachant tout cela, que fait exactement `git commit -m "..."` ? Combien de commandes de plomberie enchaîne-t-il, et dans quel ordre ?

## Résultat final attendu

```
Deux dépôts dans un état vérifiable.

Dépôt `moteur`, entièrement fabriqué à la plomberie, hashes identiques sur tous les postes :

```
$ git log --oneline --graph
* 67b81c5 fix(contact): ville
* a420e71 feat: commit fabrique a la main

$ git status
On branch main
nothing to commit, working tree clean

$ git cat-file -p a420e713f070341d0ac7b7513510538943728e49
tree 1a9f90bd705223b4590e7b30e1713a02fa733489
author Formation Git <formation@exemple.fr> 1767600000 +0100
committer Formation Git <formation@exemple.fr> 1767600000 +0100

feat: commit fabrique a la main
```

Dépôt `17-internals`, après récupération et ramasse-miettes (les deux hashes de tête varient d'un poste à l'autre, ceux du bas sont figés) :

```
$ git log --oneline --graph --branches
* 2de7401 feat: moto.yaml
* fb02a1c feat: velo.yaml
* 833c522 docs: enonce de l exercice
* e34355d feat: societe.yaml
* fe8d2eb feat: voiture.yaml
* 0134e2e feat: contact.yaml
* 8252000 chore: initial commit

$ git count-objects -vH
count: 0
size: 0 bytes
in-pack: 26
packs: 1
size-pack: 3.86 KiB
prune-packable: 0
garbage: 0
size-garbage: 0 bytes

$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
   7 blob
   7 commit
  12 tree

$ git fsck
$ git cat-file -t 65099588c4ec6588f32bcf4901b2a308c0bba09b
fatal: git cat-file: could not get object info
```
```

## Critères de réussite

- Le participant sait afficher, pour n'importe quel commit, son type, sa taille et son contenu brut avec `git cat-file -t/-s/-p`, et sait citer les cinq lignes qui composent un objet commit
- Le participant a descendu la chaîne complète commit vers tree racine vers sous-tree `yaml` vers blob, et a retrouvé le texte de `societe.yaml` en partant du seul hash `e34355d`
- `git write-tree` dans le dépôt `moteur` retourne exactement `1a9f90bd705223b4590e7b30e1713a02fa733489`, identique à `git rev-parse 0134e2e^{tree}` dans le dépôt d'exercice
- `git commit-tree` retourne exactement `a420e713f070341d0ac7b7513510538943728e49`, et ce hash est le même sur tous les postes de la salle
- Avant `git update-ref`, `git log` échoue et `git fsck` affiche `dangling commit a420e713...` ; après `git update-ref`, `git log --oneline` affiche `a420e71 feat: commit fabrique a la main` et `git status` affiche `nothing to commit, working tree clean`
- Le deuxième commit fabriqué avec `-p` porte le hash `67b81c540038d5e3b4ec73d0205e6f7c9781c115` et `git log --oneline --graph` affiche les deux commits chaînés
- Le participant explique pourquoi `git fsck` ne signale pas le commit juste après un `reset --hard`, et sait le rendre visible en expirant le reflog
- `git fsck --lost-found` a produit `.git/lost-found/commit/<hash>` et `.git/lost-found/other/<hash>`, et le commit perdu a été rattaché par `git branch`
- Après `git gc --prune=now` : `count: 0`, `packs: 1`, `in-pack: 26`, `git fsck` muet, et `git cat-file -t` sur le blob orphelin échoue
- Le participant répond juste aux trois questions finales : un commit contient un pointeur vers un tree et pas de fichiers, une branche est un fichier de 41 octets, `git reset --hard` ne détruit aucun objet

## Variantes

- **Salle sans réseau ou sans compte GitHub (vérifié).** Le script de setup produit `17-internals.bundle`, un fichier unique d'environ 2 Ko. Le distribuer par clé USB ou partage réseau, puis : `git clone -b 17-internals 17-internals.bundle 17-internals`. Testé : `git count-objects -vH` donne alors exactement `count: 0`, `in-pack: 18`, `packs: 1`, c'est-à-dire le même état qu'un clone GitHub, donc l'étape 2 de l'énoncé reste juste. Ne jamais distribuer par copie de dossier ni par `git clone ../src` : un clone par chemin local recopie la base par liens physiques et donne `count: 18`, `packs: 0`. Cette variante est aussi une publicité pour `git bundle`, à relier au chapitre bonus si l'occasion se présente.
- **Poste verrouillé, pas de droit d'écriture hors du profil utilisateur.** L'exercice n'installe rien, ne touche à aucune configuration globale (les deux `git config` sont locaux au dépôt) et n'écrit que dans le dossier de travail. Aucune adaptation nécessaire. Seule contrainte réelle : disposer d'un vrai terminal Bash. Sur un poste où seul PowerShell est autorisé, la plupart des commandes `git` passent, mais `printf`, `find`, `wc`, `sha1sum` et la syntaxe `$(...)` ne fonctionnent pas telles quelles. Prévoir le mode binôme sur le poste d'un participant équipé de Git Bash.
- **Windows Git Bash.** Créer impérativement les fichiers avec les commandes `printf` de l'énoncé, jamais avec Notepad ni l'éditeur de l'IDE : les fins de ligne CRLF changent les hashes si `core.autocrlf` est à `false`. Vérifier au passage `git config --get core.autocrlf` en début d'exercice : la valeur `true` posée par l'installeur officiel neutralise le problème. Les chemins de `.git/objects` s'écrivent avec des barres obliques normales dans Git Bash.
- **macOS.** Remplacer `sha1sum` par `shasum` à l'étape 6 si la commande n'existe pas. Toutes les autres commandes sont identiques.
- **Groupe en avance (15 minutes de plus).** Trois prolongements testés ou immédiats : fabriquer un troisième commit de fusion en passant deux fois `-p` à `git commit-tree` et constater que `git log --graph` dessine bien une fusion ; fabriquer un objet `tag` annoté avec `git mktag` puis le lire avec `git cat-file -p` pour compléter le quatuor blob/tree/commit/tag de la slide ; ou lancer `git verify-pack -v` sur le packfile d'un vrai dépôt d'entreprise volumineux et trier par taille avec `sort -k3 -n -r | head` pour trouver les plus gros blobs de l'historique, ce qui est le point d'entrée réel du sujet « mon dépôt fait 4 Go ».
- **Groupe en retard (20 minutes de moins).** Jouer les étapes 0 à 13 en autonomie (les 40 minutes qui portent le message central) et transformer les étapes 14 à 17 en démonstration projetée de 10 minutes. Ne pas sacrifier l'étape 11 (le commit invisible) ni l'étape 15 (le reflog qui masque l'orphelin), ce sont les deux moments qui font basculer la compréhension.
- **Public non développeur (chefs de projet, architectes).** Faire jouer les parties 1 et 2 en binôme, un participant au clavier et l'autre qui lit l'énoncé à voix haute et note les hashes obtenus sur une feuille. Le passage à l'écrit des hashes est ce qui fait constater qu'ils sont identiques d'un binôme à l'autre, sans avoir à comprendre le shell.
