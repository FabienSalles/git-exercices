# Jujutsu (jj) : rejouer le nettoyage d'historique de 04-rebase avec un autre modèle mental

> Un collègue annonce qu'il a arrêté d'utiliser git rebase -i depuis six mois, sur les mêmes dépôts Git que tout le monde : il s'agit de comprendre en une heure ce qu'il a gagné, et ce qu'il a accepté de perdre.

**Niveau** : avancé | **Durée estimée** : 60 min

## Prérequis

- Avoir joué l'exercice 04-rebase en Git, ou au minimum avoir vu un rebase interactif se dérouler en direct. Sans ce point de comparaison l'exercice perd tout son intérêt
- Avoir vu le chapitre day-2/slides/02-clean (amend, reset, revert, cherry-pick, rebase -i, fixup et autosquash)
- Savoir lire une sortie de git log --oneline et un graphe de commits
- Savoir naviguer dans un terminal (cd, ls) et éditer un fichier texte
- Git 2.41.0 ou plus récent sur le poste (prérequis annoncé par jj lui-même)
- jj installé, ou à défaut le formateur qui déroule en démonstration au vidéoprojecteur

## 1. Étape 0 : vérifier l'outil et déclarer son identité

Jujutsu (`jj`) est un gestionnaire de versions qui se pose par-dessus un dépôt Git existant. Les commits produits sont de vrais commits Git, poussables sur GitHub. Seule l'interface change, et avec elle le modèle mental.

Vérifier d'abord que l'outil est présent. S'il ne l'est pas, ne rien installer : suivre la démonstration du formateur et lire la section « Si jj n'est pas installable sur le poste » en fin d'énoncé.

Ensuite, déclarer son identité. Point important : `jj` ignore complètement le `git config` du dépôt. Sans cette étape, les commits sont créés avec un auteur vide, et le problème ne se voit qu'après coup.

```bash
jj --version

jj config set --user user.name  "Prénom Nom"
jj config set --user user.email "prenom@exemple.fr"
```

Résultat attendu :

```
jj 0.44.0

Les deux commandes `jj config set` n'affichent rien. Elles écrivent dans le fichier de configuration utilisateur, en dehors de tout dépôt.

Si l'étape est oubliée, `jj log` affichera plus tard `(no email set)` à la place de l'adresse, et la réparation se fait par `jj metaedit --update-author -r @`.
```

> **Question** : Pourquoi jj ne réutilise-t-il pas le user.name et le user.email déjà présents dans le git config du dépôt ? Quel intérêt y a-t-il à séparer les deux identités, et quel risque cela crée-t-il pour quelqu'un qui a plusieurs identités selon les projets ?

## 2. Étape 1 : cloner, puis poser jj par-dessus le dépôt Git

Cloner la branche de l'exercice, puis transformer le clone en dépôt colocated : `.git` et `.jj` cohabiteront dans le même répertoire et verront les mêmes commits.

À noter : depuis la version 0.40, la colocation est le comportement par défaut de `jj git init`. Les tutoriels qui écrivent `jj git init --colocate` ne sont pas faux, le drapeau existe toujours, mais il est devenu redondant.

```bash
git clone -b 14-jj https://github.com/FabienSalles/git-exercices.git 14-jj
cd 14-jj
jj git init
```

Résultat attendu :

```
Done importing changes from the underlying Git repo.
Setting the revset alias `trunk()` to `14-jj@origin`.
Hint: The following remote bookmarks aren't associated with the existing local bookmarks:
  14-jj@origin
Hint: Run the following command to keep local bookmarks updated on future pulls:
  jj bookmark track 14-jj@origin
Initialized repo in "."

Un répertoire `.jj` est apparu à côté de `.git`. Aucun fichier de travail n'a bougé.
```

> **Question** : Les commits du dépôt n'ont pas été recréés ni convertis : jj les a simplement importés. Qu'est-ce que cela implique sur la possibilité de faire marche arrière, et sur ce qu'un collègue qui n'utilise que Git verrait de ce dépôt ?

## 3. Étape 2 : lire le même dépôt avec les deux outils

Afficher l'état courant côté jj, puis le comparer à ce que voit Git. C'est l'étape la plus importante de l'exercice : trois notions y sont visibles d'un coup.

