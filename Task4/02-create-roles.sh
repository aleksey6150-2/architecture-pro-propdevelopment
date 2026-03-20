#!/usr/bin/env bash
set -euo pipefail

# Создаёт namespaces по доменам и роли RBAC:
# - cluster-readonly (ClusterRole)
# - platform-admin (ClusterRole)
# - secrets-auditor (ClusterRole)
# - namespace-viewer (Role в каждом доменном namespace)
# - namespace-operator (Role в каждом доменном namespace)

NAMESPACES=("sales" "tenant" "finance" "data")

echo "==> Создаю namespaces доменов (если не существуют)"
for ns in "${NAMESPACES[@]}"; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
done

echo "==> Применяю RBAC манифесты"

cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-readonly
rules:
  # Кластерные ресурсы (без secrets)
  - apiGroups: [""]
    resources: ["namespaces","nodes","persistentvolumes","events"]
    verbs: ["get","list","watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses","csinodes","csidrivers","csistoragecapacities"]
    verbs: ["get","list","watch"]
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-auditor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: platform-admin
rules:
  # Полный админский доступ (аналог cluster-admin, но создаём явную роль для задания)
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
  - nonResourceURLs: ["*"]
    verbs: ["*"]
YAML

# Роли внутри namespace: viewer / operator (без доступа к secrets)
for ns in "${NAMESPACES[@]}"; do
  cat <<YAML | kubectl apply -n "$ns" -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-viewer
rules:
  - apiGroups: [""]
    resources: ["pods","services","endpoints","configmaps","persistentvolumeclaims","events"]
    verbs: ["get","list","watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: ["apps"]
    resources: ["deployments","replicasets","statefulsets","daemonsets"]
    verbs: ["get","list","watch"]
  - apiGroups: ["batch"]
    resources: ["jobs","cronjobs"]
    verbs: ["get","list","watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses","networkpolicies"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-operator
rules:
  # Управление приложениями в своём namespace (но без secrets)
  - apiGroups: [""]
    resources: ["pods","services","endpoints","configmaps","persistentvolumeclaims","events"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["apps"]
    resources: ["deployments","replicasets","statefulsets","daemonsets"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["batch"]
    resources: ["jobs","cronjobs"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses","networkpolicies"]
    verbs: ["get","list","watch","create","update","patch","delete"]
  # Разрешаем exec (для отладки) — это subresource, verb "create"
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]
YAML
done
echo "Готово. Роли созданы."