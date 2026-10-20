#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Setup formateur de l'exercice 10-collab-pr (Pull Request de bout en bout).
#
# Ce script est idempotent : il supprime et recree entierement $BASE.
# Il ne pousse RIEN sur GitHub. Les commandes de publication sont affichees
# en fin d'execution, a executer a la main.
#
# Il fabrique trois choses :
#
#   1. $BASE/atelier-pr        : le contenu du depot d'atelier partage
#                                (futur FabienSalles/atelier-pr, PUBLIC).
#                                main + 8 fichiers yaml, chacun avec 1 defaut
#                                de ticket + 1 defaut latent (pays: Frnace)
#                                que le relecteur trouvera en review.
#
#   2. $BASE/git-exercices     : la branche 10-collab-pr du depot d'exercices
#                                (README = enonce, + le script du plan B).
#
#   3. $BASE/plan-b            : le dispositif hors ligne deja monte
#                                (depot nu central.git + clones alice et bob),
#                                pour verifier qu'il fonctionne avant la salle.
#
# Aucune identite git n'est ecrite en global : tout est en --local / -c.
# Teste sur git 2.54.0 / macOS.
# ---------------------------------------------------------------------------
set -euo pipefail

BASE="${1:-$HOME/atelier-10-collab-pr}"
MOI="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

rm -rf "$BASE"
mkdir -p "$BASE"

# ---------------------------------------------------------------------------
# 1. Le depot d'atelier partage
# ---------------------------------------------------------------------------
ATELIER="$BASE/atelier-pr"
mkdir -p "$ATELIER/yaml" "$ATELIER/.github"
cd "$ATELIER"
git init -q -b main
git config --local user.name "ConveyCode Formation"
git config --local user.email "formation@conveycode.fr"
git config --local commit.gpgsign false

# 8 fiches, 8 tickets, 8 fichiers distincts : aucun conflit entre binomes.
# Chaque fichier porte DEUX fautes :
#   - celle du ticket (l'auteur la corrige)
#   - `pays: Frnace` (le relecteur la trouve et propose une suggestion)
cat > yaml/contact.yaml <<'EOF'
contact:
  prenom: Jean
  vile: Paris
  pays: Frnace
EOF

cat > yaml/voiture.yaml <<'EOF'
voiture:
  marque: Renaut
  modele: Clio
  pays: Frnace
EOF

cat > yaml/societe.yaml <<'EOF'
societe:
  nom: Orange
  ville: Guyancour
  pays: Frnace
EOF

cat > yaml/velo.yaml <<'EOF'
velo:
  marque: Look
  modele: 675
  pays: Frnace
EOF

cat > yaml/train.yaml <<'EOF'
train:
  operateur: SNFC
  ligne: Paris-Bordeaux
  pays: Frnace
EOF

cat > yaml/avion.yaml <<'EOF'
avion:
  compagnie: Air Frnce
  modele: A320
  pays: Frnace
EOF

cat > yaml/bateau.yaml <<'EOF'
bateau:
  nom: Belem
  port: Marseile
  pays: Frnace
EOF

cat > yaml/moto.yaml <<'EOF'
moto:
  marque: Yamha
  modele: MT-07
  pays: Frnace
EOF

cat > .github/CODEOWNERS <<'EOF'
# Demonstration formateur : toute modification du dossier yaml/ exige
# la relecture d'un proprietaire de code.
# Un code owner doit avoir un acces write EXPLICITE sur le depot,
# sinon la regle est silencieusement inoperante.
/yaml/   @FabienSalles
EOF

cat > README.md <<'EOF'
# Atelier Pull Request

Depot d'entrainement de la formation GIT. Les donnees sont volontairement
triviales : la charge de travail porte sur le processus, pas sur le metier.

## Regle du jeu

**On ne pousse jamais sur `main`.** Toute modification passe par une branche
et une Pull Request relue par le binome.

Nom de branche impose : `fix/<votre-prenom>-<fichier>`, par exemple
`fix/alice-contact`. Cela evite que douze personnes poussent `fix-typo`.

## Les tickets

Un ticket par binome. Le formateur attribue les numeros.

| # | Fichier              | A corriger                             |
|---|----------------------|----------------------------------------|
| 1 | `yaml/contact.yaml`  | la cle `vile` doit s'appeler `ville`   |
| 2 | `yaml/voiture.yaml`  | `Renaut` doit s'ecrire `Renault`       |
| 3 | `yaml/societe.yaml`  | `Guyancour` doit s'ecrire `Guyancourt` |
| 4 | `yaml/velo.yaml`     | le modele est `576`, pas `675`         |
| 5 | `yaml/train.yaml`    | `SNFC` doit s'ecrire `SNCF`            |
| 6 | `yaml/avion.yaml`    | `Air Frnce` doit s'ecrire `Air France` |
| 7 | `yaml/bateau.yaml`   | `Marseile` doit s'ecrire `Marseille`   |
| 8 | `yaml/moto.yaml`     | `Yamha` doit s'ecrire `Yamaha`         |

Chaque fichier contient une **seconde** faute, non listee ici. C'est au
relecteur de la trouver.
EOF