```bash
jj st

git log --oneline -1

jj log

jj log -r 'all()'
```

Résultat attendu :

```
Pour `jj st` :

The working copy has no changes.
Working copy  (@) : xwywltqo c91477ef (empty) (no description set)
Parent commit (@-): xuzsxumn 8a26dfe8 14-jj 14-jj@origin | feat: enoncé de l'exercice

Trois choses à observer :
- `@` désigne la copie de travail, et c'est un COMMIT, ici vide et sans message. Il n'existe pas de « fichiers non commités » en jj.
- Chaque ligne porte DEUX identifiants : `xwywltqo` est le change id (lettres, stable à travers les réécritures), `c91477ef` est le commit id (le SHA Git, qui change à chaque réécriture).
- `@-` désigne le parent de la copie de travail.

Pour `git log --oneline -1` :

8a26dfe feat: enoncé de l'exercice

Git affiche `@-`, pas `@`. Modèle mental à retenir : Git voit le commit d'avant.

Pour `jj log` sans argument : seulement deux lignes, `@` et le sommet de la branche distante marqué d'un losange `◆`.

Pour `jj log -r 'all()'` : les 17 commits, tous marqués `◆`, plus une racine virtuelle `zzzzzzzz root() 00000000`.

Les identifiants affichés chez vous seront différents de ceux de cet énoncé.
```

> **Question** : Pourquoi `jj log` sans argument n'affiche-t-il que deux lignes alors que le dépôt contient 17 commits ? Que cherche à montrer l'outil par défaut, et en quoi cela diffère-t-il du choix fait par `git log` ?

## 4. Étape 3 : travailler sans zone d'index

Modifier `yaml/contact.yaml` : remplacer `Paris` par `Bordeaux` et `75017` par `33000`. Puis, sans rien ajouter, regarder l'état.

Enchaîner ensuite sur le cycle complet : décrire le commit courant, en ouvrir un nouveau, y créer un fichier, puis ranger ce contenu dans le commit précédent. Terminer par l'annulation de cette dernière opération.

Contenu à créer dans `yaml/velo.yaml` :

velo:
    marque: Btwin
    modele: Riverside

```bash
jj st

jj describe -m "fix(contact): déménagement à Bordeaux"

jj new -m "feat(velo): ajout du vélo"
# créer ici le fichier yaml/velo.yaml
jj st

jj squash -u

jj undo

jj op log
```

Résultat attendu :

```
Après la modification, `jj st` affiche :

Working copy changes:
M yaml/contact.yaml
Working copy  (@) : lmmykkso 14a751aa (no description set)
Parent commit (@-): xuzsxumn 8a26dfe8 14-jj 14-jj@origin | feat: enoncé de l'exercice

La modification est DÉJÀ dans le commit `@`. Il n'y a pas eu de `jj add`, et il n'en existe pas.

Après `jj squash -u` (l'équivalent de `git commit --amend`, `-u` conservant le message du commit de destination) :

Working copy  (@) now at: oypnutyw 32631cdd (empty) (no description set)
Parent commit (@-)      : lmmykkso 71d78c7e fix(contact): déménagement à Bordeaux

Après `jj undo` :

Undid operation: d63e9f0d45d8 (2026-08-11 14:00:14) squash commits into b931a299fe36…
Restored to operation: 4b77e76719bc (2026-08-11 14:00:14) snapshot working copy
Working copy  (@) now at: vpyupvum a8ce85e4 feat(velo): ajout du vélo
Parent commit (@-)      : lmmykkso b931a299 fix(contact): déménagement à Bordeaux

Le commit est revenu, AVEC LE MÊME CHANGE ID `vpyupvum`. `jj op log` liste toutes les opérations depuis la création du dépôt, y compris `snapshot working copy`, `describe commit`, `squash commits into`, `undo`.

Repartir propre avant la suite :

jj abandon -r 'description(substring:"vélo")'
jj abandon -r 'description(substring:"déménagement")'
```

> **Question** : `jj undo` annule la dernière opération sur l'ensemble du dépôt, y compris le déplacement des branches. Quel est l'équivalent Git le plus proche, et pourquoi n'est-ce pas un équivalent ? Indice : combien de reflogs y a-t-il dans un dépôt Git ?

