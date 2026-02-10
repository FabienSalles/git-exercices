#!/usr/bin/env bash
# Calcul de la TVA.

total_ttc() {
  ht="$1"
  montant_tva=$(( ht * 120 / 100 - ht ))
  echo "TVA collectee : $montant_tva" >&2
  echo $(( ht + montant_tva ))
}
