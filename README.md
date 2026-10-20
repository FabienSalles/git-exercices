# Exercices Git

Matériel des travaux pratiques de la formation « GIT, mettre en œuvre le contrôle de versions ».
Un exercice = une branche. L'énoncé est le README.md de la branche.

## Les exercices

| Exercice | Sujet | Durée | Niveau | Clone |
| --- | --- | --- | --- | --- |
| `05-stash-reflog` | Gérer l'urgence : stash, mauvaise branche et reflog | 75 min | intermédiaire | `git clone -b 05-stash-reflog/main https://github.com/FabienSalles/git-exercices.git 05-stash-reflog` |
| `06-cherry-pick-revert` | Cherry-pick et revert : propager un correctif en production, annuler proprement ce qui est déjà publié | 55 min | intermédiaire | `git clone -b 06-cherry-pick-revert/main https://github.com/FabienSalles/git-exercices.git 06-cherry-pick-revert` |
| `07-rebase-onto` | Déplacer un morceau d'historique avec git rebase --onto | 55 min | avancé | `git clone -b 07-rebase-onto/main https://github.com/FabienSalles/git-exercices.git 07-rebase-onto` |
| `08-review-fixup` | Nettoyer une branche après une review : fixup, autosquash, range-diff et force-with-lease | 60 min | intermédiaire | `git clone -b 08-review-fixup https://github.com/FabienSalles/git-exercices.git 08-review-fixup` |
| `09-collab-local` | Simulation de travail collaboratif sans forge : dépôt nu, Alice et Bob sur un seul poste | 90 min | intermédiaire | `git clone -b 09-collab-local https://github.com/FabienSalles/git-exercices.git 09-collab-local` |
| `10-collab-pr` | Pull Request de bout en bout : ouvrir, relire, corriger, fusionner | 75 min | intermédiaire | `git clone -b 10-collab-pr https://github.com/FabienSalles/git-exercices.git 10-collab-pr` |
| `11-enquete` | Mener l'enquête sur un historique : log -S/-G/-L, blame, bisect automatisé | 60 min | intermédiaire | `git clone -b 11-enquete https://github.com/FabienSalles/git-exercices.git 11-enquete` |
| `12-worktree` | Un dépôt, plusieurs répertoires : git worktree en conditions réelles | 50 min | intermédiaire | `git clone -b 12-worktree https://github.com/FabienSalles/git-exercices.git 12-worktree` |
| `13-submodule-subtree` | Exercice Submodule et Subtree : embarquer une bibliothèque partagée, deux fois | 60 min | avancé | `git clone -b 13-submodule-subtree https://github.com/FabienSalles/git-exercices.git 13-submodule-subtree` |
| `14-jj` | Jujutsu (jj) : rejouer le nettoyage d'historique de 04-rebase avec un autre modèle mental | 60 min | avancé | `git clone -b 14-jj https://github.com/FabienSalles/git-exercices.git 14-jj` |
| `15-fichiers-magiques` | Les fichiers magiques : la configuration qui voyage avec le code | 75 min | intermédiaire | `git clone -b 15-fichiers-magiques https://github.com/FabienSalles/git-exercices.git 15-fichiers-magiques` |
| `16-hooks` | Automatiser la qualité avec les hooks côté client | 60 min | intermédiaire | `git clone -b 16-hooks/main https://github.com/FabienSalles/git-exercices.git 16-hooks` |
| `17-internals` | Fabriquer un commit à la main : sous le capot du moteur Git | 60 min | intermédiaire | `git clone -b 17-internals https://github.com/FabienSalles/git-exercices.git 17-internals` |
| `18-secret-purge` | Une clé d'API est partie dans l'historique : constater, purger, prévenir | 60 min | avancé | `git clone -b 18-secret-purge https://github.com/FabienSalles/git-exercices.git 18-secret-purge` |

## Les exercices de base

Les quatre premiers exercices (`01-intro`, `02-branch`, `03-remote`, `04-rebase`) et le tutoriel `git bisect` restent sur [ConveyCode/git-exercices](https://github.com/ConveyCode/git-exercices).

## Ressources

* [Aide-mémoire Git](https://git-scm.com/cheat-sheet)
* [Learning Git Branching](https://learngitbranching.js.org/?locale=fr_FR)
* [Ebook Pro Git](https://git-scm.com/book/fr/v2)
* [Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials)
