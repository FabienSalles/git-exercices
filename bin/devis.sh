#!/usr/bin/env bash
# Edite un devis pour un client fidele.

RACINE="$(dirname "$0")/.."
. "$RACINE/bin/remise.sh"

echo "Devis ConveyCycles"
echo "Total remise : $(remise_fidelite 3000)"
