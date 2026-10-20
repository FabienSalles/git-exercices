# Nettoyer une branche après une review : fixup, autosquash, range-diff et force-with-lease

> Votre branche feat/velo est poussée depuis hier, Bob la relit et laisse trois remarques : il faut les corriger dans les commits qui les concernent, pas empiler trois commits "fix: retour de review", puis repousser sans écraser le commit que Bob a poussé entre-temps.

**Niveau** : intermédiaire | **Durée estimée** : 60 min

## Prérequis

- Jour 1 complet, en particulier day-1/slides/05-commands.md (add, commit, rm), day-1/slides/06-search.md (log, show, révisions), day-1/slides/07-branch.md et day-1/slides/09-repository.md (remote, push, branches de suivi)
- Jour 2, chapitre day-2/slides/02-clean.md jusqu'à la slide Force vs Force with lease incluse
- Avoir déjà fait au moins un rebase interactif : l'exercice 04-rebase du dépôt git-exercices est le prérequis idéal, car il apprend à lire et modifier la todo-list
- Git >= 2.30 sur le poste (option --force-if-includes du bonus 2). Validé sur Git 2.54.0
- Un terminal Git Bash ou équivalent, et surtout un éditeur configuré pour Git (git config --global core.editor), sinon le rebase interactif ouvre vi et bloque la moitié de la salle

## 1. Mise en place

Cloner la branche de l'exercice, puis lancer le script atelier.sh. Il fabrique trois dossiers sur votre disque : serveur.git est le dépôt central et joue le rôle de GitHub, atelier est votre clone de travail et c'est le seul endroit où vous travaillez, collegue est le clone de Bob et on n'y touche pas. Le script est rejouable : en cas de fausse manoeuvre, revenir dans 08-review-fixup, relancer bash atelier.sh, et tout repart de zéro.

```bash
git clone -b 08-review-fixup https://github.com/FabienSalles/git-exercices.git 08-review-fixup
cd 08-review-fixup
bash atelier.sh
cd atelier
```

Résultat attendu :

```
Materiel pret.

  serveur.git : le depot central (il joue le role de GitHub)
  atelier     : votre clone de travail   <-- cd atelier
  collegue    : le clone de Bob (ne pas y toucher)

* 3cdcf08 (HEAD -> feat/velo, origin/feat/velo) docs: referencer les accessoires dans le README
* 259ee7c feat(velo): ajouter la lumiere avant
* ed0aef2 feat: modifications
* 94b5350 feat(velo): ajouter velo.yaml
* 368d160 (origin/main, origin/HEAD) feat: catalogue initial
```

> **Question** : Le serveur est un simple dossier sur votre disque, et pourtant on le clone. Quel protocole de transport Git utilise-t-on ici, parmi les quatre vus jour 1 ?

## 2. Étape 1 : lire l'état de départ

Avant toute chose, regarder où l'on est. Quatre commits sur feat/velo, tous déjà poussés. Les empreintes affichées sont celles que vous devez voir, à l'identique : elles sont figées dans le script de fabrication.

```bash
git status
git log --oneline --graph --decorate --all
```

Résultat attendu :

```
On branch feat/velo
Your branch is up to date with 'origin/feat/velo'.

nothing to commit, working tree clean

* 3cdcf08 (HEAD -> feat/velo, origin/feat/velo) docs: referencer les accessoires dans le README
* 259ee7c feat(velo): ajouter la lumiere avant
* ed0aef2 feat: modifications
* 94b5350 feat(velo): ajouter velo.yaml
* 368d160 (origin/main, origin/HEAD) feat: catalogue initial
```

> **Question** : feat/velo et origin/feat/velo pointent sur le même commit. Que représente exactement origin/feat/velo : la branche sur le serveur, ou l'idée que votre clone se fait de la branche sur le serveur ?

## 3. Étape 2 : lire la review et retrouver les commits fautifs

Bob a laissé trois remarques. À chacune correspond un et un seul commit fautif. Avant de taper la moindre correction, retrouver lequel avec git show.

