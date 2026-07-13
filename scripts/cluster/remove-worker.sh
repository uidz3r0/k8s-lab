#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "./remove-worker.sh <node>"
    exit 1
fi

NODE=$1

kubectl drain "$NODE" \
--ignore-daemonsets \
--delete-emptydir-data

kubectl delete node "$NODE"