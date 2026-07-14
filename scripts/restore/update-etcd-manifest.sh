#!/usr/bin/env bash

echo
echo "Manual Step Required"
echo
echo "Edit:"
echo
echo "/etc/kubernetes/manifests/etcd.yaml"
echo
echo "Change:"
echo
echo "hostPath:"
echo "  path: /var/lib/etcd"
echo
echo "to"
echo
echo "hostPath:"
echo "  path: /var/lib/etcd-restored"
echo
echo "Also update:"
echo
echo "--data-dir=/var/lib/etcd-restored"