1. yaml/velo.yaml : couleru s'écrit couleur.
2. debug.log n'a rien à faire dans le dépôt.
3. yaml/antivol.yaml : le prix manque, et le message feat: modifications ne dit rien.

```bash
git show 94b5350
git show ed0aef2
git show 259ee7c
git show 3cdcf08
```

Résultat attendu :

```
Association attendue :
  remarque 1 -> 94b5350 (feat(velo): ajouter velo.yaml)
  remarque 2 -> 259ee7c (feat(velo): ajouter la lumiere avant)
  remarque 3 -> ed0aef2 (feat: modifications)
Le commit 3cdcf08 est correct, il ne doit pas bouger.
```

> **Question** : Pourquoi ne pas simplement ajouter trois commits fix: retour de review au sommet de la branche ? Qu'est-ce que cela coûte, six mois plus tard, à celui qui fait un git log sur ce fichier ?

## 4. Étape 3 : remarque 1, un fixup ciblé

Corriger la faute dans yaml/velo.yaml pour obtenir couleur: rouge, indexer, puis créer un commit correctif rattaché au commit 94b5350. On utilise --fixup et non --squash parce que le message du commit visé est bon : il n'y a que le contenu à corriger.

```bash
# yaml/velo.yaml doit contenir :
# velo:
#   couleur: rouge
#   marque: Peugeot
#   modele: LR01
git add yaml/velo.yaml
git commit --fixup 94b5350
```

Résultat attendu :

```
[feat/velo fca97e9] fixup! feat(velo): ajouter velo.yaml
 1 file changed, 1 insertion(+), 1 deletion(-)

(votre empreinte fca97e9 sera différente, elle dépend de l'heure du commit)
```

> **Question** : Git a fabriqué le message tout seul : fixup! suivi du sujet du commit visé. Qu'est-ce qui, dans ce commit, permettra tout à l'heure à --autosquash de savoir où le ranger : son empreinte, sa date, ou son message ?

## 5. Étape 4 : remarque 2, supprimer le fichier de trop

Supprimer debug.log du dépôt avec git rm, puis créer un commit correctif rattaché au commit qui l'a introduit. Là encore --fixup : le message feat(velo): ajouter la lumiere avant est correct.

```bash
git rm debug.log
git commit --fixup 259ee7c
```

Résultat attendu :

```
rm 'debug.log'

[feat/velo 0fe6518] fixup! feat(velo): ajouter la lumiere avant
 1 file changed, 2 deletions(-)
 delete mode 100644 debug.log
```

> **Question** : Après le rebase, debug.log n'aura jamais existé dans l'historique de la branche. En quoi est-ce différent d'un simple commit de suppression posé au sommet ?

## 6. Étape 5 : remarque 3, un squash pour corriger aussi le message

Ici le contenu et le message sont à reprendre. --fixup jette le message du commit correctif, --squash le conserve et propose de fusionner les deux au moment du rebase. C'est donc --squash. Ajouter prix: 79 dans yaml/antivol.yaml, indexer, puis créer le commit correctif rattaché à ed0aef2.

```bash
# yaml/antivol.yaml doit contenir :
# antivol:
#   marque: Abus
#   type: U
#   prix: 79
git add yaml/antivol.yaml
git commit --squash ed0aef2
```

Résultat attendu :

```
[feat/velo 9820a3d] squash! feat: modifications
 1 file changed, 1 insertion(+)

Aucun éditeur ne s'ouvre à cette étape : le message est fabriqué automatiquement.
```

> **Question** : Si seul le message était à corriger, sans aucun changement de contenu, quelle troisième variante existe ? (indice : git commit --fixup=reword:<empreinte>, qui produit un commit amend!)

## 7. Étape 6 : regarder avant de rebaser

Rien n'a encore bougé dans l'historique : les trois commits correctifs sont simplement empilés au sommet, dans le désordre. Le vérifier avant de lancer le rebase.

```bash
git log --oneline --decorate
git status -sb
```

Résultat attendu :