## 5. Étape 4 : se heurter à la protection de l'historique partagé, puis la désarmer

Le nettoyage peut commencer. Repérer dans `jj log -r 'all()'` le commit `create app.log`, celui qui a introduit le fichier de log par erreur, et tenter de le supprimer.

Dans la commande, remplacer `ul` par le préfixe de change id affiché sur votre machine : jj accepte n'importe quel préfixe non ambigu.

```bash
jj log -r 'all()'

jj abandon -r ul
```

Résultat attendu :

```
Error: Commit 9d9311c0c14b is immutable
Hint: Could not modify commit: ultylxxq 9d9311c0 create app.log
Hint: Immutable commits are used to protect shared history.
Hint: For more information, see:
      - https://docs.jj-vcs.dev/latest/config/#set-of-immutable-commits
      - `jj help -k config`, "Set of immutable commits"
Hint: This operation would rewrite 13 immutable commits.

C'est le comportement NORMAL, pas une erreur de manipulation. Les commits déjà présents sur le dépôt distant sont immuables par défaut : c'est la règle « on ne réécrit pas un historique partagé » du chapitre précédent, appliquée par l'outil au lieu d'être laissée à la discipline de chacun.

Ici, l'exercice consiste précisément à réécrire cet historique. Il faut donc désarmer explicitement le garde-fou, pour ce dépôt uniquement :

jj config set --repo 'revset-aliases."immutable_heads()"' 'none()'

La commande n'affiche rien. Relancer `jj log -r 'all()'` : les losanges `◆` sont devenus des cercles `○`. Les commits sont redevenus modifiables.

Cette commande contient des guillemets imbriqués : elle est à taper dans Git Bash, pas dans PowerShell ni dans cmd.
```

> **Question** : Git offre-t-il un garde-fou équivalent ? Que se passe-t-il exactement, en Git, si l'on lance `git rebase -i --root` sur une branche déjà poussée, et à quel moment le problème devient-il visible ? Question subsidiaire : préférez-vous un outil qui vous laisse faire ou un outil qui vous arrête ?

## 6. Étape 5 : faire disparaître le fichier de log, et observer l'effet de bord

Relancer l'abandon du commit `create app.log`, maintenant que le garde-fou est désarmé. Puis regarder ce qui est arrivé au commit `fix: remove app.log`, celui qui supprimait ce fichier.

```bash
jj abandon -r ul

jj log -r 'all()'

jj abandon -r st
```

Résultat attendu :

```
Abandoned 1 commits:
  ultylxxq 9d9311c0 create app.log
Rebased 13 descendant commits onto parents of abandoned commits.
Working copy  (@) now at: ourmvsty 75be8675 (empty) (no description set)
Parent commit (@-)      : xuzsxumn 186a3c93 14-jj | feat: enoncé de l'exercice

Les 13 commits suivants ont été rebasés automatiquement. Il n'y a eu ni conflit, ni `--continue`, ni `--abort`, ni éditeur ouvert.

Dans le `jj log -r 'all()'` qui suit, le commit `fix: remove app.log` porte désormais la mention `(empty)` : il supprimait un fichier qui n'existe plus. L'abandonner à son tour :

Abandoned 1 commits:
  stnqntrl a84cec79 (empty) fix: remove app.log
Rebased 9 descendant commits onto parents of abandoned commits.
```

> **Question** : En `git rebase -i`, à quel moment aurait-on découvert que le second commit devenait vide, et qu'aurait affiché Git à ce moment-là ? Que se serait-il passé si l'on avait simplement mis `drop` sur les deux lignes sans réfléchir ?

## 7. Étape 6 : ranger chaque correctif dans son commit d'origine

C'est le geste central de l'exercice. `jj squash --from A --into B` déplace le contenu du commit A dans le commit B, MÊME SI B est un lointain ancêtre de A. L'option `-u` conserve le message du commit de destination et évite l'ouverture d'un éditeur.

Sept correctifs sont à ranger. Relire son `jj log -r 'all()'` avant chaque commande : les préfixes de change id peuvent s'allonger ou se raccourcir au fur et à mesure que des commits disparaissent.

