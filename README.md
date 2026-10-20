# Exercice Submodule et Subtree : embarquer une bibliothèque partagée, deux fois

> Un collègue clone votre application, lance le projet, et rien ne démarre : le dossier `lib/` est là, mais il est vide.

**Niveau** : avancé | **Durée estimée** : 60 min

## Prérequis

- Jour 1 complet : init, clone, add, commit, status, log --oneline --graph, branches, switch, HEAD détachée, tags.
- Jour 1 chapitre 09-repository : remote, fetch, pull, push, branches de suivi.
- Chapitre day-2/slides/11-submodules-subtrees.md vu en cours (vocabulaire pointeur, .gitmodules, avertissement sur la complexité).
- Un terminal bash. Sous Windows, Git Bash (le script de mise en place est du bash).
- Git >= 2.28 (option git init -b main). Vérifié sur Git 2.54.0.
- Aucun compte GitHub, aucun réseau, aucune installation : les dépôts distants sont fabriqués localement.

## 1. Mise en place : cloner la branche et fabriquer le matériel

Cloner la branche de l'exercice, puis lancer le script qui fabrique les dépôts. Le script crée trois dépôts nus (le rôle de GitHub) et trois clones de travail. Aucun compte ni réseau n'est nécessaire : tout est local.

```bash
git clone -b 13-submodule-subtree https://github.com/FabienSalles/git-exercices.git 13-submodule-subtree
cd 13-submodule-subtree
bash setup.sh
```

Résultat attendu :

```
Materiel pret :
  serveur/lib-yaml.git  serveur/app-submodule.git  serveur/app-subtree.git
  lib-yaml/  app-submodule/  app-subtree/

Rôle de chaque dossier :
  serveur/lib-yaml.git       dépôt nu de la bibliothèque partagée, 3 commits, tag v1.0.0
  serveur/app-submodule.git  dépôt nu de l'application, volet A
  serveur/app-subtree.git    dépôt nu de la même application, volet B
  lib-yaml/                  clone de travail de la bibliothèque (le mainteneur de la lib)
  app-submodule/             clone de travail de l'application, volet A
  app-subtree/               clone de travail de l'application, volet B
```

> **Question** : Pourquoi les dépôts du dossier serveur/ portent-ils le suffixe .git et ne contiennent-ils aucun fichier YAML visible ?

## 2. Mise en place : autoriser le protocole fichier dans ce terminal

Depuis Git 2.38.1, Git refuse de cloner un submodule dont l'URL est un simple chemin de fichier. C'est un garde-fou de sécurité (CVE-2022-39253) : un dépôt piégé pouvait faire cloner un chemin local arbitraire. Comme les dépôts de cet exercice sont locaux, il faut lever ce garde-fou. La commande est à refaire dans chaque nouveau terminal ouvert pendant l'exercice. Elle ne modifie aucune configuration Git : elle ne vaut que pour le terminal courant.

```bash
export GIT_ALLOW_PROTOCOL=file
```

Résultat attendu :

```
Aucune sortie. Si plus tard une commande échoue avec `fatal: transport 'file' not allowed`, c'est que cette ligne n'a pas été tapée dans le terminal courant : la retaper.

À noter : `git config protocol.file.allow always` posé dans le dépôt ne suffit pas, le clone du submodule est un autre dépôt et ne lit pas cette configuration.
```

> **Question** : Dans la vraie vie, l'URL d'un submodule est en https:// ou ssh://. Pourquoi ce garde-fou ne gêne-t-il jamais en entreprise ?

## 3. Mise en place : constater l'état de départ

Regarder les deux historiques de départ. Les empreintes de ces commits sont fabriquées avec des dates figées : elles sont identiques sur toutes les machines. En revanche, les empreintes des commits que vous allez créer seront différentes des exemples de cet énoncé : seule la forme des sorties compte.

```bash
git -C lib-yaml log --oneline --decorate
git -C app-submodule log --oneline
```

Résultat attendu :

```
3252fdb (HEAD -> main, tag: v1.0.0, origin/main, origin/HEAD) feat: societe.yaml
000553d feat: contact.yaml
5ecbd1d chore: commit initial

c802c3e feat: app.yaml
c7b6522 chore: commit initial
```

> **Question** : Les deux dépôts n'ont aucun commit en commun. Que faudrait-il pour que l'application puisse malgré tout embarquer la bibliothèque ?

## 4. A1. Se placer dans l'application

