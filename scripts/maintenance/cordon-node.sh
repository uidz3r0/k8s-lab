#!/usr/bin/env bash

set -e

NODE=$1

kubectl cordon "$NODE"

kubectl get nodes