```
9820a3d (HEAD -> feat/velo) squash! feat: modifications
0fe6518 fixup! feat(velo): ajouter la lumiere avant
fca97e9 fixup! feat(velo): ajouter velo.yaml
3cdcf08 (origin/feat/velo) docs: referencer les accessoires dans le README
259ee7c feat(velo): ajouter la lumiere avant
ed0aef2 feat: modifications
94b5350 feat(velo): ajouter velo.yaml
368d160 (origin/main, origin/HEAD) feat: catalogue initial

## feat/velo...origin/feat/velo [ahead 3]
```

> **Question** : origin/feat/velo est resté sur 3cdcf08 alors que vous venez de faire trois commits. Pourquoi cette référence ne bouge-t-elle pas toute seule ?

## 8. Étape 7 : le rebase avec autosquash

Lancer le rebase interactif avec l'option --autosquash, en prenant pour base origin/main, qui est le point de départ de la branche. Ce clone n'a pas de branche main locale, d'où le préfixe origin/. Dans le premier éditeur, il n'y a rien à modifier : tout est déjà rangé, les commits correctifs ont été déplacés sous leur cible et leur verbe est passé de pick à fixup ou squash. Enregistrer et quitter. Un second éditeur s'ouvre ensuite, uniquement pour le squash : y écrire le message définitif.

```bash
git rebase -i --autosquash origin/main

# premier editeur, deja range, ne rien toucher :
pick 94b5350 # feat(velo): ajouter velo.yaml
fixup fca97e9 # fixup! feat(velo): ajouter velo.yaml
pick ed0aef2 # feat: modifications
squash 9820a3d # squash! feat: modifications
pick 259ee7c # feat(velo): ajouter la lumiere avant
fixup 0fe6518 # fixup! feat(velo): ajouter la lumiere avant
pick 3cdcf08 # docs: referencer les accessoires dans le README

# second editeur, remplacer tout le contenu par :
feat(velo): ajouter antivol.yaml
```

Résultat attendu :

```
Contenu du second éditeur, avant modification :

# This is a combination of 2 commits.
# This is the 1st commit message:

feat: modifications

# This is the commit message #2:

# squash! feat: modifications

Puis, en sortie de commande :

Successfully rebased and updated refs/heads/feat/velo.
```

> **Question** : Sans l'option --autosquash, la todo-list aurait listé les trois commits correctifs à la fin, tous en pick, dans l'ordre chronologique. Qu'auriez-vous eu à faire à la main dans ce cas ?

## 9. Étape 8 : vérifier le résultat

Contrôler les trois corrections : quatre commits au lieu de sept, debug.log disparu, faute corrigée, message clair. Et lire attentivement la ligne de git status -sb.

```bash
git log --oneline --decorate --all
ls
cat yaml/velo.yaml
git status -sb
```

Résultat attendu :

```
0644fda (HEAD -> feat/velo) docs: referencer les accessoires dans le README
9b462c5 feat(velo): ajouter la lumiere avant
438a7ad feat(velo): ajouter antivol.yaml
981a4df feat(velo): ajouter velo.yaml
3cdcf08 (origin/feat/velo) docs: referencer les accessoires dans le README
259ee7c feat(velo): ajouter la lumiere avant
ed0aef2 feat: modifications
94b5350 feat(velo): ajouter velo.yaml
368d160 (origin/main, origin/HEAD) feat: catalogue initial

README.md
yaml

velo:
  couleur: rouge
  marque: Peugeot
  modele: LR01

## feat/velo...origin/feat/velo [ahead 4, behind 4]

À partir d'ici, toutes les empreintes réécrites seront différentes chez vous. Seules celles d'avant le rebase (94b5350, ed0aef2, 259ee7c, 3cdcf08, 3fc49b5, 368d160) sont communes à tout le monde.
```

> **Question** : ahead 4, behind 4 alors que vous n'avez rien récupéré du serveur. Comment expliquez-vous ce behind 4 ?

## 10. Étape 9 : relire sa propre réécriture avec range-diff

git diff répondrait que tout a changé, puisque les empreintes ne sont plus les mêmes. La bonne question est : qu'est-ce qui a vraiment changé entre la version poussée et la version réécrite. C'est ce que fait git range-diff. Lancer d'abord la forme simple, constater que deux commits ne sont pas appariés, puis relâcher le seuil avec --creation-factor.

