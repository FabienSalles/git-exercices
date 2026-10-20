#!/usr/bin/env bash
#
# atelier.sh : fabrique le materiel local de l'exercice 08-review-fixup.
#
# Cree, dans le repertoire courant, trois dossiers :
#   serveur.git : le depot "central" (bare). Il joue le role de GitHub.
#   atelier     : votre clone de travail. Vous travaillez UNIQUEMENT ici.
#   collegue    : le clone de Bob, qui pousse un commit sur votre branche
#                 pendant que vous corrigez. C'est lui qui fera echouer
#                 le premier "git push --force-with-lease".
#
# Le script est idempotent : il supprime et recree ces trois dossiers.
#
set -euo pipefail

RACINE="$(pwd)"
SERVEUR="$RACINE/serveur.git"
ATELIER="$RACINE/atelier"
COLLEGUE="$RACINE/collegue"
TMP="$RACINE/.fabrication"

rm -rf "$SERVEUR" "$ATELIER" "$COLLEGUE" "$TMP"

# Dates figees : les empreintes (hashes) des commits fabriques sont donc
# identiques sur toutes les machines, et identiques a celles du README.
horodate() {
  export GIT_AUTHOR_DATE="2026-01-05T$1:00+01:00"
  export GIT_COMMITTER_DATE="2026-01-05T$1:00+01:00"
}

# --- 1. le depot central, vide ------------------------------------------------
git init -q --bare "$SERVEUR"
git -C "$SERVEUR" symbolic-ref HEAD refs/heads/main

# --- 2. un clone temporaire pour fabriquer l'historique ------------------------
git init -q "$TMP"
git -C "$TMP" symbolic-ref HEAD refs/heads/main
git -C "$TMP" config user.name "Alice Martin"
git -C "$TMP" config user.email "alice.martin@exemple.fr"
git -C "$TMP" config commit.gpgsign false

cd "$TMP"

# --- 3. la branche main : le projet tel qu'il est en production ----------------
mkdir -p yaml
cat > README.md <<'EOF'
# Catalogue

Ce depot decrit le materiel de la societe au format YAML.

## Contenu

- `yaml/contact.yaml`
- `yaml/voiture.yaml`
- `yaml/societe.yaml`
EOF
cat > yaml/contact.yaml <<'EOF'
contact:
  prenom: Jean
  nom: Dupont
  ville: Paris
EOF
cat > yaml/voiture.yaml <<'EOF'
voiture:
  marque: Renault
  modele: Clio
EOF
cat > yaml/societe.yaml <<'EOF'
societe:
  nom: Orange
  ville: Guyancourt
EOF
git add .
horodate "09:00"
git commit -q -m "feat: catalogue initial"

# --- 4. la branche feat/velo : 4 commits, 3 defauts plantes -------------------
git switch -q -c feat/velo

# commit 1 : faute de frappe "couleru"
cat > yaml/velo.yaml <<'EOF'
velo:
  couleru: rouge
  marque: Peugeot
  modele: LR01
EOF
git add yaml/velo.yaml
horodate "10:12"
git commit -q -m "feat(velo): ajouter velo.yaml"

# commit 2 : message vague, et le prix manque
cat > yaml/antivol.yaml <<'EOF'
antivol:
  marque: Abus
  type: U
EOF
git add yaml/antivol.yaml
horodate "10:41"
git commit -q -m "feat: modifications"

# commit 3 : un fichier de debug committe par erreur
cat > yaml/lumiere.yaml <<'EOF'
lumiere:
  position: avant
  lumens: 400
EOF
cat > debug.log <<'EOF'
DEBUG lecture de yaml/lumiere.yaml
DEBUG lumens = 400
EOF
git add yaml/lumiere.yaml debug.log
horodate "11:05"
git commit -q -m "feat(velo): ajouter la lumiere avant"

# commit 4 : celui-ci est bon, il ne doit pas bouger
cat > README.md <<'EOF'
# Catalogue

Ce depot decrit le materiel de la societe au format YAML.

## Contenu

- `yaml/contact.yaml`
- `yaml/voiture.yaml`
- `yaml/societe.yaml`
- `yaml/velo.yaml`
- `yaml/antivol.yaml`
- `yaml/lumiere.yaml`
EOF
git add README.md
horodate "11:30"
git commit -q -m "docs: referencer les accessoires dans le README"

git remote add origin "$SERVEUR"
git push -q -u origin main feat/velo

cd "$RACINE"
rm -rf "$TMP"

# --- 5. le clone de travail du participant -------------------------------------
git clone -q -b feat/velo "$SERVEUR" "$ATELIER"
git -C "$ATELIER" config user.name "Alice Martin"
git -C "$ATELIER" config user.email "alice.martin@exemple.fr"
git -C "$ATELIER" config commit.gpgsign false

# --- 6. le clone du collegue ---------------------------------------------------
# Bob pousse APRES le clone du participant : la reference locale
# origin/feat/velo de l'atelier est donc perimee, et c'est exactement ce que
# --force-with-lease va detecter.
git clone -q -b feat/velo "$SERVEUR" "$COLLEGUE"
git -C "$COLLEGUE" config user.name "Bob Durand"
git -C "$COLLEGUE" config user.email "bob.durand@exemple.fr"
git -C "$COLLEGUE" config commit.gpgsign false
cat > "$COLLEGUE/yaml/casque.yaml" <<'EOF'
casque:
  marque: Abus
  taille: M
EOF
git -C "$COLLEGUE" add yaml/casque.yaml
horodate "14:20"
git -C "$COLLEGUE" commit -q -m "feat(velo): ajouter casque.yaml"
git -C "$COLLEGUE" push -q origin feat/velo

echo "Materiel pret."
echo
echo "  serveur.git : le depot central (il joue le role de GitHub)"
echo "  atelier     : votre clone de travail   <-- cd atelier"
echo "  collegue    : le clone de Bob (ne pas y toucher)"
echo
git -C "$ATELIER" log --oneline --graph --decorate --all

# ---------------------------------------------------------------------------
# PUBLICATION DE LA BRANCHE (cote formateur, a lancer a la main, PAS ici) :
#
#   git clone https://github.com/FabienSalles/git-exercices.git git-exercices-08
#   cd git-exercices-08
#   git switch --orphan 08-review-fixup
#   git rm -rq --cached .
#   find . -maxdepth 1 ! -name . ! -name .git -exec rm -rf {} +
#   printf 'serveur.git/\natelier/\ncollegue/\n.fabrication/\n' > .gitignore
#   # deposer README.md (l'enonce) et ce fichier atelier.sh
#   chmod +x atelier.sh
#   git add .gitignore README.md atelier.sh
#   git commit -m "feat: exercice 08-review-fixup"
#   git push origin 08-review-fixup
# ---------------------------------------------------------------------------
