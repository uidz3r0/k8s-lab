#!/usr/bin/env bash

set -e

NODE=$1

kubectl drain "$NODE" \
  --ignore-daemonsets \
  --delete-emptydir-data