Le volet A traite le besoin avec un submodule. Entrer dans le clone de travail de l'application et vérifier que c'est un dépôt tout à fait ordinaire.

```bash
cd app-submodule
git remote -v
```

Résultat attendu :

```
origin	/chemin/absolu/vers/serveur/app-submodule.git (fetch)
origin	/chemin/absolu/vers/serveur/app-submodule.git (push)
```

> **Question** : Rien ne distingue encore ce dépôt d'un dépôt classique. Qu'est-ce qui va changer dans le prochain commit ?

## 5. A2. Ajouter la bibliothèque en submodule

La bibliothèque est le dépôt voisin de l'application sur le serveur. Son URL s'écrit donc `../lib-yaml.git`, relative à l'URL du dépôt distant de l'application. Ajouter la bibliothèque dans un dossier `lib`, puis observer ce que Git a préparé sans encore committer.

```bash
git submodule add ../lib-yaml.git lib
git status --short
cat .gitmodules
git diff --cached lib
```

Résultat attendu :

```
Cloning into '.../app-submodule/lib'...
done.

A  .gitmodules
A  lib

[submodule "lib"]
	path = lib
	url = ../lib-yaml.git

diff --git a/lib b/lib
new file mode 160000
index 0000000..3252fdb
--- /dev/null
+++ b/lib
@@ -0,0 +1 @@
+Subproject commit 3252fdbffcbf635aa6ad660f8ffdb9c5d79ee8be
```

> **Question** : Le dossier lib/ contient trois fichiers YAML. Pourquoi le git diff ne montre-t-il qu'une seule ligne, et pas trois fichiers ajoutés ?

## 6. A3. Committer le pointeur et publier

Committer, puis regarder l'arbre du commit. Le mode 160000 est le mode « lien vers un commit » : un submodule n'est ni un fichier (100644) ni un dossier (040000), c'est une empreinte de commit épinglée dans l'arbre du dépôt principal. Publier ensuite l'application.

```bash
git commit -m "feat: ajout de lib-yaml en submodule"
git ls-tree HEAD
git submodule status
git push origin main
```

Résultat attendu :

```
100644 blob fa02740...	.gitmodules
100644 blob 058beaf...	README.md
100644 blob b576a12...	app.yaml
160000 commit 3252fdbffcbf635aa6ad660f8ffdb9c5d79ee8be	lib

 3252fdbffcbf635aa6ad660f8ffdb9c5d79ee8be lib (v1.0.0)
```

> **Question** : Si la bibliothèque publie dix commits demain, le contenu de lib/ change-t-il tout seul chez les collègues ?

## 7. A4. Ce que voit un collègue qui clone

Simuler un collègue : revenir à la racine de l'exercice et cloner l'application comme il le ferait, sans rien connaître des submodules.

```bash
cd ..
git clone serveur/app-submodule.git app-collegue
ls -A app-collegue/lib
git -C app-collegue submodule status
```

Résultat attendu :

```
La commande ls ne renvoie rien : le dossier lib existe et il est vide.

-3252fdbffcbf635aa6ad660f8ffdb9c5d79ee8be lib

C'est l'incident classique : le clone est correct, l'application ne démarre pas. Le tiret en début de ligne de git submodule status signifie « submodule non initialisé ».
```

> **Question** : Le collègue a fait un git clone correct et il a pourtant un dépôt inutilisable. Où est passée l'information qui manque, et pourquoi Git ne l'a-t-il pas récupérée ?

## 8. A5. Initialiser le submodule et comparer les deux configurations

Initialiser le submodule chez le collègue, puis comparer les deux fichiers qui portent son URL. `--init` inscrit le submodule dans la configuration locale, `--recursive` traite les submodules de submodules.

```bash
cd app-collegue
git submodule update --init --recursive
cat .gitmodules
git config --local --list | grep submodule
```

Résultat attendu :

```
Submodule 'lib' (.../serveur/lib-yaml.git) registered for path 'lib'
Cloning into '.../app-collegue/lib'...
done.
Submodule path 'lib': checked out '3252fdbffcbf635aa6ad660f8ffdb9c5d79ee8be'

[submodule "lib"]
	path = lib
	url = ../lib-yaml.git

submodule.lib.active=true
submodule.lib.url=/chemin/absolu/vers/serveur/lib-yaml.git

.gitmodules est versionné et contient l'URL relative. .git/config est local et contient l'URL résolue. C'est submodule init qui recopie l'une dans l'autre.

En une seule commande, au clonage, on aurait évité l'aller-retour :
  git clone --recurse-submodules serveur/app-submodule.git app-collegue
```

