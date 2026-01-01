#!/usr/bin/env bash
# Verifie que bin/tarif.sh annonce le bon total TTC du catalogue.
# Codes de sortie : 0 = tout va bien, 1 = mauvais total.

ATTENDU=3000

obtenu=$(bash bin/tarif.sh 2>/dev/null)

if [ "$obtenu" = "$ATTENDU" ]; then
  echo "OK   total TTC = $obtenu"
  exit 0
fi

echo "KO   total TTC attendu $ATTENDU, obtenu '$obtenu'"
exit 1
