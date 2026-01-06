# Un dépôt, plusieurs répertoires : git worktree en conditions réelles

> Une fonctionnalité est commencée et non commitée, le taux de TVA est faux en production : il faut livrer le correctif tout de suite, sans mettre son travail de côté.

**Niveau** : intermédiaire | **Durée estimée** : 50 min

## Prérequis

- Git installé (l'exercice a été validé sur Git 2.54.0 ; `git worktree add/list/prune` existe depuis Git 2.5, `remove` et `move` depuis Git 2.17, l'annotation `prunable` de `git worktree list` depuis Git 2.36)
- Savoir créer une branche et basculer dessus (`git switch`, `git switch -c`) : jour 1, chapitre 07
- Savoir fusionner avec `git merge --no-ff` et lire `git log --oneline --graph --all` : jour 1, chapitre 08
- Avoir vu `git stash` : jour 2, chapitre 04 (sert de point de comparaison, pas d'outil)
- Savoir ce qu'est un fichier ignoré par `.gitignore` : jour 1, chapitre 05
- Un terminal capable de faire `cd ..` sans se perdre. Sous Windows : Git Bash, pas PowerShell
- Aucun compte GitHub personnel n'est nécessaire au-delà du `git clone` public initial ; Docker n'est jamais lancé, le `docker-compose.yml` est seulement lu

## 1. Cloner l'exercice et regarder l'état de départ

Cloner la branche `12-worktree` du dépôt d'exercices, entrer dans le dossier, puis observer l'historique et la liste des répertoires de travail. Le dépôt contient trois fichiers YAML, un `docker-compose.yml`, un `.gitignore`, une branche `feat/export` déjà commencée et un tag `v1.0.0` qui correspond à ce qui tourne en production. Les identifiants de commit affichés dans cet énoncé proviennent d'une exécution de référence : ceux des commits que vous créerez seront différents, seule la forme du graphe compte. Sous Windows, travailler dans Git Bash, pas dans PowerShell.

```bash
git clone -b 12-worktree https://github.com/FabienSalles/git-exercices.git 12-worktree
cd 12-worktree
git log --oneline --graph --all
git worktree list
```

Résultat attendu :

```
* a95f262 docs: enonce de l exercice worktree
| * 1c38e80 feat: export.yaml
|/
* dae26ae feat: tva.yaml
* 0888e1e chore: docker compose
* 1de444e feat: societe.yaml
* a4b194e feat: contact.yaml

/chemin/vers/12-worktree a95f262 [12-worktree]
```

> **Question** : `git worktree list` affiche déjà une ligne alors qu'aucun worktree n'a été créé. Qu'est-ce que cette ligne désigne, et qu'en déduisez-vous sur ce qu'est un clone ordinaire ?

## 2. Reconstituer un environnement local

Un vrai projet a des fichiers qui ne sont pas dans Git : configuration locale, dépendances installées, uploads. Les simuler en créant un fichier `.env`, puis vérifier que Git ne le voit pas et lire le `.gitignore`. Retenir ce fichier : il servira de révélateur plus loin.

```bash
printf 'APP_ENV=local\nAPP_SECRET=formation\n' > .env
git status --short --branch
cat .gitignore
```

Résultat attendu :

```
## 12-worktree...origin/12-worktree

.env
node_modules/
```

> **Question** : Le fichier `.env` existe sur le disque et `git status` ne le signale pas. Le `.gitignore`, lui, est versionné. Lequel des deux se retrouvera dans un nouveau répertoire de travail, et pourquoi ?

## 3. Commencer le travail sur feat/export

Basculer sur la branche `feat/export`, puis remplacer le contenu de `yaml/export.yaml` par les quatre lignes ci-dessous. Ne PAS committer : c'est du travail en cours, exactement l'état dans lequel une urgence vous surprend toujours.

```yaml
export:
  format: csv
  separateur: ";"
  encodage: UTF-8
```

```bash
git switch feat/export
# éditer yaml/export.yaml
git status --short
```

Résultat attendu :

```
Switched to a new branch 'feat/export'
branch 'feat/export' set up to track 'origin/feat/export'.

 M yaml/export.yaml
```

> **Question** : Avec les outils vus jusqu'ici, comment feriez-vous pour aller corriger un bug sur la branche principale sans perdre cette modification ? Combien de commandes cela demande-t-il, et que se passe-t-il si vous oubliez la dernière ?

## 4. L'urgence arrive : créer un deuxième répertoire de travail

Le taux de TVA de `yaml/tva.yaml` est faux en production. Il faut livrer le correctif tout de suite, à partir de la branche principale, sans toucher au travail en cours. Réflexe habituel : `git stash`. Réflexe worktree : un deuxième répertoire. La commande se lit : créer le répertoire `../12-worktree-hotfix`, y créer la branche `fix/tva` (option `-b`), en partant de `12-worktree`. Vérifier ensuite que le travail en cours n'a pas bougé.

```bash
git worktree add ../12-worktree-hotfix -b fix/tva 12-worktree
git worktree list
git status --short
```

Résultat attendu :

```
Preparing worktree (new branch 'fix/tva')
HEAD is now at a95f262 docs: enonce de l exercice worktree

/chemin/vers/12-worktree        1c38e80 [feat/export]
/chemin/vers/12-worktree-hotfix a95f262 [fix/tva]

 M yaml/export.yaml
```

> **Question** : Rien n'a été mis de côté et rien n'a été restauré. Quelle est la différence de fond avec `git stash`, du point de vue du risque d'oublier son travail ?

## 5. Explorer le nouveau répertoire

Se déplacer dans le nouveau répertoire, lister son contenu (fichiers cachés compris), afficher le contenu de `.git`, puis vérifier que l'historique complet est visible depuis ici.

```bash
cd ../12-worktree-hotfix
ls -a
cat .git
git log --oneline --graph --all
```

Résultat attendu :

```
.  ..  .git  .gitignore  docker-compose.yml  README.md  yaml

gitdir: /chemin/vers/12-worktree/.git/worktrees/12-worktree-hotfix

* a95f262 docs: enonce de l exercice worktree
| * 1c38e80 feat: export.yaml
|/
* dae26ae feat: tva.yaml
* 0888e1e chore: docker compose
* 1de444e feat: societe.yaml
* a4b194e feat: contact.yaml
```

> **Question** : Ici `.git` est un fichier d'une ligne, pas un répertoire, et le fichier `.env` est absent. Qu'est-ce qui est partagé entre les deux répertoires, et qu'est-ce qui ne l'est pas ? En quoi est-ce différent d'un second `git clone` ?

## 6. Corriger et committer le hotfix

Toujours dans le répertoire `12-worktree-hotfix`, remplacer le contenu de `yaml/tva.yaml` par les trois lignes ci-dessous, puis committer.

```yaml
tva:
  pays: France
  taux: 0.20
```

```bash
git add yaml/tva.yaml
git commit -m "fix(tva): taux a 20 pourcent"
```

Résultat attendu :

```
[fix/tva e4d6a16] fix(tva): taux a 20 pourcent
 1 file changed, 1 insertion(+), 1 deletion(-)
```

> **Question** : Ce commit vient d'être créé dans un autre répertoire que le vôtre. Faudra-t-il un `push` puis un `pull` pour que le répertoire principal le voie ?

## 7. Revenir au travail en cours et le committer

Revenir dans le répertoire principal, constater que la modification est exactement là où elle avait été laissée, puis la committer.

```bash
cd ../12-worktree
git status --short
git add yaml/export.yaml
git commit -m "feat(export): encodage UTF-8"
```

Résultat attendu :

```
 M yaml/export.yaml

[feat/export b0b5f2f] feat(export): encodage UTF-8
 1 file changed, 1 insertion(+)
```

> **Question** : Sur quelle branche êtes-vous ici, et sur quelle branche est l'autre répertoire ? Comment le vérifier en une seule commande, sans changer de dossier ?

## 8. Provoquer les deux refus

Faire échouer volontairement deux commandes. D'abord ouvrir un deuxième répertoire sur la branche actuellement extraite. Ensuite basculer sur la branche du hotfix, qui est extraite ailleurs. Les deux commandes doivent échouer : c'est le but.

```bash
git worktree add ../12-worktree-export feat/export
git switch fix/tva
```

Résultat attendu :

```
Preparing worktree (checking out 'feat/export')
fatal: 'feat/export' is already used by worktree at '/chemin/vers/12-worktree'

fatal: 'fix/tva' is already used by worktree at '/chemin/vers/12-worktree-hotfix'
```

> **Question** : La règle est : une branche ne peut être extraite que dans un seul worktree à la fois. Que se passerait-il si Git l'autorisait, alors que les deux répertoires partagent le même `.git` et donc la même référence de branche ?

## 9. Fusionner le hotfix

Le commit du correctif est déjà dans le dépôt : aucun `fetch`, aucun `pull`, aucun `push`. Basculer sur la branche principale (elle n'est extraite nulle part, la bascule est donc autorisée) et fusionner `fix/tva` en gardant une trace de la fusion.

```bash
git switch 12-worktree
git merge --no-ff fix/tva -m "Merge branch 'fix/tva'"
git log --oneline --graph --all
```

Résultat attendu :

```
Switched to branch '12-worktree'
Your branch is up to date with 'origin/12-worktree'.
Merge made by the 'ort' strategy.
 yaml/tva.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

*   a05b559 Merge branch 'fix/tva'
|\
| * e4d6a16 fix(tva): taux a 20 pourcent
|/
* a95f262 docs: enonce de l exercice worktree
| * b0b5f2f feat(export): encodage UTF-8
| * 1c38e80 feat: export.yaml
|/
* dae26ae feat: tva.yaml
* 0888e1e chore: docker compose
* 1de444e feat: societe.yaml
* a4b194e feat: contact.yaml
```

> **Question** : La bascule vers `12-worktree` a fonctionné alors que la bascule vers `fix/tva` avait été refusée. Quelle est exactement la condition qui distingue les deux cas ?

## 10. Les deux autres formes de worktree add

Maintenant que `feat/export` n'est plus extraite dans le répertoire principal, lui ouvrir son propre répertoire : c'est la forme « branche existante », sans `-b`. Puis ouvrir un répertoire en HEAD détaché sur le tag `v1.0.0` pour comparer le correctif avec ce qui est parti en production : c'est la forme `--detach`. Comparer enfin les deux fichiers `tva.yaml`.

```bash
git worktree add ../12-worktree-export feat/export
git worktree add --detach ../12-worktree-v1 v1.0.0
git worktree list
cat ../12-worktree-v1/yaml/tva.yaml
cat yaml/tva.yaml
```

Résultat attendu :

```
Preparing worktree (checking out 'feat/export')
HEAD is now at b0b5f2f feat(export): encodage UTF-8

Preparing worktree (detached HEAD dae26ae)
HEAD is now at dae26ae feat: tva.yaml

/chemin/vers/12-worktree        a05b559 [12-worktree]
/chemin/vers/12-worktree-export b0b5f2f [feat/export]
/chemin/vers/12-worktree-hotfix e4d6a16 [fix/tva]
/chemin/vers/12-worktree-v1     dae26ae (detached HEAD)

tva:
  pays: France
  taux: 0.196

tva:
  pays: France
  taux: 0.20
```

> **Question** : Le dernier répertoire est annoté `(detached HEAD)` au lieu d'un nom de branche. Que se passerait-il si vous y faisiez un commit, et pourquoi cette forme est-elle la bonne pour simplement regarder une version livrée ?

## 11. Ranger les répertoires

Supprimer les deux répertoires d'inspection avec `git worktree remove`. Puis salir volontairement le répertoire du hotfix et constater que la suppression est refusée, avant de forcer. Vérifier enfin ce qui a disparu et ce qui est resté.

```bash
git worktree remove ../12-worktree-v1
git worktree remove ../12-worktree-export
echo "brouillon" >> ../12-worktree-hotfix/yaml/tva.yaml
git worktree remove ../12-worktree-hotfix
git worktree remove --force ../12-worktree-hotfix
git worktree list
git branch
```

Résultat attendu :

```
fatal: '../12-worktree-hotfix' contains modified or untracked files, use --force to delete it

/chemin/vers/12-worktree a05b559 [12-worktree]

* 12-worktree
  feat/export
  fix/tva
```

> **Question** : Les branches `feat/export` et `fix/tva` sont toujours là après la suppression des répertoires. Que supprime donc exactement `git worktree remove` ? Et que devient un fichier `.env` présent dans le répertoire supprimé, sachant que le refus ne porte que sur les fichiers modifiés ou non suivis ?

## 12. Un worktree par agent

Créer deux répertoires pour deux agents travaillant en parallèle, chacun sur sa branche. Observer `git worktree list` et surtout `git branch`. Puis protéger le répertoire d'un agent en cours d'exécution avec `lock`, et tenter de le supprimer.

```bash
git worktree add ../12-worktree-agent-a -b feat/agent-a
git worktree add ../12-worktree-agent-b -b feat/agent-b
git worktree list
git branch
git worktree lock ../12-worktree-agent-b --reason "agent en cours d execution"
git worktree list
git worktree remove ../12-worktree-agent-b
```

Résultat attendu :

```
/chemin/vers/12-worktree         a05b559 [12-worktree]
/chemin/vers/12-worktree-agent-a a05b559 [feat/agent-a]
/chemin/vers/12-worktree-agent-b a05b559 [feat/agent-b]

* 12-worktree
+ feat/agent-a
+ feat/agent-b
  feat/export
  fix/tva

/chemin/vers/12-worktree         a05b559 [12-worktree]
/chemin/vers/12-worktree-agent-a a05b559 [feat/agent-a]
/chemin/vers/12-worktree-agent-b a05b559 [feat/agent-b] locked

fatal: cannot remove a locked working tree, lock reason: agent en cours d execution
use 'remove -f -f' to override or unlock first
```

> **Question** : Le `+` devant `feat/agent-a` et `feat/agent-b` dans `git branch` signifie « extraite dans un autre worktree ». En quoi cette annotation, combinée au refus de bascule vu plus tôt, garantit-elle que deux agents lancés en parallèle ne peuvent pas écraser le travail l'un de l'autre ?

## 13. Le piège du rm -rf

Supprimer le répertoire de l'agent A à la main, comme on supprimerait un dossier quelconque, puis lister les worktrees. Nettoyer ensuite la fiche administrative laissée derrière, d'abord à blanc (`-n`), puis pour de vrai. Terminer le ménage.

```bash
rm -rf ../12-worktree-agent-a
git worktree list
git worktree prune -n -v
git worktree prune -v
git worktree list
git worktree unlock ../12-worktree-agent-b
git worktree remove ../12-worktree-agent-b
git branch -D feat/agent-a feat/agent-b
```

Résultat attendu :

```
/chemin/vers/12-worktree         a05b559 [12-worktree]
/chemin/vers/12-worktree-agent-a a05b559 [feat/agent-a] prunable
/chemin/vers/12-worktree-agent-b a05b559 [feat/agent-b] locked

Removing worktrees/12-worktree-agent-a: gitdir file points to non-existent location

Removing worktrees/12-worktree-agent-a: gitdir file points to non-existent location

/chemin/vers/12-worktree         a05b559 [12-worktree]
/chemin/vers/12-worktree-agent-b a05b559 [feat/agent-b] locked

Deleted branch feat/agent-a (was a05b559).
Deleted branch feat/agent-b (was a05b559).
```

> **Question** : Le répertoire n'existe plus mais Git en garde la trace, annotée `prunable`. Où cette trace est-elle stockée, et pourquoi `git worktree prune` n'a-t-il pas emporté le worktree annoté `locked` au passage ?

## 14. Là où ça coince

Créer un dernier répertoire de démonstration, lister son contenu et relire le `docker-compose.yml` du projet. Faire ensuite trois constats à voix haute : 1) aucun `.env` ni `node_modules/` dans le nouveau répertoire, et il n'y en aura jamais, il faut rejouer l'installation (`cp ../12-worktree/.env ../12-worktree-demo/.env`, puis `npm install`, `composer install`) ; le `.gitignore`, lui, est versionné et bien présent ; 2) le `docker-compose.yml` publie le port 8080, donc deux `docker compose up` dans deux worktrees et le second échoue, il faut un port et un fichier de surcharge par worktree ; 3) le volume `./yaml` est relatif au répertoire courant, chaque worktree monte donc ses propres fichiers. Vérifier enfin qu'un worktree créé DANS le dépôt apparaît comme un répertoire non suivi, puis tout ranger.

