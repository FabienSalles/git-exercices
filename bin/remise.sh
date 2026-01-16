#!/usr/bin/env bash
# Remise accordee aux clients fideles.

REMISE_FIDELITE=10

remise_fidelite() {
    montant=$1
    echo $(( montant * (100 - REMISE_FIDELITE) / 100 ))
}