> **Question** : Pourquoi Git recopie-t-il l'URL dans .git/config au lieu de lire .gitmodules à chaque commande ?

## 9. A6. La HEAD détachée du submodule

Regarder sur quelle branche se trouve le submodule fraîchement initialisé.

```bash
git -C lib status
```

Résultat attendu :

```
HEAD detached at 3252fdb
nothing to commit, working tree clean

Le submodule n'est sur aucune branche, et c'est voulu : le dépôt principal épingle un commit, pas une branche. Un commit fait ici n'appartiendrait à aucune branche et serait perdu au prochain git submodule update.

Règle à retenir : dans un submodule, on ne committe pas sans s'être d'abord rattaché à une branche avec git switch main.
```

> **Question** : Pourquoi Git ne place-t-il pas simplement le submodule sur main ? Que se passerait-il si deux commits différents de l'application épinglaient deux commits différents de la bibliothèque ?

## 10. A7. La bibliothèque évolue

Prendre le rôle du mainteneur de la bibliothèque : revenir dans son clone de travail, créer le fichier velo.yaml, le committer et le publier.

```bash
cd ../lib-yaml
# créer le fichier velo.yaml avec le contenu :
#   velo:
#     marque: Look
#     modele: 576
git add velo.yaml
git commit -m "feat: velo.yaml"
git push origin main
```

Résultat attendu :

```
Un commit `feat: velo.yaml` publié sur serveur/lib-yaml.git. À ce stade, l'application ne sait rien de ce commit.
```

> **Question** : Combien de dépôts contiennent maintenant ce nouveau commit ?

## 11. A8. Mettre à jour le pointeur, méthode du support

C'est le workflow présenté en cours : entrer dans le submodule, le mettre à jour, ressortir, committer le pointeur. Observer au passage ce que dit git status du dépôt principal.

```bash
cd ../app-submodule/lib
git switch main
git pull
cd ..
git status
git diff --submodule=log
git add lib
git commit -m "chore: mise a jour du pointeur lib-yaml"
git show --stat HEAD
git push origin main
```

Résultat attendu :

```
Changes not staged for commit:
	modified:   lib (new commits)

Submodule lib 3252fdb..8b7701c:
  > feat: velo.yaml

 lib | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

Le commit de l'application ne contient qu'une ligne modifiée : l'ancienne empreinte remplacée par la nouvelle.
```

> **Question** : Pourquoi git add lib et non git add lib/velo.yaml ?

## 12. A9. Le raccourci git submodule update --remote

La bibliothèque publie une correction. Dans lib-yaml, remplacer la ville de contact.yaml par Bordeaux, committer et publier. Côté application, la mise à jour tient cette fois en une seule commande.

```bash
cd ../lib-yaml
# contact.yaml devient :
#   contact:
#     prenom: Jean
#     nom: Dupont
#     ville: Bordeaux
git add contact.yaml
git commit -m "fix(contact): ville"
git push origin main

cd ../app-submodule
git submodule update --remote lib
git submodule status
git -C lib status
git add lib
git commit -m "chore: mise a jour du pointeur lib-yaml"
git push origin main
```

Résultat attendu :

```
From .../serveur/lib-yaml
   8b7701c..a744d58  main       -> origin/main
Submodule path 'lib': checked out 'a744d58c4a5eed5a1127dac94747233d40a6a721'

+a744d58c4a5eed5a1127dac94747233d40a6a721 lib (v1.0.0-2-ga744d58)

HEAD detached at a744d58

Le signe + de git submodule status signifie « le commit sorti n'est pas celui qui est épinglé ». Deux différences avec l'étape précédente : --remote suit la branche distante du submodule (main par défaut, configurable via submodule.lib.branch) au lieu de suivre l'empreinte épinglée, et il laisse le submodule en HEAD détachée.
```

> **Question** : git submodule update et git submodule update --remote ne font pas la même chose. Laquelle des deux ramène le dépôt à l'état voulu par le dernier commit de l'application ?

## 13. A10. Corriger la bibliothèque depuis l'application et rencontrer la référence cassée

Un bug est repéré dans la bibliothèque pendant le développement de l'application. On le corrige sur place. Se rattacher d'abord à une branche, comme vu en A6, sinon le commit serait perdu. Puis publier l'application avec vérification.

