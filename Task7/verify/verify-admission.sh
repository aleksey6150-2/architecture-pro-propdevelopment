#!/usr/bin/env bash
set -euo pipefail

echo "==> Create namespace (PSA restricted)"
kubectl apply -f ../01-create-namespace.yaml

echo
echo "==> Try apply insecure manifests (should FAIL)"
set +e
kubectl apply -f ../insecure-manifests/01-privileged-pod.yaml
echo "exit=$?"
kubectl apply -f ../insecure-manifests/02-hostpath-pod.yaml
echo "exit=$?"
kubectl apply -f ../insecure-manifests/03-root-user-pod.yaml
echo "exit=$?"
set -e

echo
echo "==> Apply secure manifests (should PASS)"
kubectl apply -f ../secure-manifests/01-secure.yaml
kubectl apply -f ../secure-manifests/02-secure.yaml
kubectl apply -f ../secure-manifests/03-secure.yaml

echo
echo "==> Pods in audit-zone"
kubectl get pods -n audit-zone -o wide