```bash
git worktree add ../12-worktree-demo -b feat/demo
ls -a ../12-worktree-demo
cat docker-compose.yml
git worktree add ./sous-worktree -b feat/dedans
git status --short
git worktree remove ./sous-worktree
git branch -D feat/dedans
git worktree remove ../12-worktree-demo
git branch -D feat/demo
git worktree list
```

Résultat attendu :

```
.  ..  .git  .gitignore  docker-compose.yml  README.md  yaml

?? sous-worktree/

/chemin/vers/12-worktree a05b559 [12-worktree]
```

> **Question** : Le slide dit « worktree est gratuit côté Git, jamais côté environnement ». Sur votre projet réel, listez trois fichiers ou services qu'il faudrait reconstruire à chaque nouveau worktree. Combien de temps cela prendrait-il, et qu'est-ce que cela change à l'intérêt de la commande ?

## Résultat final attendu

```
État obtenu réellement en fin d'exercice dans le bac à sable (Git 2.54.0, macOS), après le ménage complet.

$ git worktree list
/chemin/vers/12-worktree a05b559 [12-worktree]

$ git branch
* 12-worktree
  feat/export
  fix/tva

$ git log --oneline --graph --all
*   a05b559 Merge branch 'fix/tva'
|\
| * e4d6a16 fix(tva): taux a 20 pourcent
|/
* a95f262 docs: enonce de l exercice worktree
| * b0b5f2f feat(export): encodage UTF-8
| * 1c38e80 feat: export.yaml
|/
* dae26ae feat: tva.yaml
* 0888e1e chore: docker compose
* 1de444e feat: societe.yaml
* a4b194e feat: contact.yaml

$ git status --short --branch
## 12-worktree...origin/12-worktree [ahead 2]

$ cat yaml/tva.yaml
tva:
  pays: France
  taux: 0.20

Lecture : un seul répertoire de travail restant, la branche principale contient le correctif fusionné, la branche `feat/export` a bien conservé le travail commencé sans jamais avoir été mise de côté, et les branches `feat/agent-a`, `feat/agent-b`, `feat/demo`, `feat/dedans` ont été supprimées avec leurs répertoires. Les cinq identifiants a4b194e, 1de444e, 0888e1e, dae26ae et 1c38e80 sont identiques chez tous les participants ; a95f262 dépend du texte de l'énoncé publié ; e4d6a16, b0b5f2f et a05b559 sont propres à chaque exécution.
```