```bash
cd lib
git switch main
git pull
# societe.yaml devient :
#   societe:
#     nom: Orange
#     ville: Lyon
git add societe.yaml
git commit -m "fix(societe): ville"
cd ..
git add lib
git commit -m "chore: mise a jour du pointeur lib-yaml"
git push --recurse-submodules=check origin main
```

Résultat attendu :

```
The following submodule paths contain changes that can
not be found on any remote:
  lib

Please try

	git push --recurse-submodules=on-demand

or cd to the path and use

	git push

to push them to a remote.

fatal: Aborting.

Git refuse : le commit de la bibliothèque n'existe que sur le poste. Un git push ordinaire aurait réussi et cassé le dépôt pour tout le monde, car le pointeur désignerait un commit introuvable.

Puis :
  git push --recurse-submodules=on-demand origin main

Pushing submodule 'lib'
To .../serveur/lib-yaml.git
   a744d58..b7d8722  main -> main
To .../serveur/app-submodule.git
   149bc1c..58510ec  main -> main
```

> **Question** : Pourquoi ce garde-fou n'est-il pas actif par défaut ? Que faudrait-il configurer pour ne plus jamais l'oublier ?

## 14. A11. Ce que voit le collègue qui met à jour

Revenir dans le clone du collègue et faire ce que tout le monde fait : un git pull. Puis regarder le contenu réel du fichier avant de conclure.

```bash
cd ../app-collegue
git pull
git status
cat lib/societe.yaml
git submodule update
cat lib/societe.yaml
```

Résultat attendu :

```
Fetching submodule lib
Updating c83254f..58510ec
Fast-forward
 lib | 2 +-

Changes not staged for commit:
	modified:   lib (new commits)

societe:
  nom: Orange
  ville: Guyancourt

Le git pull a récupéré le nouveau pointeur, mais le contenu de lib/ est resté à l'ancienne version, et le dépôt apparaît modifié alors que rien n'a été touché à la main. Après git submodule update :

Submodule path 'lib': checked out 'b7d8722f107a9cdbcd75ef810795bca86c06c63e'

societe:
  nom: Orange
  ville: Lyon
```

> **Question** : Combien de commandes faut-il connaître pour travailler sur un projet à submodules sans jamais se tromper ? Est-ce raisonnable pour une équipe de dix personnes ?

## 15. B1. Se placer dans la seconde application

Le volet B traite exactement le même besoin, avec un subtree. Le support présente le mécanisme en quatre commandes (remote add, fetch, checkout -b, read-tree) : la commande git subtree, livrée avec Git, fait la même chose en une seule fois. Vérifier que le dépôt de départ est identique à celui du volet A.

```bash
cd ../app-subtree
git log --oneline
```

Résultat attendu :

```
c802c3e feat: app.yaml
c7b6522 chore: commit initial

C'est le même dépôt de départ que le volet A, sans le submodule.
```

> **Question** : Avant de taper quoi que ce soit : où vont vivre les fichiers de la bibliothèque, cette fois ?

## 16. B2. Intégrer la bibliothèque avec git subtree add

Épingler volontairement la version v1.0.0, comme le submodule épinglait un commit. L'option --squash écrase l'historique de la bibliothèque en un seul commit au lieu de le déverser entièrement dans celui de l'application.

```bash
git subtree add --prefix=lib ../serveur/lib-yaml.git v1.0.0 --squash
ls lib
git log --oneline --graph
git status --short
```

Résultat attendu :

```
git fetch ../serveur/lib-yaml.git v1.0.0
From ../serveur/lib-yaml
 * tag               v1.0.0     -> FETCH_HEAD
Added dir 'lib'

contact.yaml   README.md   societe.yaml

*   604303e Merge commit '16cfa77...' as 'lib'
|\
| * 16cfa77 Squashed 'lib/' content from commit 3252fdb
* c802c3e feat: app.yaml
* c7b6522 chore: commit initial

git status ne montre rien : le dossier lib/ contient de vrais fichiers versionnés dans le dépôt de l'application. Il n'y a pas de .gitmodules, pas de lib/.git.

Deux points à noter :
  - GIT_ALLOW_PROTOCOL n'a pas été nécessaire ici : git subtree fait un git fetch ordinaire dans le dépôt principal, pas un clone de submodule.
  - l'URL ../serveur/lib-yaml.git est ici un chemin relatif au dossier courant, alors que celle du volet A était relative à l'URL du dépôt distant. Les deux commandes ne lisent pas les chemins de la même façon.
```

