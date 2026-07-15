#!/bin/bash

echo "Current etcd Members"

kubectl get nodes

echo

echo "Remember that etcd quorum is calculated as (N/2)+1, where N is the number of etcd members in the cluster."
echo "" It is based on etcd members, not the number of nodes in the cluster. ""
echo "1 member -> quorum 1 -> can lose 0 members"

echo "2 members -> quorum 2 -> can lose 0 member"

echo "3 members -> quorum 2 -> can lose 1 member"

echo "5 members -> quorum 3 -> can lose 2 members"