## Critères de réussite

- `git worktree list` ne renvoie plus qu'une seule ligne en fin d'exercice, celle du répertoire principal
- `git branch` montre `12-worktree`, `feat/export` et `fix/tva`, et plus aucune branche d'agent ni de démonstration
- `git log --oneline --graph --all` montre le commit de fusion `Merge branch 'fix/tva'` au sommet de la branche principale, et la branche `feat/export` toujours divergente avec ses deux commits
- `cat yaml/tva.yaml` affiche `taux: 0.20` dans le répertoire principal
- Le participant sait dire sans hésiter quelles sont les trois formes de `git worktree add` (`-b`, branche existante, `--detach`) et à quel besoin chacune répond
- Le participant a provoqué les deux refus (`worktree add` sur branche extraite, `git switch` sur branche extraite ailleurs) et peut reformuler la règle « une branche, un worktree » ainsi que la raison technique (les deux répertoires partagent la même référence de branche)
- Le participant peut expliquer pourquoi le commit fait dans le worktree du hotfix a été fusionnable sans aucun `push` ni `pull`
- Le participant a constaté de ses yeux l'absence de `.env` dans un nouveau worktree et peut citer deux autres choses à reconstruire sur son projet réel
- Le participant sait quoi faire quand `git worktree list` affiche `prunable` et quand il affiche `locked`
- Le participant est capable de dire dans quel cas il préférera encore `git stash` à un worktree

