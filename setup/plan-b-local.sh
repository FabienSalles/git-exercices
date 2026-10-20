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