```bash
git range-diff origin/feat/velo...HEAD
git range-diff --creation-factor=95 origin/feat/velo...HEAD
```

Résultat attendu :

```
Forme simple :

1:  94b5350 < -:  ------- feat(velo): ajouter velo.yaml
-:  ------- > 1:  981a4df feat(velo): ajouter velo.yaml
2:  ed0aef2 ! 2:  438a7ad feat: modifications
    @@ Metadata
     Author: Alice Martin <alice.martin@exemple.fr>

      ## Commit message ##
    -    feat: modifications
    +    feat(velo): ajouter antivol.yaml

      ## yaml/antivol.yaml (new) ##
     @@
     +antivol:
     +  marque: Abus
     +  type: U
    ++  prix: 79
3:  259ee7c < -:  ------- feat(velo): ajouter la lumiere avant
-:  ------- > 3:  9b462c5 feat(velo): ajouter la lumiere avant
4:  3cdcf08 = 4:  0644fda docs: referencer les accessoires dans le README

Avec --creation-factor=95, les quatre commits sont appariés :

1:  94b5350 ! 1:  981a4df feat(velo): ajouter velo.yaml
    @@ Commit message
      ## yaml/velo.yaml (new) ##
     @@
     +velo:
    -+  couleru: rouge
    ++  couleur: rouge
     +  marque: Peugeot
     +  modele: LR01
2:  ed0aef2 ! 2:  438a7ad feat: modifications
    @@ Metadata
     Author: Alice Martin <alice.martin@exemple.fr>

      ## Commit message ##
    -    feat: modifications
    +    feat(velo): ajouter antivol.yaml

      ## yaml/antivol.yaml (new) ##
     @@
     +antivol:
     +  marque: Abus
     +  type: U
    ++  prix: 79
3:  259ee7c ! 3:  9b462c5 feat(velo): ajouter la lumiere avant
    @@ Metadata
      ## Commit message ##
         feat(velo): ajouter la lumiere avant

    - ## debug.log (new) ##
    -@@
    -+DEBUG lecture de yaml/lumiere.yaml
    -+DEBUG lumens = 400
    -
      ## yaml/lumiere.yaml (new) ##
     @@
     +lumiere:

Lecture des symboles : = commit inchangé, ! commit modifié (le diff des diffs suit), < présent seulement à gauche, > présent seulement à droite.

Pourquoi la première forme n'apparie pas tout : range-diff refuse d'apparier deux commits qu'il juge trop différents, et un commit qui crée un fichier est presque intégralement composé de lignes ajoutées, ce qui fausse son calcul.
```

> **Question** : Les trois remarques de Bob apparaissent, une par commit, dans la seconde sortie. Qu'est-ce que cela vous permet d'écrire dans la conversation de la pull request, que git log ne permettait pas ?

## 11. Étape 10 : pousser, et se faire refuser

La branche locale a été réécrite : un push normal serait refusé pour non fast-forward. On utilise donc --force-with-lease, la version prudente du force. Le lancer, et lire le message d'erreur avant de faire quoi que ce soit.

```bash
git push --force-with-lease
```

Résultat attendu :

```
To .../serveur.git
 ! [rejected]        feat/velo -> feat/velo (stale info)
error: failed to push some refs to '.../serveur.git'

stale info signifie que la branche telle qu'elle est sur le serveur ne correspond plus à la branche telle que votre clone la croit (origin/feat/velo). Quelqu'un a poussé depuis votre dernier échange avec le serveur, donc Git refuse.
```

> **Question** : Git compare deux choses avant d'accepter ce push. Lesquelles ? Et qu'aurait fait git push --force à la place ?

## 12. Étape 11 : aller voir ce qu'on allait écraser

Le refus signifie que quelqu'un a poussé sur la branche. Récupérer les références, regarder qui, et quoi. Ne rien pousser tant que ce n'est pas lu.

```bash
git fetch origin
git status -sb
git log --oneline --graph --decorate --all
git show --stat 3fc49b5
```