> **Question** : D'où vient le commit `Squashed 'lib/' content` ? Que se serait-il passé sans --squash ?

## 17. B3. La bibliothèque évolue à nouveau

Reprendre le rôle du mainteneur de la bibliothèque et publier un nouveau fichier moto.yaml. Penser à récupérer d'abord les commits du volet A.

```bash
cd ../lib-yaml
git pull
# créer moto.yaml :
#   moto:
#     marque: Honda
#     modele: CB500
git add moto.yaml
git commit -m "feat: moto.yaml"
git push origin main
```

Résultat attendu :

```
Un commit `feat: moto.yaml` publié sur serveur/lib-yaml.git, en plus des corrections faites pendant le volet A.
```

> **Question** : L'application du volet B est restée épinglée sur v1.0.0. Combien de commits la séparent maintenant de la bibliothèque ?

## 18. B4. Récupérer la nouvelle version avec git subtree pull

Ramener le contenu à jour de la bibliothèque dans le dossier lib/. L'option --squash doit être répétée à chaque pull.

```bash
cd ../app-subtree
git subtree pull --prefix=lib ../serveur/lib-yaml.git main --squash
ls lib
git log --oneline --graph
```

Résultat attendu :

```
From ../serveur/lib-yaml
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
 lib/contact.yaml | 2 +-
 lib/moto.yaml    | 3 +++
 lib/societe.yaml | 2 +-
 lib/velo.yaml    | 3 +++
 4 files changed, 8 insertions(+), 2 deletions(-)

contact.yaml   moto.yaml   README.md   societe.yaml   velo.yaml

*   674ec8f Merge commit '61c038c...'
|\
| * 61c038c Squashed 'lib/' changes from 3252fdb..3b13af8
* | 604303e Merge commit '16cfa77...' as 'lib'
|\|
| * 16cfa77 Squashed 'lib/' content from commit 3252fdb
* c802c3e feat: app.yaml
* c7b6522 chore: commit initial

Tout le contenu de la bibliothèque, y compris velo.yaml et les corrections du volet A, est arrivé en un commit de fusion.
```

> **Question** : --squash doit être utilisé au add et à chaque pull. Que se passe-t-il si on l'oublie une fois ?

## 19. B5. Corriger la bibliothèque depuis l'application et renvoyer la correction

Modifier lib/moto.yaml pour lui ajouter une année, et committer. C'est un commit ordinaire de l'application. Pour le renvoyer à la bibliothèque, il faut l'extraire du sous-dossier avec git subtree push, qui rejoue tout l'historique du dossier lib/ pour en fabriquer une branche autonome.

```bash
# lib/moto.yaml devient :
#   moto:
#     marque: Honda
#     modele: CB500
#     annee: 2024
git add lib/moto.yaml
git commit -m "feat(moto): annee"
git subtree push --prefix=lib ../serveur/lib-yaml.git contrib-app

cd ../lib-yaml
git fetch origin
git log --oneline -3 origin/contrib-app
git show --stat origin/contrib-app
```

Résultat attendu :

```
git push using:  ../serveur/lib-yaml.git contrib-app
1/       7 (0) [0]...
To ../serveur/lib-yaml.git
 * [new branch]      3f01508... -> contrib-app

3f01508 feat(moto): annee
3b13af8 feat: moto.yaml
b7d8722 fix(societe): ville

 moto.yaml | 1 +
 1 file changed, 1 insertion(+)

Le préfixe lib/ a disparu : le commit porte bien sur moto.yaml à la racine de la bibliothèque, et il se raccroche à l'historique réel de celle-ci. Une pull request de contrib-app vers main terminerait la contribution.

Sur un vrai dépôt, ce recalcul peut prendre plusieurs minutes.
```

> **Question** : Sur quel critère décide-t-on du nom de la branche poussée ? Que se passerait-il en poussant directement sur main ?

## 20. B6. Ce que voit le collègue qui clone

Publier l'application, puis simuler un collègue qui la clone pour la première fois, sans aucune option particulière.

```bash
cd ../app-subtree
git push origin main
cd ..
git clone serveur/app-subtree.git app-collegue-subtree
ls app-collegue-subtree/lib
```

Résultat attendu :

