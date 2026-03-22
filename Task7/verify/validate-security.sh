#!/usr/bin/env bash
set -euo pipefail

echo "==> Gatekeeper pods"
kubectl get pods -n gatekeeper-system

echo
echo "==> Constraints"
kubectl get constraints

echo
echo "==> Describe constraints (violations if any)"
kubectl describe k8sdisallowprivileged disallow-privileged-in-audit-zone || true
kubectl describe k8sdisallowhostpath disallow-hostpath-in-audit-zone || true
kubectl describe k8srequiredsecuritycontext require-nonroot-and-readonlyrootfs-in-audit-zone || true

echo
echo "==> PSA labels on audit-zone"
kubectl get ns audit-zone -o jsonpath='{.metadata.labels}' ; echo
