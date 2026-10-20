#!/usr/bin/env bash
# Reconstruit l'atelier complet jusqu'à la FIN DE L'ÉTAPE 4 :
#   atelier/central.git : le dépôt nu qui joue le serveur
#   atelier/alice       : le poste d'Alice, identité locale Alice
#   atelier/bob         : le poste de Bob, identité locale Bob
# Les deux postes sont à jour, main contient contact.yaml et societe.yaml.
# Reprendre l'énoncé à l'étape 5.
#
# Idempotent : supprime et recrée le dossier atelier/.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf atelier
mkdir atelier
cd atelier

git init --bare -b main central.git >/dev/null

git clone central.git alice 2>/dev/null
git -C alice config user.name  "Alice"
git -C alice config user.email "alice@exemple.fr"
mkdir -p alice/yaml
cat > alice/yaml/contact.yaml <<'EOF'
contact:
  prenom: Jean
  nom: Dupont
  ville: Paris
EOF
git -C alice add yaml/contact.yaml
git -C alice commit -q -m "feat: contact.yaml"
git -C alice push -q -u origin main

git clone central.git bob 2>/dev/null
git -C bob config user.name  "Bob"
git -C bob config user.email "bob@exemple.fr"
cat > bob/yaml/societe.yaml <<'EOF'
societe:
  nom: Orange
  ville: Guyancourt
EOF
git -C bob add yaml/societe.yaml
git -C bob commit -q -m "feat: societe.yaml"
git -C bob push -q

git -C alice pull -q

echo "Atelier reconstruit dans $(pwd)"
echo "Reprendre l'énoncé à l'étape 5."
git -C alice log --oneline --graph --all --decorate