```
contact.yaml   moto.yaml   README.md   societe.yaml   velo.yaml

Un git clone ordinaire suffit. Aucune option, aucune commande de rattrapage, aucun dossier vide. C'est l'argument principal du subtree.
```

> **Question** : Comparer avec l'étape A4. Quel est le coût de cette simplicité, du point de vue du dépôt ?

## 21. C1. Mesurer la comparaison au lieu de la réciter

Revenir à la racine de l'exercice et comparer les deux dépôts avec les mêmes commandes. Répondre aux questions avant de lire le tableau de synthèse.

```bash
cd ..
git -C app-submodule log --oneline --graph
git -C app-subtree   log --oneline --graph

git -C app-submodule log --oneline -- lib
git -C app-subtree   log --oneline -- lib

git -C app-submodule grep -n Bordeaux
git -C app-subtree   grep -n Bordeaux
```

Résultat attendu :

```
Historique du volet A, strictement linéaire, quatre commits qui ne disent rien du contenu :

* 58510ec chore: mise a jour du pointeur lib-yaml
* 149bc1c chore: mise a jour du pointeur lib-yaml
* 9f23fb6 chore: mise a jour du pointeur lib-yaml
* c83254f feat: ajout de lib-yaml en submodule
* c802c3e feat: app.yaml
* c7b6522 chore: commit initial

Historique du volet B, avec les fusions du subtree :

* e2cf0b9 feat(moto): annee
*   7d3fc5c Merge commit '8628e0d...'
|\
| * 8628e0d Squashed 'lib/' changes from 3252fdb..0240e42
* | 7e06fa3 Merge commit 'af875bf...' as 'lib'
|\|
| * af875bf Squashed 'lib/' content from commit 3252fdb
* c802c3e feat: app.yaml
* c7b6522 chore: commit initial

Et surtout : git grep Bordeaux ne trouve rien dans le dépôt à submodule, et trouve lib/contact.yaml:4 dans le dépôt à subtree. Les outils qui parcourent un dépôt (grep, log -S, blame, la recherche de l'IDE, l'analyse statique de la CI) s'arrêtent à la frontière d'un submodule.
```

> **Question** : Un développeur cherche d'où vient la valeur Bordeaux. Dans lequel des deux dépôts va-t-il la trouver, et combien de temps va-t-il perdre dans l'autre ?

## 22. C2. Le tableau des cinq critères

Comparer ses réponses au tableau de synthèse, puis retenir la règle de choix.

```bash
(aucune commande, temps d'échange)
```

Résultat attendu :

```
| Critère | Submodule | Subtree |
| --- | --- | --- |
| Clonage | git clone seul donne un dossier vide, il faut --recurse-submodules ou submodule update --init | git clone seul suffit, rien à savoir |
| Mise à jour | git pull puis git submodule update, sinon le dépôt paraît modifié sans raison | git pull suffit ; la montée de version est un git subtree pull --squash fait par une seule personne |
| Contribution vers l'amont | naturelle : on committe dans le submodule et on pousse, avec --recurse-submodules=check comme garde-fou | coûteuse : git subtree push recalcule tout l'historique du préfixe |
| Historique et outillage | deux historiques séparés, versions de la lib parfaitement identifiées ; grep, blame et log -- lib du dépôt principal ne voient rien | un seul historique, le code de la lib est cherchable et blâmable comme le reste ; en contrepartie l'historique de l'application est mêlé de commits de fusion |
| Épinglage de version | exact et explicite : une empreinte de commit dans l'arbre, visible dans le git log | implicite : le contenu au moment du dernier subtree pull, sans marqueur de version dans l'arbre |

Une nuance sur la taille, souvent mal comprise : un submodule est léger tant qu'il n'est pas initialisé. Après submodule update --init, les objets de la bibliothèque sont stockés dans .git/modules/lib du dépôt principal. Le poids revient, il est seulement rangé ailleurs.

À retenir :
  - Submodule : pour une dépendance externe consommée à une version précise, à laquelle on contribue de temps en temps.
  - Subtree : pour du code partagé que l'on contrôle, dans une équipe où personne ne doit avoir à connaître de commande particulière.
  - Dans les deux cas : un paquet publié (npm, composer, pip, maven) ne ferait-il pas mieux le travail ?
```

> **Question** : Sur votre projet actuel, lequel des deux choisiriez-vous, et quel critère du tableau emporte la décision ?

## 23. Annexe. Supprimer un submodule proprement

