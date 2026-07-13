#!/bin/bash

echo "Current etcd Members"

kubectl get nodes

echo

echo "Remember"

echo "1 member -> quorum 1"

echo "2 members -> quorum 2"

echo "3 members -> quorum 2"

echo "5 members -> quorum 3"