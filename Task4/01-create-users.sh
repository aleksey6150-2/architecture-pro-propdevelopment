#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-minikube}"
OUT_DIR="${OUT_DIR:-./_pki}"

CA_CRT="${CA_CRT:-$HOME/.minikube/ca.crt}"
CA_KEY="${CA_KEY:-$HOME/.minikube/ca.key}"

if [[ ! -f "$CA_CRT" || ! -f "$CA_KEY" ]]; then
  echo "Не найдены CA файлы minikube:"
  echo "  CA_CRT=$CA_CRT"
  echo "  CA_KEY=$CA_KEY"
  echo "Проверьте, что вы запускаете скрипт на хосте с minikube и у вас есть доступ к этим файлам."
  exit 1
fi

mkdir -p "$OUT_DIR"

# Берём параметры кластера из текущего kubeconfig
CLUSTER_SERVER="$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")"
CLUSTER_CA_DATA="$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.certificate-authority-data}")"

if [[ -z "$CLUSTER_SERVER" || -z "$CLUSTER_CA_DATA" ]]; then
  echo "Не удалось прочитать настройки кластера '$CLUSTER_NAME' из kubeconfig."
  echo "Проверьте: kubectl config get-clusters"
  exit 1
fi

# Пользователи (минимум 2, сделаем 4 для полноты модели)
# Группы в Kubernetes for x509 задаются как Organization (O) в subject.
# Можно указать несколько O: /CN=user/O=group1/O=group2
declare -A USERS_SUBJ
USERS_SUBJ["pd-sales-manager"]="/CN=pd-sales-manager/O=pd:sales:ops/O=pd:readonly"
USERS_SUBJ["pd-sales-dev"]="/CN=pd-sales-dev/O=pd:sales:dev"
USERS_SUBJ["pd-devops"]="/CN=pd-devops/O=pd:platform:admin"
USERS_SUBJ["pd-security"]="/CN=pd-security/O=pd:security:audit/O=pd:readonly"

create_user () {
  local user="$1"
  local subj="$2"

  local key="$OUT_DIR/$user.key"
  local csr="$OUT_DIR/$user.csr"
  local crt="$OUT_DIR/$user.crt"

  echo "==> Создаю сертификат для пользователя: $user"
  openssl genrsa -out "$key" 2048 >/dev/null 2>&1
  openssl req -new -key "$key" -out "$csr" -subj "$subj" >/dev/null 2>&1
  openssl x509 -req -in "$csr" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial -out "$crt" -days 365 >/dev/null 2>&1

  # Добавляем credentials и context в kubeconfig
  kubectl config set-credentials "$user" \
    --client-certificate="$crt" \
    --client-key="$key" >/dev/null

  kubectl config set-context "$user@$CLUSTER_NAME" \
    --cluster="$CLUSTER_NAME" \
    --user="$user" \
    --namespace=default >/dev/null
}

for u in "${!USERS_SUBJ[@]}"; do
  create_user "$u" "${USERS_SUBJ[$u]}"
done

echo
echo "Готово."