Un rm -rf lib ne suffit pas : il laisse l'entrée dans .gitmodules, l'entrée gitlink dans l'index, et le dépôt caché dans .git/modules. Dérouler la séquence complète sur le clone du collègue, qui ne sert plus.

```bash
cd app-collegue
git submodule deinit -f lib
git rm -f lib
rm -rf .git/modules/lib
git status --short
```

Résultat attendu :

```
Cleared directory 'lib'
Submodule 'lib' (../lib-yaml.git) unregistered for path 'lib'
rm 'lib'

M  .gitmodules
D  lib
```

> **Question** : Trois emplacements à nettoyer pour une seule suppression. Qu'est-ce que cela dit du coût d'entretien d'un projet à submodules ?

## 24. Annexe. Repartir de zéro

Le script de mise en place est idempotent : il supprime et recrée les six dossiers qu'il a fabriqués. Les dossiers app-collegue et app-collegue-subtree créés pendant l'exercice sont à supprimer à la main.

```bash
cd /chemin/vers/13-submodule-subtree
rm -rf app-collegue app-collegue-subtree
bash setup.sh
```

Résultat attendu :

```
Materiel pret :
  serveur/lib-yaml.git  serveur/app-submodule.git  serveur/app-subtree.git
  lib-yaml/  app-submodule/  app-subtree/
```

> **Question** : Pourquoi le script fige-t-il les dates des commits qu'il fabrique ?

## Résultat final attendu

```
Sorties réellement obtenues en sandbox à la fin de la correction complète, depuis un clone neuf de la branche (Git 2.54.0, macOS).

Volet A, historique de l'application à submodule (linéaire, quatre commits qui ne disent rien du contenu de la bibliothèque) :

    * 1cf03fc chore: mise a jour du pointeur lib-yaml
    * ad03798 chore: mise a jour du pointeur lib-yaml
    * bb0231c chore: mise a jour du pointeur lib-yaml
    * 351e7ae feat: ajout de lib-yaml en submodule
    * c802c3e feat: app.yaml
    * c7b6522 chore: commit initial

Volet B, historique de l'application à subtree (deux fusions de subtree) :

    * cd97f56 feat(moto): annee
    *   86aaaf1 Merge commit '736c52edbd2dceafd2bb96c8a7f3c6facfc3f5f9'
    |\
    | * 736c52e Squashed 'lib/' changes from 3252fdb..96e7440
    * | 59cccea Merge commit '0928025776c46c1ad07212b1aad63af0a4377121' as 'lib'
    |\|
    | * 0928025 Squashed 'lib/' content from commit 3252fdb
    * c802c3e feat: app.yaml
    * c7b6522 chore: commit initial

Ce que voit le dépôt principal du contenu de lib/ :

    $ git -C app-submodule log --oneline -- lib
    8f1d8fd chore: mise a jour du pointeur lib-yaml
    2b4f3e2 chore: mise a jour du pointeur lib-yaml
    a10ea7b chore: mise a jour du pointeur lib-yaml
    8639766 feat: ajout de lib-yaml en submodule

    $ git -C app-subtree log --oneline -- lib
    ec9be1d feat(moto): annee
    f9b0829 Merge commit 'c7460e8...'
    0a647f5 Merge commit 'e29adfb...' as 'lib'

Le critère qui frappe le plus en salle :

    $ git -C app-submodule grep -n Bordeaux
    (aucun resultat)
    $ git -C app-subtree grep -n Bordeaux
    lib/contact.yaml:4:  ville: Bordeaux

Et le clone du collègue, volet B, sans aucune option :

    $ ls app-collegue-subtree/lib
    contact.yaml  moto.yaml  README.md  societe.yaml  velo.yaml

Les empreintes c802c3e, c7b6522 et 3252fdb sont fabriquées par setup.sh avec des dates figées : elles seront identiques sur toutes les machines. Toutes les autres varient d'une exécution à l'autre.
```

## Critères de réussite

