**Оргструктура PropDevelopment:**

- Есть домены (`sales`, `tenant`, `finance`, `data`) → доступ режем **по namespace**.
- В каждом домене две “подкоманды”:
    - **операционная** (менеджеры) → `namespace-viewer` + (при необходимости) `cluster-readonly`;
    - **функциональная** (разработка/эксплуатация) → `namespace-operator` в своём домене.
- Отдельно:
    - DevOps → `platform-admin` (управление кластером),
    - ИБ → `secrets-auditor` (привилегированное действие: просмотр секретов).

**Таблица ролей:**

| Роль                                                                                  | Права роли                                                                                                                                                                                                                                                                  | Группы пользователей                                                                                                                      |
|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `cluster-readonly` (ClusterRole)                                                      | Кластерный read-only без секретов: `get/list/watch` для `namespaces`, `nodes`, `persistentvolumes`, `events`, `storageclasses`, `crd` (без прав на `secrets`).                                                                                                              | Наблюдатели: менеджеры (операционные команды) всех доменов, бизнес-аналитики (если нужен обзор кластера), аудит (без доступа к секретам). |
| `namespace-viewer` (Role, в каждом доменном namespace: `sales/tenant/finance/data`)   | Read-only в своём namespace: `get/list/watch` для `pods`, `services`, `deployments/statefulsets/daemonsets`, `jobs/cronjobs`, `ingresses`, `configmaps`, + `get` для `pods/log`. **Нет** прав на `secrets`.                                                                 | Операционные команды доменов (менеджеры): `pd:<domain>:ops` (например `pd:sales:ops`).                                                    |
| `namespace-operator` (Role, в каждом доменном namespace: `sales/tenant/finance/data`) | Управление приложениями в своём namespace: `create/update/patch/delete/get/list/watch` для workload’ов и сервисных ресурсов (`deployments`, `statefulsets`, `services`, `ingresses`, `configmaps` и т. п.) + `create` для `pods/exec` (отладка). **Нет** прав на `secrets`. | Функциональные команды доменов (разработка/эксплуатация): `pd:<domain>:dev` (например `pd:tenant:dev`).                                   |
| `secrets-auditor` (ClusterRole)                                                       | Привилегированное действие: `get/list/watch` для `secrets` во всех namespaces (только чтение).                                                                                                                                                                              | Специалист по ИБ (аудит): `pd:security:audit`.                                                                                            |
| `platform-admin` (ClusterRole)                                                        | Администрирование/настройка кластера: `*` на `*` (включая RBAC, namespaces, CRD и т. п.).                                                                                                                                                                                   | DevOps/Platform: `pd:platform:admin`.                                                                                                     |

* [01-create-users.sh](01-create-users.sh) создание пользователей (client cert) + kubeconfig контексты
* [02-create-roles.sh](02-create-roles.sh) - создание ролей (namespaces + Role/ClusterRole)
* [03-bind-users-to-roles.sh](03-bind-users-to-roles.sh) - привязка пользователей/групп к ролям (RoleBinding/ClusterRoleBinding)

## Быстрая самопроверка (ожидаемое поведение)

- Пользователь `pd-sales-manager` (группа `pd:sales:ops`, `pd:readonly`):
  - может смотреть `pods`, `deployments`, `pods/log` в `sales`
  - **не может** читать `secrets` нигде
- Пользователь `pd-sales-dev` (группа `pd:sales:dev`):
  - может деплоить/менять ресурсы в `sales`
  - **не может** читать `secrets`
- Пользователь `pd-security` (группа `pd:security:audit`):
  - может **читать secrets** (get/list/watch) во всех namespaces
  - не обязательно имеет права “админить” кластер
- Пользователь `pd-devops` (группа `pd:platform:admin`):
  - может настраивать кластер (RBAC/namespace/CRD и т. п.)