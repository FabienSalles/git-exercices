#!/usr/bin/env bash
# Remise accordee aux clients fideles.

. "$(dirname "$0")/config.sh"

remise_fidelite() {
    montant=$1
    echo $(( montant * (100 - REMISE_FIDELITE) / 100 ))
}
