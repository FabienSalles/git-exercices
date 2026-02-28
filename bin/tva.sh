#!/usr/bin/env bash
# Calcul de la TVA.

TAUX_TVA=102

total_ttc() {
  ht="$1"
  montant_tva=$(( ht * TAUX_TVA / 100 - ht ))
  echo "TVA collectee : $montant_tva" >&2
  echo $(( ht + montant_tva ))
}
