# Отчёт по результатам анализа инцидентов в Kubernetes

## Дата проведения
20 марта 2026 года

## Выполненные действия

Был запущен скрипт simulate-incident.sh, который выполнил следующие действия:

### 1. Попытка доступа к секретам
kubectl get secrets --as=system:serviceaccount:secure-ops:monitoring

text
**Результат**: Error from server (Forbidden)
**Вывод**: RBAC работает корректно — сервис-аккаунт не имеет прав на чтение секретов

### 2. Создание привилегированного пода
kubectl apply -f privileged-pod.yaml

text
**Результат**: pod/privileged-pod created
**Риск**: Привилегированный контейнер имеет доступ к хостовому ядру

### 3. Попытка выполнения команды в чужом поде
kubectl exec -n kube-system coredns-xxx -- cat /etc/resolv.conf

text
**Результат**: OCI runtime exec failed (cat not found)
**Вывод**: Попытка зафиксирована, но не удалась

### 4. Эскалация привилегий через RoleBinding
kubectl apply -f escalate-binding.yaml

text
**Результат**: rolebinding created with cluster-admin
**Критический риск**: Сервис-аккаунт получил полный доступ к кластеру

## Итоги

| Событие | Статус | Риск |
|---------|--------|------|
| Доступ к секретам | Заблокирован RBAC | Средний |
| Привилегированный под | Успешно создан | Высокий |
| Exec в чужой под | Ошибка выполнения | Средний |
| RoleBinding cluster-admin | Успешно создан | Критический |

## Рекомендации

1. Включить Pod Security Standards
2. Ограничить создание RoleBinding через OPA
3. Настроить аудит и мониторинг