git add -A
git commit -q -m "chore: bootstrap atelier pull request"
echo "OK  1/3  depot d'atelier construit : $ATELIER"

# ---------------------------------------------------------------------------
# 2. La branche 10-collab-pr du depot d'exercices
# ---------------------------------------------------------------------------
EXOS="$BASE/git-exercices"
mkdir -p "$EXOS/setup"
cd "$EXOS"
git init -q -b 10-collab-pr
git config --local user.name "ConveyCode Formation"
git config --local user.email "formation@conveycode.fr"
git config --local commit.gpgsign false

cp "$MOI" "$EXOS/setup/setup-10-collab-pr.sh"
chmod +x "$EXOS/setup/setup-10-collab-pr.sh"

# Le plan B est un script autonome, distribuable sur cle USB.
cat > setup/plan-b-local.sh <<'PLANB'
#!/usr/bin/env bash
# Plan B de l'exercice 10-collab-pr : aucun reseau, aucun compte GitHub.
# Monte un depot nu central.git et deux clones alice/ et bob/ sur le poste.
# Idempotent : supprime et recree $DEST.
set -euo pipefail
DEST="${1:-$HOME/atelier-pr-local}"
rm -rf "$DEST"
mkdir -p "$DEST"
cd "$DEST"

git init -q --bare central.git
git -C central.git symbolic-ref HEAD refs/heads/main

git init -q -b main amorce
cd amorce
git config --local user.name "ConveyCode Formation"
git config --local user.email "formation@conveycode.fr"
mkdir -p yaml
printf 'contact:\n  prenom: Jean\n  vile: Paris\n  pays: Frnace\n' > yaml/contact.yaml
printf 'voiture:\n  marque: Renaut\n  modele: Clio\n  pays: Frnace\n' > yaml/voiture.yaml
git add -A
git commit -q -m "chore: bootstrap atelier pull request"
git push -q ../central.git main
cd ..
rm -rf amorce

# Simule une branche protegee : main n'accepte plus aucun push direct.
# Echappatoire du mainteneur, qui joue le bouton "Merge" de la forge :
#   git push -o mainteneur origin main
git -C central.git config receive.advertisePushOptions true
cat > central.git/hooks/pre-receive <<'HOOK'
#!/bin/sh
[ "${GIT_PUSH_OPTION_0:-}" = "mainteneur" ] && exit 0
while read -r old new ref; do
  if [ "$ref" = "refs/heads/main" ]; then
    echo "refuse: main est protegee, passez par une branche et une revue" >&2
    exit 1
  fi
done
exit 0
HOOK
chmod +x central.git/hooks/pre-receive

git clone -q central.git alice
git -C alice config --local user.name "Alice"
git -C alice config --local user.email "alice@exemple.fr"

git clone -q central.git bob
git -C bob config --local user.name "Bob"
git -C bob config --local user.email "bob@exemple.fr"

echo "Plan B pret dans $DEST :"
echo "  central.git  le depot de partage (joue le role de GitHub)"
echo "  alice/       poste de l'auteur"
echo "  bob/         poste du relecteur"
PLANB
chmod +x setup/plan-b-local.sh

cat > README.md <<'EOF'
# Exercice Pull Request

L'enonce complet est distribue en salle. Ce depot contient le materiel :

- `setup/setup-10-collab-pr.sh` : fabrication du depot d'atelier (formateur)
- `setup/plan-b-local.sh` : dispositif hors ligne, sans compte GitHub
EOF

git add -A
git commit -q -m "feat: add pull request workshop material"
echo "OK  2/3  branche 10-collab-pr construite : $EXOS"

# ---------------------------------------------------------------------------
# 3. Verification du plan B
# ---------------------------------------------------------------------------
bash "$EXOS/setup/plan-b-local.sh" "$BASE/plan-b" > /dev/null
echo "OK  3/3  plan B verifie : $BASE/plan-b"

# ---------------------------------------------------------------------------
# Publication (A EXECUTER A LA MAIN, rien n'est pousse par ce script)
# ---------------------------------------------------------------------------
cat <<EOF

--------------------------------------------------------------------------
Publication, a executer a la main apres relecture :

  # 1. Le depot d'atelier, PUBLIC (les protections de branche ne sont
  #    gratuites que sur un depot public)
  cd $ATELIER
  gh repo create FabienSalles/atelier-pr --public --source=. --push

  # 2. La branche d'exercice
  cd $EXOS
  git remote add origin https://github.com/FabienSalles/git-exercices.git
  git push origin 10-collab-pr

  # 3. Les collaborateurs (repo partage) : un appel par participant
  for u in login1 login2 login3; do
    gh api -X PUT repos/FabienSalles/atelier-pr/collaborators/\$u -f permission=push
  done

  # 4. La protection de main
  gh api -X PUT repos/FabienSalles/atelier-pr/branches/main/protection \\
    -F required_pull_request_reviews[required_approving_review_count]=1 \\
    -F required_pull_request_reviews[dismiss_stale_reviews]=true \\
    -F required_conversation_resolution=true \\
    -F enforce_admins=false -F required_status_checks=null -F restrictions=null
--------------------------------------------------------------------------
EOF