```bash
jj squash --from ws  --into v   -u   # fix: dimensions in voiture.yaml
jj squash --from k   --into v   -u   # fix: poids dans voiture.yaml
jj squash --from ur  --into v   -u   # fix: mv voiture.yaml in yaml folder
jj squash --from ss  --into uzz -u   # fix: birthdate in contact.yaml
jj squash --from wk  --into uzz -u   # fix: french keys in contact.yaml
jj squash --from t   --into r   -u   # fix: societe.yaml missing :
jj squash --from uzs --into r   -u   # fix: mv societe.yaml in yaml folder
```

Résultat attendu :

```
Chaque commande affiche le nombre de commits rebasés derrière, par exemple :

Rebased 13 descendant commits.
Working copy  (@) now at: ourmvsty 18408274 (empty) (no description set)
Parent commit (@-)      : xuzsxumn 1aabfdc9 14-jj | feat: enoncé de l'exercice

À l'arrivée, `jj log -r 'all()'` ne montre plus que 8 commits plus la racine :

@   (vide)
○   feat: enoncé de l'exercice
○   fix: ville dans societe.yaml + puissance dans voiture.yaml (à spliter en 2 commits)
○   feat: contact.yaml
○   chore: logs/.gitkeep
○   chore: .gitignore
○   societe.yaml
○   feat: voiture.yaml
○   chore: commit initial

Noter au passage que le déplacement du fichier (`fix: mv voiture.yaml in yaml folder`) a été absorbé par le commit de création : `feat: voiture.yaml` crée désormais directement `yaml/voiture.yaml`.
```

> **Question** : Combien d'étapes aurait-il fallu en `git rebase -i` pour obtenir le même résultat, et qu'aurait-on dû faire manuellement dans l'éditeur de todo ? Question plus fine : `git commit --fixup` suivi de `git rebase --autosquash` fait-il exactement la même chose, et sur quel point diffère-t-il ?

## 8. Étape 7 : éclater le commit fourre-tout, sans le découper

Le commit `fix: ville dans societe.yaml + puissance dans voiture.yaml` touche deux fichiers pour deux sujets. Le réflexe serait de le découper en deux (`jj split`), puis de déplacer chaque moitié.

Il y a plus court : `jj squash` accepte un CHEMIN en argument. Seul ce chemin est déplacé, le reste demeure dans le commit source.

```bash
jj squash --from ux --into v yaml/voiture.yaml -u

jj squash --from ux --into r -u
```

Résultat attendu :

```
Rebased 7 descendant commits.
Working copy  (@) now at: ourmvsty 24b264e0 (empty) (no description set)
Parent commit (@-)      : xuzsxumn 4494d996 14-jj | feat: enoncé de l'exercice
Rebased 5 descendant commits.

La première commande envoie la ligne `puissanceFiscale` dans `feat: voiture.yaml`. La seconde envoie ce qu'il reste (la ligne `ville`) dans le commit `societe.yaml`. Le commit source devenant vide, il est abandonné automatiquement.

Il ne reste que 7 commits, plus la copie de travail vide.

Variante si le découpage explicite est préféré (elle fonctionne aussi, en deux temps) :

jj split -r ux yaml/voiture.yaml -m "fix(voiture): puissance fiscale"
```

> **Question** : Quelle commande Git aurait permis de déplacer une PARTIE d'un commit vers un autre commit non adjacent ? Combien d'étapes cela aurait-il pris, et laquelle de ces étapes est celle où l'on perd son travail si l'on se trompe ?

## 9. Étape 8 : corriger les messages, puis réordonner

Deux messages restent à reprendre : `societe.yaml` n'est pas un message conventionnel, et `chore: logs/.gitkeep` doit devenir `chore: .gitkeep logs` pour coller au résultat attendu.

Puis réordonner. `jj rebase -r <rév> --after <rév>` et `--before <rév>` déplacent un commit isolé ; les descendants sont rebasés automatiquement. L'ordre visé, du plus ancien au plus récent : commit initial, énoncé, .gitignore, .gitkeep, contact, societe, voiture.

```bash
jj describe -r r -m "feat: societe.yaml"
jj describe -r o -m "chore: .gitkeep logs"

jj rebase -r x   --after  p     # l'énoncé remonte juste après le commit initial
jj rebase -r v   --after  uzz   # voiture passe au sommet
jj rebase -r r   --before v     # societe se glisse juste sous voiture
```