Résultat attendu :

```
From .../serveur
   3cdcf08..3fc49b5  feat/velo  -> origin/feat/velo

## feat/velo...origin/feat/velo [ahead 4, behind 5]

* 0644fda (HEAD -> feat/velo) docs: referencer les accessoires dans le README
* 9b462c5 feat(velo): ajouter la lumiere avant
* 438a7ad feat(velo): ajouter antivol.yaml
* 981a4df feat(velo): ajouter velo.yaml
| * 3fc49b5 (origin/feat/velo) feat(velo): ajouter casque.yaml
| * 3cdcf08 docs: referencer les accessoires dans le README
| * 259ee7c feat(velo): ajouter la lumiere avant
| * ed0aef2 feat: modifications
| * 94b5350 feat(velo): ajouter velo.yaml
|/
* 368d160 (origin/main, origin/HEAD) feat: catalogue initial

commit 3fc49b5bb03c52c3de19799a424f6f79f9ab85f6
Author: Bob Durand <bob.durand@exemple.fr>
Date:   Mon Jan 5 14:20:00 2026 +0100

    feat(velo): ajouter casque.yaml

 yaml/casque.yaml | 3 +++
 1 file changed, 3 insertions(+)

Attention : maintenant que le fetch est fait, origin/feat/velo est à jour, le bail est de nouveau valide, et git push --force-with-lease passerait, en supprimant le commit de Bob.
```

> **Question** : Le garde-fou protège donc de quoi, exactement : de ce que vous n'avez pas vu, ou de ce que vous n'avez pas lu ?

## 13. Étape 12 : récupérer le commit de Bob, puis pousser

Le commit de Bob ne touche qu'un fichier neuf. Le recopier sur la branche réécrite avec cherry-pick, puis repousser. Ne pas faire git pull ni git rebase origin/feat/velo : les deux ramèneraient l'ancienne version des quatre commits et produiraient des conflits.

```bash
git cherry-pick 3fc49b5
git push --force-with-lease
git status -sb
git log --oneline --graph --decorate --all
```

Résultat attendu :

```
[feat/velo 81a2a4e] feat(velo): ajouter casque.yaml
 Author: Bob Durand <bob.durand@exemple.fr>
 Date: Mon Jan 5 14:20:00 2026 +0100
 1 file changed, 3 insertions(+)
 create mode 100644 yaml/casque.yaml

To .../serveur.git
 + 3fc49b5...81a2a4e feat/velo -> feat/velo (forced update)

## feat/velo...origin/feat/velo

* 81a2a4e (HEAD -> feat/velo, origin/feat/velo) feat(velo): ajouter casque.yaml
* 0644fda docs: referencer les accessoires dans le README
* 9b462c5 feat(velo): ajouter la lumiere avant
* 438a7ad feat(velo): ajouter antivol.yaml
* 981a4df feat(velo): ajouter velo.yaml
* 368d160 (origin/main, origin/HEAD) feat: catalogue initial

Cinq commits, un par sujet, aucun fix: retour de review, et le travail de Bob est intact.
```

> **Question** : Le cherry-pick a conservé Bob comme auteur mais a changé l'empreinte du commit. Que devra faire Bob dans son propre clone pour se remettre à jour, et pourquoi un simple git pull ne suffira pas ?

## 14. Bonus 1 : voir ce que --force aurait fait

À ne faire qu'après avoir terminé, et seulement parce que ce dépôt est jetable. Repartir de zéro, refaire les étapes 3 à 7, puis pousser en --force sans avoir fait de fetch.

```bash
cd ..
bash atelier.sh
cd atelier
# refaire les etapes 3 a 7
git push --force
git log --oneline --decorate origin/feat/velo

# Bob tente de repousser son commit :
git -C ../collegue push origin feat/velo

# recuperation, depuis l'atelier :
git fetch ../collegue feat/velo
git cherry-pick FETCH_HEAD
git push --force-with-lease
```

Résultat attendu :

