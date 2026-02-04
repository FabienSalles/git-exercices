#!/usr/bin/env bash
# Remise accordee aux clients fideles.

. "$(dirname "$0")/config.sh"

remise_fidelite() {
    montant=$1
    echo $(( montant - montant * REMISE_FIDELITE / 100 ))
}