Résultat attendu :

```
Chaque `jj rebase` affiche :

Rebased 1 commits to destination.
Rebased 5 descendant commits.
Working copy  (@) now at: ourmvsty 144c846b (empty) (no description set)
Parent commit (@-)      : vzntqwoz d87171db feat: voiture.yaml

Aucun conflit n'apparaît : les trois fichiers YAML sont indépendants les uns des autres.
```

> **Question** : Dans quel ordre aurait-il fallu déplacer les lignes du fichier de todo de `git rebase -i` pour obtenir le même résultat, et qu'est-ce qui aurait pu échouer en cours de route ? Autre question : en jj, à quel moment décide-t-on de valider le réordonnancement ?

## 10. Étape 9 : relire le résultat, avec jj puis avec Git

Vérifier l'historique final côté jj, puis repositionner le repère `14-jj`, puis relire avec Git pour se convaincre que ce sont bien de vrais commits Git.

Point à ne pas manquer : `14-jj` est un BOOKMARK, l'équivalent d'une branche Git. Il n'a pas suivi les nouveaux commits. En jj, un bookmark ne se déplace jamais tout seul : il n'existe pas de branche « courante ».

```bash
jj log -r 'all()'

jj bookmark set 14-jj -r v

git log --oneline 14-jj

git show --stat 14-jj
```

Résultat attendu :

```
L'historique attendu côté jj, du plus récent au plus ancien :

feat: voiture.yaml
feat: societe.yaml
feat: contact.yaml
chore: .gitkeep logs
chore: .gitignore
feat: enoncé de l'exercice
chore: commit initial

Pour `jj bookmark set` :

Moved 1 bookmarks to vzntqwoz d9825fed 14-jj* | feat: voiture.yaml

Pour `git log --oneline 14-jj` (les hashes seront différents chez vous) :

d9825fe feat: voiture.yaml
1b1f562 feat: societe.yaml
5d5f48e feat: contact.yaml
bc98888 chore: .gitkeep logs
95ebb2f chore: .gitignore
21c81ac feat: enoncé de l'exercice
b4e4ceb chore: commit initial

C'est exactement le résultat attendu par l'exercice 04-rebase. Chaque commit ne porte que sur un seul fichier, à vérifier avec `git show --stat`.
```

> **Question** : Le résultat est identique à celui de l'exercice 04-rebase. Combien de commandes a-t-il fallu de chaque côté ? Et surtout : si le téléphone avait sonné au milieu, laquelle des deux méthodes aurait laissé le dépôt dans un état utilisable ?

## 11. Étape 10 : ce qu'il ne faut jamais faire dans un dépôt colocated

Cette étape est une démonstration, à faire en dernier et sur ce dépôt jetable uniquement.

Dans un dépôt où `.git` et `.jj` cohabitent, les commandes Git qui ÉCRIVENT sont à proscrire : `git commit`, `git rebase`, `git reset`, `git merge`, `git checkout`. Les commandes de LECTURE (`git log`, `git show`, `git diff`, `git status`) sont sans danger et restent utiles.

Faire l'expérience pour comprendre pourquoi. Fermer au préalable son IDE sur ce dépôt : VS Code et les JetBrains lancent des commandes Git en tâche de fond.

```bash
jj new -m "wip: travail jj en cours"
echo "travail jj" > wip.txt
jj st

git add -A && git commit -m "chore: commit fait avec git"

jj st
jj log

jj undo
```

Résultat attendu :

```
Avant le commit Git, `jj st` affiche bien :

Working copy changes:
A wip.txt
Working copy  (@) : lkokzkqr a33944bf wip: travail jj en cours

Après le `git commit`, le `jj st` suivant affiche :

Reset the working copy parent to the new Git HEAD.
The working copy has no changes.
Working copy  (@) : nuxynxxx be977657 (empty) (no description set)
Parent commit (@-): lnyyklny c59b0d9c chore: commit fait avec git

Trois symptômes pour une seule cause :
- jj a réinitialisé le parent de la copie de travail sur le nouveau HEAD Git ;
- il a créé un commit vide et sans description comme nouvelle copie de travail, et ce commit bloquerait un futur `jj git push` ;
- le travail jj en cours est devenu ORPHELIN, visible dans `jj log` comme une branche parallèle, doublon mort du contenu que Git vient de commiter.

`jj undo` répare tout, y compris côté Git : le commit fait avec Git disparaît de `git log`, et la copie de travail jj revient avec `wip.txt` et son change id d'origine.
```

