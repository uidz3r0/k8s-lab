#!/bin/bash

kubectl get nodes -o wide

echo
echo "Control Plane Pods"
echo

kubectl get pods -n kube-system -o wide