```
To .../serveur.git
 + 3fc49b5...d638abd feat/velo -> feat/velo (forced update)

d638abd (HEAD -> feat/velo, origin/feat/velo) docs: referencer les accessoires dans le README
1d7580c feat(velo): ajouter la lumiere avant
20d1e9a feat(velo): ajouter antivol.yaml
9253ca3 feat(velo): ajouter velo.yaml
368d160 (origin/main, origin/HEAD) feat: catalogue initial

Le commit de Bob a disparu du serveur, sans avertissement et sans question.

Tentative de Bob :
 ! [rejected]        feat/velo -> feat/velo (fetch first)

Récupération :
   d638abd..5aeb188  feat/velo -> feat/velo
```

> **Question** : Le commit de Bob n'est pas perdu pour tout le monde : où existe-t-il encore, et pourquoi son propre push est-il malgré tout refusé ?

## 15. Bonus 2 : le garde-fou le plus strict

--force-with-lease se contente de vérifier que votre référence origin/feat/velo est à jour. --force-if-includes exige en plus que le sommet distant ait été intégré dans votre branche locale. Le tester après le fetch de l'étape 11.

```bash
git push --force-with-lease --force-if-includes
```

Résultat attendu :

```
To .../serveur.git
 ! [rejected]        feat/velo -> feat/velo (remote ref updated since checkout)
error: failed to push some refs to '.../serveur.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout.

À noter : un cherry-pick recopie la modification mais ne rend pas le commit distant ancêtre de la branche. --force-if-includes refuse donc encore après le cherry-pick de l'étape 12. C'est volontairement très strict, et cela demande Git 2.30 ou plus récent.
```

> **Question** : Dans quel cas concret --force-with-lease seul est-il insuffisant, en équipe, quand un IDE fait des git fetch en tâche de fond ?

## 16. Aide-mémoire

Tableau de synthèse à garder pour le poste de travail.

```bash
Corriger le contenu d'un commit precedent      git commit --fixup <empreinte>
Corriger contenu ET message                   git commit --squash <empreinte>
Ne corriger que le message                    git commit --fixup=reword:<empreinte>  (commit amend!)
Appliquer les correctifs                      git rebase -i --autosquash <base>
Rendre --autosquash implicite                 git config --global rebase.autosquash true
Relire sa reecriture                          git range-diff <base>...HEAD
                                              git range-diff --creation-factor=95 <base>...HEAD
Repousser une branche reecrite                git push --force-with-lease
Refuser tant que le distant n'est pas integre git push --force-with-lease --force-if-includes
Ecraser le travail des autres sans prevenir   git push --force, a ne jamais taper
Annuler tout tant que rien n'est pousse       git reset --hard origin/feat/velo
```

Résultat attendu :

```
Règle de sortie : la réécriture d'historique est légitime sur une branche de fonctionnalité qui n'appartient qu'à vous, et sur elle seule. Sur main, jamais.
```

> **Question** : Sur quel type de branche cet exercice serait-il une faute professionnelle, et pourquoi ?

## Résultat final attendu

```
Sortie réelle obtenue en fin de parcours, dans le clone atelier :

$ git status -sb
## feat/velo...origin/feat/velo

$ git log --oneline --graph --decorate --all
* 81a2a4e (HEAD -> feat/velo, origin/feat/velo) feat(velo): ajouter casque.yaml
* 0644fda docs: referencer les accessoires dans le README
* 9b462c5 feat(velo): ajouter la lumiere avant
* 438a7ad feat(velo): ajouter antivol.yaml
* 981a4df feat(velo): ajouter velo.yaml
* 368d160 (origin/main, origin/HEAD) feat: catalogue initial

$ ls yaml
antivol.yaml
casque.yaml
contact.yaml
lumiere.yaml
societe.yaml
velo.yaml
voiture.yaml

$ cat yaml/velo.yaml
velo:
  couleur: rouge
  marque: Peugeot
  modele: LR01

$ cat yaml/antivol.yaml
antivol:
  marque: Abus
  type: U
  prix: 79

Cinq commits, un par sujet, aucun commit fix: retour de review, plus de debug.log, velo.yaml corrigé, antivol.yaml avec son prix et un message conforme aux conventional commits, et le commit de Bob intact avec Bob Durand comme auteur. Les empreintes des commits réécrits varient d'un poste à l'autre puisqu'elles dépendent de l'heure du rebase : seules celles d'avant le rebase (368d160, 94b5350, ed0aef2, 259ee7c, 3cdcf08, 3fc49b5) sont identiques partout, les dates ayant été figées dans atelier.sh.
```