## Variantes

- HORS LIGNE / SANS COMPTE GITHUB : le formateur distribue un bundle fabriqué avec `git bundle create 12-worktree.bundle --all` depuis le dépôt de setup. Les participants remplacent la première commande par `git clone -b 12-worktree 12-worktree.bundle 12-worktree`. Tout le reste de l'exercice est strictement local : aucun `push`, `pull` ou `fetch` n'y figure, c'est même l'un des enseignements de l'étape 9. Variante non exécutée en bac à sable, la commande `git bundle` est reprise du mémo de recherche et reste à valider par le formateur.
- SANS RÉSEAU DU TOUT ET SANS CLÉ USB : faire fabriquer le dépôt de départ par les participants eux-mêmes en dictant le script de setup (5 minutes), ou repartir du dépôt de l'exercice 01-intro déjà cloné le jour 1 en y ajoutant une branche `feat/export` et un tag. L'exercice n'a besoin que d'un dépôt avec deux branches et un tag.
- POSTE VERROUILLÉ (pas de droit d'écriture hors du dossier utilisateur) : imposer un dossier de travail court dans le profil utilisateur, par exemple `C:\git\` ou `~/git/`. Les worktrees étant créés en `../`, ils atterrissent à côté du clone, donc dans le même dossier parent. Aucune installation, aucun service, aucun port ouvert n'est nécessaire : Docker n'est jamais lancé, le `docker-compose.yml` est seulement lu.
- WINDOWS GIT BASH : remplacer les deux `printf` par une édition dans l'éditeur configuré au jour 1. Travailler dans un chemin court et sans espace. Si un chemin avec espace est inévitable, guillemeter systématiquement (`git worktree add "../mon dossier" -b tmp/espace` fonctionne, vérifié).
- GROUPE EN AVANCE (+15 min) : faire lancer un vrai serveur dans deux worktrees pour vivre le conflit de ports. Sans Docker : `python3 -m http.server 8080` dans le premier répertoire, puis la même commande dans le second, qui échoue avec `Address already in use`. Enchaîner sur l'écriture d'un `docker-compose.override.yml` par worktree, ou sur une variable `${WEB_PORT:-8080}` dans le `docker-compose.yml`. Non exécuté en bac à sable.
- GROUPE EN AVANCE, VARIANTE AGENTS IA : lancer réellement deux agents en parallèle, un par worktree, sur deux tâches indépendantes (par exemple ajouter `yaml/velo.yaml` dans l'un, `yaml/moto.yaml` dans l'autre), puis fusionner les deux branches dans la principale. Le point à faire ressortir : les deux agents n'ont jamais eu à se coordonner sur un `git switch`, et la fusion est un merge ordinaire. Suppose que les postes disposent d'un agent, ce qui est rarement le cas en salle Orsys : à réserver à une démonstration formateur.
- GROUPE À LA PEINE (-15 min) : s'arrêter après l'étape 9 (fusion du hotfix). Les étapes 10 à 14 deviennent une démonstration formateur de 6 minutes, écran partagé, en insistant sur `prunable` et sur le slide « là où ça coince ». Le cœur pédagogique (créer un worktree, ne pas perdre son travail, une branche un worktree) est acquis dès l'étape 9.
- EXERCICE EN BINÔME : l'un tient le clavier dans le répertoire principal, l'autre dans le répertoire du hotfix, chacun avec son terminal. C'est la meilleure façon de faire ressentir que deux personnes travaillent en même temps sur le même dépôt sans se gêner, et cela supprime d'un coup le piège de la perte de repères entre répertoires.
