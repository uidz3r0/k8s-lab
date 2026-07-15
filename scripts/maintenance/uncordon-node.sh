#!/usr/bin/env bash

set -e

NODE=$1

kubectl uncordon "$NODE"

kubectl get nodes