#!/usr/bin/env bash

set -e

NODES=$(kubectl get nodes -o name | cut -d/ -f2)

for NODE in $NODES
do
    echo
    echo "====================================="
    echo "$NODE"
    echo "====================================="

    kubectl cordon "$NODE"

    kubectl drain "$NODE" \
        --ignore-daemonsets \
        --delete-emptydir-data

    echo
    echo "Maintenance..."

    sleep 3

    kubectl uncordon "$NODE"

done

echo

kubectl get nodes