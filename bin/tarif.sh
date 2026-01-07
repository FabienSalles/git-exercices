#!/usr/bin/env bash
# Calcule le tarif du catalogue.

RACINE="$(dirname "$0")/.."

total_ht() {
    total=0
    while read -r cle valeur; do
        if [ "$cle" = "prix:" ]; then
            total=$(( total + valeur ))
        fi
    done < "$RACINE/yaml/velo.yaml"
    echo $total
}

total_ht