- `git ls-tree HEAD` dans app-submodule affiche une ligne `160000 commit <sha> lib`, et le participant sait dire ce que signifie 160000.
- Le participant explique sans aide pourquoi le dossier lib/ est vide chez le collègue qui a cloné, et donne la commande de réparation (`git submodule update --init --recursive`).
- Le participant distingue à l'oral .gitmodules (versionné, URL relative) de .git/config (local, URL résolue), et sait quelle commande recopie l'une dans l'autre.
- `git -C lib status` affiche `HEAD detached at <sha>` et le participant énonce la règle : se rattacher à une branche avant de committer dans un submodule.
- Le pointeur a été mis à jour au moins deux fois, une fois par la méthode du support (switch + pull dans le submodule) et une fois avec `git submodule update --remote`, et le participant nomme la différence.
- `git push --recurse-submodules=check` a réellement refusé le push, et le participant explique quelle catastrophe ce refus a évitée.
- Après `git pull` chez le collègue, le participant a constaté que le contenu de lib/ n'avait pas bougé et a corrigé avec `git submodule update` plutôt qu'avec un reset.
- `ls app-subtree/lib` affiche cinq fichiers et `git status` est propre, sans .gitmodules ni lib/.git.
- `git log --oneline --graph` dans app-subtree montre les deux commits `Squashed 'lib/'` et leurs commits de fusion.
- `git log --oneline -3 origin/contrib-app` dans lib-yaml montre le commit `feat(moto): annee` portant sur moto.yaml sans le préfixe lib/.
- `ls app-collegue-subtree/lib` affiche cinq fichiers après un `git clone` sans aucune option.
- `git grep Bordeaux` ne renvoie rien dans app-submodule et renvoie lib/contact.yaml dans app-subtree, et le participant en tire la conséquence sur l'outillage.
- Le participant remplit les cinq critères du tableau de comparaison avec ses propres mots avant de lire le corrigé, et choisit une approche pour son projet en citant le critère décisif.
- Le participant reformule la recommandation d'ouverture : avant submodule ou subtree, se demander si un paquet publié ne ferait pas mieux le travail.

## Variantes

- OFFLINE, SANS COMPTE, POSTE VERROUILLÉ : c'est le mode par défaut, il n'y a pas de variante à prévoir. Les trois dépôts distants sont des dépôts nus créés par setup.sh dans le dossier de l'exercice, aucun compte GitHub, aucun accès réseau et aucune installation ne sont nécessaires après le clonage de la branche. Si même le clonage de la branche est bloqué par le proxy, le formateur distribue le dossier de l'exercice sur clé USB ou en pièce jointe : deux fichiers, README.md et setup.sh, suffisent.
- WINDOWS GIT BASH : lancer toutes les commandes depuis Git Bash. Vérifier avant la session que `git subtree --help` répond (commande de contrib, livrée avec Git for Windows, non vérifiée par l'auteur de cette fiche). Cloner l'exercice près de la racine du disque pour éviter les chemins longs. `export GIT_ALLOW_PROTOCOL=file` fonctionne à l'identique en bash.
- GROUPE EN RETARD, OU MOINS DE 45 MINUTES DISPONIBLES : ne faire que le volet A, jusqu'à l'étape A11 incluse (35 minutes). Le volet B devient une démonstration formateur de 5 minutes sur le vidéoprojecteur, en enchaînant B2, B4 et B6 : cela suffit à faire sentir la différence de coût au clonage. Terminer par le tableau des cinq critères.
- GROUPE EN AVANCE : quatre prolongements, dans cet ordre de rentabilité. 1. Configurer `git config -f .gitmodules submodule.lib.branch main` puis committer, et constater que `git submodule update --remote` n'a plus besoin de savoir quelle branche suivre. 2. `git config --global submodule.recurse true` et refaire un pull chez le collègue : le submodule se met à jour tout seul, discuter du pour et du contre. 3. `git submodule foreach 'git switch main'` sur un projet à plusieurs submodules. 4. `git subtree split --prefix=lib -b lib-extraite` et regarder la branche produite : c'est ce que `subtree push` fabrique en interne.
- GROUPE DÉJÀ ÉQUIPÉ D'UN GITLAB OU GITHUB D'ENTREPRISE : remplacer les dépôts nus locaux par deux dépôts réels et les URL relatives par des URL https. L'étape `export GIT_ALLOW_PROTOCOL=file` devient inutile et doit être retirée de l'énoncé. Le reste est identique. Compter 10 minutes de plus pour la création des dépôts et l'authentification.
- VARIANTE COURTE POUR UN PUBLIC DE CHEFS DE PROJET OU D'ARCHITECTES, 20 MINUTES : le formateur joue A2, A4, A11 et B6 en démonstration, et le groupe ne fait que la partie comparaison (étapes C1 et C2) sur un dépôt déjà préparé. L'objectif devient la décision d'architecture, pas la manipulation.