> **Question** : Pourquoi jj a-t-il créé un commit vide plutôt que de reprendre le travail en cours ? Et question pratique : quel outil de votre quotidien risque de lancer une commande Git d'écriture sans vous prévenir, dans un dépôt ouvert dans votre IDE ?

## 12. Annexe : si jj n'est pas installable sur le poste

L'exercice se suit alors en démonstration. Les étapes 2, 4, 5, 7 et 10 sont celles qui portent le message ; les étapes 6 et 8 peuvent être accélérées.

Pour une installation ultérieure sur son poste personnel, avec pour prérequis Git 2.41.0 ou plus récent.

```bash
brew install jj                                # macOS et Linux, Homebrew
winget install jj-vcs.jj                       # Windows, winget
scoop install main/jj                          # Windows, scoop
cargo install --locked --bin jj jj-cli         # toutes plateformes, via Rust
# sans droits administrateur : binaire unique depuis les GitHub Releases du projet
```

Résultat attendu :

```
jj est un binaire unique, sans service ni démon. Une fois le clone fait, l'exercice ne demande aucun accès réseau.

À savoir avant de l'envisager sur un dépôt d'entreprise, ce sont les points qui disqualifient l'outil sur place :
- Git LFS non supporté
- hooks Git non supportés (donc ni pre-commit, ni husky, ni lint-staged)
- sous-modules non supportés
- `.gitattributes` non supporté (donc pas de normalisation de fins de ligne)
- création de tags annotés impossible
- clone partiel non supporté, clone superficiel partiellement supporté
- projet toujours pré-1.0 : chaque version mensuelle apporte des ruptures
```

> **Question** : Parmi ces limites, laquelle serait rédhibitoire sur le dépôt principal de votre équipe ? Et si aucune ne l'est, qu'est-ce qui vous empêcherait quand même d'essayer demain ?

## 13. Annexe : table de correspondance git et jj

Table à conserver après la formation. Elle vaut pour jj 0.44.0. Attention aux tutoriels antérieurs : `jj branch` n'existe plus du tout (remplacé par `jj bookmark`), `--destination` est devenu `--onto`, `--allow-new` a disparu de `jj git push`, et la colocation est devenue le défaut.

```bash
| Intention | Git | jj |
|---|---|---|
| État courant | `git status` | `jj st` |
| Historique | `git log --oneline --graph --all` | `jj log -r 'all()'` |
| Ajouter un fichier | `git add f` | (rien à faire) |
| Terminer un commit | `git commit` | `jj commit` |
| Changer le message courant | `git commit --amend --only` | `jj describe` |
| Amender le contenu | `git commit --amend -a` | `jj squash` |
| Amender partiellement | `git add -p` puis `git commit --amend` | `jj squash -i` |
| Corriger un ancêtre | `git commit --fixup=X` puis `git rebase --autosquash X^` | `jj squash --into X` |
| Déplacer un commit entier dans un autre | (pas d'équivalent direct) | `jj squash --from A --into B` |
| Découper un commit | `git commit -p` | `jj split` |
| Découper un commit quelconque | (pas d'équivalent direct) | `jj split -r <rév>` |
| Réordonner | `git rebase -i` | `jj rebase -r C --before B` |
| Supprimer un commit | `git rebase -i` puis `drop` | `jj abandon -r C` |
| Mettre de côté | `git stash` | `jj new @-` |
| Créer une branche | `git switch -c x` | `jj bookmark create x -r @` |
| Déplacer une branche | `git branch -f x <rév>` | `jj bookmark set x -r <rév>` |
| Annuler la dernière opération | `git reflog` puis `git reset` | `jj undo` |
| Revenir à un état antérieur du dépôt | (pas d'équivalent) | `jj op restore <op>` |
```

Résultat attendu :

