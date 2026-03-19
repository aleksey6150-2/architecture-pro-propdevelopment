**Оргструктура PropDevelopment:**

- Есть домены (`sales`, `tenant`, `finance`, `data`) → доступ режем **по namespace**.
- В каждом домене две “подкоманды”:
    - **операционная** (менеджеры) → `namespace-viewer` + (при необходимости) `cluster-readonly`;
    - **функциональная** (разработка/эксплуатация) → `namespace-operator` в своём домене.
- Отдельно:
    - DevOps → `platform-admin` (управление кластером),
    - ИБ → `secrets-auditor` (привилегированное действие: просмотр секретов).

**Таблица ролей:**

| Роль  | Права роли | Группы пользователей |
| --- | --- | --- |
| `cluster-readonly` (ClusterRole) | Просмотр ресурсов кластера без доступа к секретам: `get/list/watch` для `namespaces`, `nodes`, `persistentvolumes`, `storageclasses` и т. п. | Операционные команды доменов (менеджеры), часть функциональных ролей “только посмотреть”, аудит/наблюдение (например, бизнес-аналитики без админки). |
| `namespace-viewer` (Role в namespace) | Просмотр ресурсов в конкретном namespace: `get/list/watch` для workload’ов/сервисов + `get` для `pods/log`. Без доступа к `secrets`. | Операционные менеджеры доменов (Sales/Tenant/Finance/Data), BI-аналитики (в `data` namespace) — просмотр состояния окружения и логов. |
| `namespace-operator` (Role в namespace) | Настройка и эксплуатация приложений в рамках namespace: `create/update/patch/delete/get/list/watch` для `deployments/statefulsets/daemonsets/jobs/cronjobs/services/ingresses/configmaps` + `create` для `pods/exec`. **Без** прав на `secrets`. | Функциональные команды доменов (разработчики + инженеры эксплуатации) — деплой/настройка своих сервисов в своём домене. |
| `secrets-auditor` (ClusterRole) | Привилегированное чтение секретов: `get/list/watch` для `secrets` во всех namespace. | Специалист по ИБ (аудит доступа/утечек), ограниченно — выделенные привилегированные лица. |
| `platform-admin` (ClusterRole) | Настройка/администрирование кластера: полный доступ к ресурсам (`*` на `*`, включая RBAC, namespaces, CRD и т. п.). | DevOps / Platform team (операционная команда инфраструктуры). |

