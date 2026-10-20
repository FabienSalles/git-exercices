#!/usr/bin/env bash
# Fabrique le materiel de l'exercice 13-submodule-subtree.
# Cree, a cote de ce script :
#   serveur/lib-yaml.git        depot nu (bare) de la bibliotheque partagee, 3 commits + tag v1.0.0
#   serveur/app-submodule.git   depot nu de l'application, pour le volet A
#   serveur/app-subtree.git     depot nu de la meme application, pour le volet B
#   lib-yaml/                   clone de travail de la bibliotheque
#   app-submodule/              clone de travail de l'application (volet A)
#   app-subtree/                clone de travail de l'application (volet B)
# Le script est idempotent : il supprime et recree ces six dossiers.
set -euo pipefail
cd "$(dirname "$0")"

NAME="Formation Git"
MAIL="formation@example.org"

# Dates figees : les empreintes des commits fabriques sont identiques
# sur toutes les machines, donc les sorties de l'enonce sont exactes.
export GIT_AUTHOR_NAME="$NAME"  GIT_COMMITTER_NAME="$NAME"
export GIT_AUTHOR_EMAIL="$MAIL" GIT_COMMITTER_EMAIL="$MAIL"
export GIT_AUTHOR_DATE="2026-01-05T09:00:00+01:00"
export GIT_COMMITTER_DATE="2026-01-05T09:00:00+01:00"

rm -rf serveur lib-yaml app-submodule app-subtree _tmp
mkdir -p serveur

ident() {
  git -C "$1" config user.name  "$NAME"
  git -C "$1" config user.email "$MAIL"
  git -C "$1" config commit.gpgsign false
}

# --- bibliotheque partagee -------------------------------------------------
mkdir -p _tmp/lib-yaml
git init -q -b main _tmp/lib-yaml
ident _tmp/lib-yaml
cat > _tmp/lib-yaml/README.md <<'EOF'
# lib-yaml

Bibliotheque de fiches YAML partagee entre plusieurs applications.
EOF
git -C _tmp/lib-yaml add README.md
git -C _tmp/lib-yaml commit -q -m "chore: commit initial"
cat > _tmp/lib-yaml/contact.yaml <<'EOF'
contact:
  prenom: Jean
  nom: Dupont
  ville: Paris
EOF
git -C _tmp/lib-yaml add contact.yaml
git -C _tmp/lib-yaml commit -q -m "feat: contact.yaml"
cat > _tmp/lib-yaml/societe.yaml <<'EOF'
societe:
  nom: Orange
  ville: Guyancourt
EOF
git -C _tmp/lib-yaml add societe.yaml
git -C _tmp/lib-yaml commit -q -m "feat: societe.yaml"
git -C _tmp/lib-yaml tag -a v1.0.0 -m "v1.0.0"

git init -q --bare -b main serveur/lib-yaml.git
git -C _tmp/lib-yaml remote add origin ../../serveur/lib-yaml.git
git -C _tmp/lib-yaml push -q -u origin main --tags

# --- application -----------------------------------------------------------
mkdir -p _tmp/app
git init -q -b main _tmp/app
ident _tmp/app
cat > _tmp/app/README.md <<'EOF'
# app

Application qui consomme les fiches YAML de lib-yaml.
EOF
git -C _tmp/app add README.md
git -C _tmp/app commit -q -m "chore: commit initial"
cat > _tmp/app/app.yaml <<'EOF'
app:
  nom: annuaire
  version: 1
EOF
git -C _tmp/app add app.yaml
git -C _tmp/app commit -q -m "feat: app.yaml"

for cible in app-submodule app-subtree; do
  git init -q --bare -b main "serveur/$cible.git"
  git -C _tmp/app push -q "../../serveur/$cible.git" main:main
done

# --- clones de travail -----------------------------------------------------
git clone -q serveur/lib-yaml.git lib-yaml
ident lib-yaml
git clone -q serveur/app-submodule.git app-submodule
ident app-submodule
git clone -q serveur/app-subtree.git app-subtree
ident app-subtree

rm -rf _tmp

echo "Materiel pret :"
echo "  serveur/lib-yaml.git  serveur/app-submodule.git  serveur/app-subtree.git"
echo "  lib-yaml/  app-submodule/  app-subtree/"
