#!/usr/bin/env bash
set -euo pipefail

# Привязки делаем к ГРУППАМ (организациям из x509), а не к конкретным users.

NAMESPACES=("sales" "tenant" "finance" "data")

echo "==> ClusterRoleBinding: cluster-readonly для группы pd:readonly"
cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-readonly-cluster
subjects:
  - kind: Group
    name: pd:readonly
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-readonly
  apiGroup: rbac.authorization.k8s.io
YAML

echo "==> ClusterRoleBinding: secrets-auditor для группы pd:security:audit"
cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-security-secrets-auditor
subjects:
  - kind: Group
    name: pd:security:audit
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secrets-auditor
  apiGroup: rbac.authorization.k8s.io
YAML

echo "==> ClusterRoleBinding: platform-admin для группы pd:platform:admin (DevOps)"
cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-platform-admin
subjects:
  - kind: Group
    name: pd:platform:admin
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: platform-admin
  apiGroup: rbac.authorization.k8s.io
YAML

echo "==> RoleBinding по доменам (namespace-viewer / namespace-operator)"
for ns in "${NAMESPACES[@]}"; do
  # viewer для операционных менеджеров домена
  cat <<YAML | kubectl apply -n "$ns" -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ns}-ops-viewer
subjects:
  - kind: Group
    name: pd:${ns}:ops
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-viewer
  apiGroup: rbac.authorization.k8s.io
YAML

  # operator для функциональной команды домена
  cat <<YAML | kubectl apply -n "$ns" -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ns}-dev-operator
subjects:
  - kind: Group
    name: pd:${ns}:dev
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-operator
  apiGroup: rbac.authorization.k8s.io
YAML
done

echo "Готово. Привязки созданы."
echo
echo "Проверка (пример):"
echo "  kubectl config use-context pd-sales-manager@minikube"
echo "  kubectl auth can-i get pods -n sales"
echo "  kubectl auth can-i get secrets -n sales  # должно быть 'no'"
echo
echo "  kubectl config use-context pd-security@minikube"
echo "  kubectl auth can-i get secrets -n sales  # должно быть 'yes'"