```
Deux lignes méritent d'être commentées à l'oral en fin de séance :

- « Déplacer un commit entier dans un autre » et « Découper un commit quelconque » sont les deux seules opérations de cette table qui n'ont pas d'équivalent Git en une commande. Ce sont celles qui ont été pratiquées aux étapes 6 et 7.
- « Revenir à un état antérieur du dépôt » : le reflog Git est par référence, il faut donc restaurer chaque branche une par une. `jj op restore` restaure l'état complet du dépôt en une fois.
```

> **Question** : En regardant cette table, quelle est la commande jj que vous auriez voulu avoir la dernière fois que vous avez cassé un rebase ? Et inversement, qu'est-ce qui, dans la colonne Git, vous manquerait si vous passiez à jj demain ?

## Résultat final attendu

```
Sortie réellement obtenue en sandbox à la fin de la correction, sur le dépôt fabriqué par le script.

Côté jj (`jj log -r 'all()'`, gabarit simplifié) :

@  lu (vide)
○  zu feat: voiture.yaml
○  vo feat: societe.yaml
○  x  feat: contact.yaml
○  s  chore: .gitkeep logs
○  uu chore: .gitignore
○  kt feat: enonce de l'exercice
○  zk chore: commit initial
◆  zzz (vide)

Côté Git, après `jj bookmark set 14-jj -r <sommet>` :

$ git log --oneline 14-jj
6ca54c6 feat: voiture.yaml
6915f2e feat: societe.yaml
a49b3ee feat: contact.yaml
734ffc1 chore: .gitkeep logs
de7d3f8 chore: .gitignore
ef87512 feat: enonce de l'exercice
56cc9dd chore: commit initial

Un commit, un fichier (vérification réellement exécutée, commit par commit) :

feat: voiture.yaml         | yaml/voiture.yaml
feat: societe.yaml         | yaml/societe.yaml
feat: contact.yaml         | yaml/contact.yaml
chore: .gitkeep logs       | logs/.gitkeep
chore: .gitignore          | .gitignore
feat: enonce de l'exercice | README.md
chore: commit initial      | README.md

C'est exactement le résultat attendu par l'exercice 04-rebase (7 commits, mêmes messages, même ordre, un fichier par commit). Les hashes Git et les change ids diffèrent à chaque fabrication du dépôt, ce qui est normal.

On est passé de 17 commits à 7 en 15 commandes jj, sans aucun éditeur ouvert, sans aucun conflit, et sans que le dépôt ne passe une seule fois par un état intermédiaire bloquant.
```

## Critères de réussite

- `git log --oneline 14-jj` affiche exactement 7 commits, dans l'ordre feat: voiture.yaml / feat: societe.yaml / feat: contact.yaml / chore: .gitkeep logs / chore: .gitignore / feat: enoncé de l'exercice / chore: commit initial
- `git show --stat` sur chacun des 7 commits ne montre qu'un seul fichier modifié
- Le fichier `logs/app.log` n'apparaît dans aucun commit de l'historique final : `git log --all --oneline -- logs/app.log` ne renvoie rien
- Aucun commit ne porte de message commençant par `fix:` : tous les correctifs ont été absorbés dans le commit qu'ils corrigeaient
- Le participant sait dire, sans regarder l'énoncé, ce que `@` et `@-` désignent, et pourquoi `git log --oneline -1` n'affiche pas la même chose que `jj st`
- Le participant sait expliquer la différence entre un change id et un commit id, et ce qui arrive à chacun lors d'un rebase
- Le participant a rencontré le message `Error: Commit ... is immutable` et sait relier ce garde-fou à la règle « on ne réécrit pas un historique partagé » du support jour 2
- Le participant sait citer au moins une opération faite en une commande jj qui aurait demandé plusieurs étapes en `git rebase -i`, et une limite de jj qui pourrait le disqualifier sur son dépôt professionnel
- Le participant sait énoncer la règle du dépôt colocated : commandes Git de lecture seulement, tout ce qui écrit passe par jj

## Variantes