## Critères de réussite

- git log --oneline sur feat/velo affiche cinq commits, et aucun message ne commence par fixup!, squash! ou fix: retour de review
- Le fichier debug.log n'existe ni dans le répertoire de travail ni dans aucun commit de la branche : git log --all --oneline -- debug.log ne renvoie rien
- yaml/velo.yaml contient couleur: rouge, et git show sur le premier commit de la branche montre que la faute n'y a jamais existé
- yaml/antivol.yaml contient prix: 79, et le commit qui le crée porte un message conforme aux conventional commits, plus feat: modifications
- git range-diff --creation-factor=95 origin/feat/velo...HEAD apparie les quatre commits et fait apparaître exactement les trois corrections demandées par Bob
- Le participant sait expliquer avec ses mots ce que compare --force-with-lease, et pourquoi un git fetch désarme le garde-fou
- Le commit feat(velo): ajouter casque.yaml de Bob est présent sur la branche finale, avec Bob Durand comme auteur
- git status -sb affiche ## feat/velo...origin/feat/velo, sans ahead ni behind
- Le participant sait dire pourquoi git pull et git rebase origin/feat/velo étaient les mauvaises réponses à l'étape 12
- Le participant sait énoncer sur quel type de branche cette manipulation est interdite

## Variantes

- Hors ligne, sans compte et sans réseau : c'est le mode par défaut. L'exercice ne touche jamais GitHub une fois la branche clonée, le serveur est un dépôt bare local. Pour les salles sans réseau du tout, distribuer la branche en bundle : côté formateur git bundle create 08-review-fixup.bundle 08-review-fixup, côté participant git clone -b 08-review-fixup 08-review-fixup.bundle 08-review-fixup. Vérifié : atelier.sh produit exactement les mêmes empreintes quel que soit le chemin du dossier de travail.
- Poste verrouillé, sans droit d'exécuter un script : donner les commandes de atelier.sh à coller directement dans le terminal, ou faire l'exercice en binôme sur un seul poste. Le script n'installe rien, ne télécharge rien et n'écrit que dans son dossier courant, ce qui suffit en général à débloquer une DSI méfiante.
- Proxy d'entreprise qui bloque GitHub : le seul accès réseau est le git clone initial. En cas de blocage, distribuer le dossier 08-review-fixup sur clé USB, ou en bundle.
- Windows / Git Bash : lancer bash atelier.sh depuis Git Bash et non depuis PowerShell ou cmd. Prévoir un chemin court et sans accent. Vérifier core.editor et core.autocrlf avant de démarrer.
- Groupe en avance : enchaîner sur le bonus 1 (--force destructeur puis récupération depuis le clone de Bob) et le bonus 2 (--force-if-includes). Ajouter une quatrième remarque de review portant uniquement sur un message de commit, à traiter avec git commit --fixup=reword:<empreinte> qui produit un commit amend! : vérifié sur Git 2.54.0, la commande ouvre l'éditeur et refuse d'être combinée avec -m.
- Groupe en retard ou horaire serré : s'arrêter après l'étape 9 et faire les étapes 10 à 12 en démonstration au vidéoprojecteur. Le coeur pédagogique (fixup, squash, autosquash, range-diff) est alors couvert en 30 minutes, et le refus de --force-with-lease est vu sans être manipulé.
- Salle disposant de comptes GitHub, si le formateur veut prolonger vers la pull request : après l'étape 12, faire pousser la branche vers un dépôt d'atelier public et ouvrir une PR. L'étape 9 devient le commentaire à coller dans la conversation de la PR, et l'étape 10 illustre pourquoi un force-push fait sauter les approbations et passe les commentaires inline en Outdated.
