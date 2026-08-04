# middleware-chart

统一管理数据库和中间件的 Helm umbrella chart。目前包含以下 Bitnami 子 chart：

| 组件 | Chart 版本 | 默认状态 | 默认架构 |
| --- | ---: | --- | --- |
| MySQL | `14.0.3` | 启用 | 单节点 |
| Redis | `27.0.17` | 启用 | 单节点 |
| PostgreSQL | `18.8.0` | 启用 | 单节点 |
| Elasticsearch | `22.1.6` | 启用 | 单节点 |
| MongoDB | `19.1.22` | 启用 | 单节点 |

## 使用

五个子 Chart 均以解压后的源码形式保存在仓库中，可以直接查看和修改：

- `charts/mysql`
- `charts/redis`
- `charts/postgresql`
- `charts/elasticsearch`
- `charts/mongodb`

`Chart.lock` 用于记录上游版本，`helm dependency list .` 会将五个依赖显示为
`unpacked`。不要在项目根目录直接执行 `helm dependency update`，否则 Helm
会再次生成 `.tgz` 文件。

当前子 Chart 使用了较新的 OCI 与模板能力，请使用 Helm `3.18+`（已用
`3.18.4` 验证）。

如需指定非系统默认的 Helm 二进制，可以传给 Make：

```bash
make lint HELM=/path/to/helm
make template HELM=/path/to/helm
```

检查并渲染：

```bash
make dependencies
helm lint .
helm template middleware . --namespace middleware
```

安装：

```bash
helm upgrade --install middleware . \
  --namespace middleware \
  --create-namespace \
  -f values-production.yaml
```

默认会安装全部五个组件。`values-production.example.yaml` 中每个组件都有
`enabled` 开关，也可以通过命令行按需控制：

```bash
helm upgrade --install middleware . \
  --namespace middleware \
  --create-namespace \
  --set mysql.enabled=false \
  --set redis.enabled=true \
  --set postgresql.enabled=false \
  --set elasticsearch.enabled=false \
  --set mongodb.enabled=false
```

## 配置

父级 `values.yaml` 已暴露常用配置，包括：

- 镜像仓库、镜像版本和拉取策略
- 用户名、密码、数据库和已有 Secret
- 单节点/复制架构及副本数
- Service 类型、业务端口和 NodePort
- CPU/内存 requests、limits
- PVC 开关、StorageClass、容量和已有 PVC
- 节点选择、容忍、亲和性和 Pod 注解
- TLS 与 Prometheus metrics 开关

所有配置保留在子 Chart 同名顶层键下，例如：

```yaml
mysql:
  auth:
    username: order_service
    password: change-me
    database: orders
  primary:
    service:
      ports:
        mysql: 3307
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: "2"
        memory: 2Gi
    persistence:
      size: 20Gi

redis:
  architecture: replication
  auth:
    password: change-me
  master:
    service:
      ports:
        redis: 6380
  replica:
    replicaCount: 2

postgresql:
  auth:
    username: report_service
    password: change-me
    database: reports
  primary:
    service:
      ports:
        postgresql: 5433
    persistence:
      size: 20Gi
```

父级未列出的高级参数仍可直接透传。完整可编辑参数位于：

- `charts/mysql/values.yaml`
- `charts/redis/values.yaml`
- `charts/postgresql/values.yaml`
- `charts/elasticsearch/values.yaml`
- `charts/mongodb/values.yaml`

上游文档：

- [MySQL](https://artifacthub.io/packages/helm/bitnami/mysql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Elasticsearch](https://artifacthub.io/packages/helm/bitnami/elasticsearch)
- [MongoDB](https://artifacthub.io/packages/helm/bitnami/mongodb)

## 凭据与持久化

`values.yaml` 不保存明文密码。首次安装时 Bitnami chart 会自动生成凭据；生产环境建议提前创建 Kubernetes Secret。数据库 Chart 使用 `auth.existingSecret`，Elasticsearch 使用 `security.existingSecret`。可复制 `values-production.example.yaml` 作为生产配置起点，但不要提交包含真实凭据的文件。

五个组件默认均启用 PVC，容量为 `8Gi`。通过 `global.defaultStorageClass` 指定集群的 StorageClass；留空时使用集群默认值。

升级前应固定并复用现有 Secret，否则数据库密码可能与持久卷中的已有数据不一致。跨主版本升级子 chart 或数据库镜像前，请先阅读 Bitnami 的升级说明并做好备份。
