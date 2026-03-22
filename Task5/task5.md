## Управление трафиком внутри кластера Kubernetes (NetworkPolicy)

[non-admin-api-allow.yaml](non-admin-api-allow.yaml) - файл сетевых политик

* В namespace включается изоляция по умолчанию (default-deny-all).
* Разрешён трафик только внутри пар:
front-end - back-end-api
admin-front-end - admin-back-end-api

* Admin-API изолирован от non-admin pod’ов (и наоборот), т. к. нет политик, разрешающих пересечение ролей.
* Прочие pod’ы (например тестовые без нужной метки) не могут ходить ни к одному сервису.

проверка:
```bash
kubectl create ns task5
kubectl config set-context --current --namespace=task5

kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80

kubectl get pods,svc -o wide
```