- DÉMONSTRATION FORMATEUR (le cas le plus probable en salle d'entreprise, à préparer par défaut) : si moins de la moitié de la salle a jj, ne rien installer et dérouler au vidéoprojecteur en 25 à 30 minutes. Garder les étapes 2 (les deux visions du même dépôt), 4 (le mur de l'immuabilité), 5 (l'abandon avec rebase automatique des 13 descendants), 7 (le squash par chemin, le moment le plus spectaculaire) et 10 (le crash test git commit). Accélérer 6 et 8 en collant le bloc de commandes d'un coup. Distribuer l'énoncé en PDF pour ceux qui voudront le refaire chez eux. Terminer par la table de correspondance git et jj, qui est ce que les participants garderont.
- OFFLINE INTÉGRAL (salle sans réseau, proxy bloquant, ou wifi mort) : distribuer un bundle sur clé USB. Côté formateur, `git bundle create 14-jj.bundle 14-jj` puis `git bundle verify 14-jj.bundle`. Côté participant, `git clone -b 14-jj /Volumes/USB/14-jj.bundle 14-jj` puis `cd 14-jj && jj git init`. Tout le reste de l'exercice fonctionne à l'identique : après le clone, aucune commande ne sort sur le réseau. Mettre aussi sur la clé les binaires jj pour Windows et macOS récupérés depuis les GitHub Releases, pour ceux qui pourront les exécuter sans installation.
- POSTE VERROUILLÉ SANS DROITS ADMINISTRATEUR : les GitHub Releases du projet publient un binaire unique, sans installeur. Il suffit de le décompresser dans le répertoire personnel et de l'appeler par son chemin (`~/jj --version`) ou d'ajouter ce répertoire au PATH de la session Git Bash. À tester AVANT la session sur un poste représentatif du client, car certaines politiques bloquent l'exécution de tout binaire non signé.
- SANS COMPTE GITHUB, OU GITHUB BLOQUÉ : l'exercice ne demande aucun compte, seulement un clone en lecture. Si github.com est inaccessible, servir le dépôt depuis le poste du formateur avec `git daemon --base-path=<dossier> --export-all --reuseaddr`, puis clone en `git://<ip-formateur>/build-14-jj`. Ou bien, plus simple encore, le bundle sur clé USB de la variante précédente.
- GROUPE EN AVANCE, PROLONGEMENT 1 (le clou du spectacle) : la démonstration du conflit non bloquant, en 10 minutes, sur un clone frais. Deux commits frères modifient la même ligne de `yaml/voiture.yaml`, puis `jj rebase -s <side Y> -o <side X>`. Le rebase RÉUSSIT, le commit est marqué `×` dans `jj log` avec la mention `(conflict)`, et surtout on peut faire `jj new 14-jj` et travailler sur autre chose : le conflit ne bloque rien. Le comparer explicitement au couple `git rebase --continue` et `--abort` vu au jour 1. La résolution consiste à écrire le fichier, point final : il n'y a rien à continuer. Séquence complète en commentaire dans le champ `correction`.
- GROUPE EN AVANCE, PROLONGEMENT 2 : refaire l'étape 7 par la voie longue (`jj split -r <rév> <chemin> -m "..."` puis deux `jj squash`) et faire comparer le nombre de commandes avec la voie courte. Bon révélateur : le squash par chemin n'a pas d'équivalent Git, le split en a un partiel.
- GROUPE EN AVANCE, PROLONGEMENT 3 : faire explorer `jj op log` puis `jj op restore <opération>` pour revenir à l'état du dépôt AVANT tout le nettoyage, en une seule commande. C'est ce qui n'existe pas en Git, où le reflog est par référence et où il faut restaurer chaque branche une par une.
- GROUPE EN DIFFICULTÉ, OU TEMPS QUI MANQUE : s'arrêter après l'étape 5 et remplacer les étapes 6 à 9 par la lecture commentée du bloc de commandes de la correction, projeté. Les trois idées à emporter (copie de travail = commit, pas d'index, undo universel) sont déjà acquises à l'étape 5. Les étapes 6 à 8 sont de la répétition.
- PUBLIC MAJORITAIREMENT CHEFS DE PROJET OU ARCHITECTES : sauter les étapes 6 et 8 en autonomie, et transformer l'exercice en discussion de 20 minutes après une démonstration de 20 minutes. La question à poser : « qu'est-ce qui, dans votre organisation, empêcherait un développeur d'utiliser jj demain sans rien demander à personne ? ». La réponse est toujours dans la liste des limites (LFS, hooks, sous-modules, .gitattributes), et c'est exactement le raisonnement d'évaluation d'outil qu'ils doivent savoir tenir.
