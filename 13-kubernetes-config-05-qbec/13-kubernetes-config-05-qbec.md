# Домашнее задание к занятию "13.5 поддержка нескольких окружений на примере Qbec"
Приложение обычно существует в нескольких окружениях. Для удобства работы следует использовать соответствующие инструменты, например, Qbec.

## Задание 1: подготовить приложение для работы через qbec
Приложение следует упаковать в qbec. Окружения должно быть 2: stage и production. 

Требования:
* stage окружение должно поднимать каждый компонент приложения в одном экземпляре;
* production окружение — каждый компонент в трёх экземплярах;
* для production окружения нужно добавить endpoint на внешний адрес.

### Ответ

Инциализируем проект:

```
> qbec init mytest --with-example
using server URL "https://192.168.90.135:6443" and default namespace "default" for the default environment
wrote mytest/params.libsonnet
wrote mytest/environments/base.libsonnet
wrote mytest/environments/default.libsonnet
wrote mytest/components/hello.jsonnet
wrote mytest/qbec.yaml
```


Настройка окружений. Редактируем файл qbec.yaml
```
apiVersion: qbec.io/v1alpha1
kind: App
metadata:
  name: mytest
spec:
  environments:
    stage:
      defaultNamespace: stage
      server: https://192.168.90.135:6443
    prod:
      defaultNamespace: prod
      server: https://192.168.90.135:6443
  vars: {}

```

Значения перменных для окружений хранятя в папке environmets

В файле base.libsonnet хранятся значния которе будут использоваться как в stage так и в prod

```
{
  components: {
  "db": {
    "image": {
      "repository": "postgres",
      "tag": "13-alpine"
    },
    "port": 5432,
    "credentials": {
      "POSTGRES_DB": "news",
      "POSTGRES_USER": "postgres",
      "POSTGRES_PASSWORD": "postgres"
    }
  },
  "back": {
    "image": {
      "repository": "lutovp/test-backend",
      "tag": "0.0.1"
    }
  },
  "front": {
    "image": {
      "repository": "lutovp/test-frontend",
      "tag": "0.0.7"
    }
  }
  },
}

```

В файле stage.libsonnet все что есть в base + значения только для stage

```

local base = import './base.libsonnet';

 base {
   components +: {
     db +: {
      "replicaCount": 1,
      "statefulSetName": "postgres-statefulset",
      "serviceName": "dbprod",
      "configMap": {
        "name": "postgres-configuration"
      }
     },
     back +: {
       "replicaCount": 1,
       "deploymentName": "backend",
       "serviceName": "backend-svc",
       "port": 9000,
       "targetPort": 9000,
       "nodePort": 30090
     },
     front +: {
       "replicaCount": 1,
       "deploymentName": "frontend",
       "serviceName": "frontend-svc",
       "port": 8000,
       "targetPort": 80,
       "nodePort": 30080
     },          
  }
 }


```

В файле prod.libsonnet все что есть в base + значения только для prod

```

local base = import './base.libsonnet';

 base {
   components +: {
     db +: {
      "replicaCount": 1,
      "statefulSetName": "postgres-statefulset1",
      "serviceName": "dbprod1",
      "configMap": {
        "name": "postgres-configuration1"
      }
     },
     back +: {
       "replicaCount": 3,
       "deploymentName": "backend1",
       "serviceName": "backend-svc1",
       "port": 9000,
       "targetPort": 9000,
       "nodePort": 30091
     },
     front +: {
       "replicaCount": 3,
       "deploymentName": "frontend1",
       "serviceName": "frontend-svc1",
       "port": 8000,
       "targetPort": 80,
       "nodePort": 30081
     },          
  }
 }

```

Наше приложение состоит из 3 компонентов. Для каждого из них создан отдельный файл в папке componets

db.jsonnet

```
local p = import '../params.libsonnet';
local params = p.components.db;

[
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": params.configMap.name,
    "labels": {
      "app": "postgres"
    }
  },
  "data": {
    "POSTGRES_DB": params.credentials.POSTGRES_DB,
    "POSTGRES_USER": params.credentials.POSTGRES_USER,
    "POSTGRES_PASSWORD": params.credentials.POSTGRES_PASSWORD
  }
},

{
  "apiVersion": "apps/v1",
  "kind": "StatefulSet",
  "metadata": {
    "name": params.statefulSetName,
    "labels": {
      "app": "postgres"
    }
  },
  "spec": {
    "serviceName": "postgres",
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "postgres"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "postgres"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "postgres",
            "image": params.image.repository+':'+params.image.tag,
            "envFrom": [
              {
                "configMapRef": {
                  "name": params.configMap.name
                }
              }
            ],
            "ports": [
              {
                "containerPort": params.port,
                "name": "postgresdb"
              }
            ]
          }
        ]
      }
    }
  }
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": params.serviceName,
    "labels": {
      "app": "postgres"
    }
  },
  "spec": {
    "ports": [
      {
        "port": params.port,
        "name": "postgres"
      }
    ],
    "type": "ClusterIP",
    "selector": {
      "app": "postgres"
    }
  }
}
]
```

back.jsonnet

```
local p = import '../params.libsonnet';
local params = p.components.back;
local prmdb = p.components.db;

[
    {
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "labels": {
      "app": "backend"
    },
    "name": params.deploymentName
  },
  "spec": {
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "backend"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "backend"
        }
      },
      "spec": {
        "containers": [
          {
            "image":  params.image.repository+':'+params.image.tag,
            "imagePullPolicy": "IfNotPresent",
            "name": "backend",
            "ports": [
              {
                "containerPort": params.port
              }
            ],
            "env": [
              {
                "name": "DATABASE_URL",
                "value":  "postgres://"+prmdb.credentials.POSTGRES_USER+":"+prmdb.credentials.POSTGRES_PASSWORD+"@"+prmdb.serviceName+":"+prmdb.port+"/"+prmdb.credentials.POSTGRES_DB 
              }
            ]
          }
        ]
      }
    }
  }
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": params.serviceName,
  },
  "spec": {
    "ports": [
      {
        "name": "web",
        "port": params.port,
        "targetPort": params.targetPort,
        "nodePort": params.nodePort
      }
    ],
    "selector": {
      "app": "backend"
    },
    "type": "NodePort"
  }
}


]


```

front.jsonnet

```
local p = import '../params.libsonnet';
local params = p.components.front;

[
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "labels": {
      "app": "frontend"
    },
    "name": params.deploymentName
  },
  "spec": {
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "frontend"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "frontend"
        }
      },
      "spec": {
        "containers": [
          {
            "image":  params.image.repository+':'+params.image.tag,
            "imagePullPolicy": "IfNotPresent",
            "name": "frontend",
            "ports": [
              {
                "containerPort": params.port
              }
            ]
          }
        ]
      }
    }
  }
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": params.serviceName
  },
  "spec": {
    "ports": [
      {
        "name": "web",
        "port": params.port,
        "targetPort": params.targetPort,
        "nodePort": params.nodePort
      }
    ],
    "selector": {
      "app": "frontend"
    },
    "type": "NodePort"
  }
}

]

```

Создадим namespace stage и prod
```
> kubectl create ns stage
namespace/stage created
opsuser@opsserver:~$ 
> kubectl create ns prod
namespace/prod created
opsuser@opsserver:~$ 
```

Проверим возможность деплоя в каждое окружение
```
> qbec validate stage
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 34ms
3 components evaluated in 6ms
✔ deployments backend -n stage (source back) is valid
✔ deployments frontend -n stage (source front) is valid
✔ services frontend-svc -n stage (source front) is valid
✔ services backend-svc -n stage (source back) is valid
✔ services dbprod -n stage (source db) is valid
✔ configmaps postgres-configuration -n stage (source db) is valid
✔ statefulsets postgres-statefulset -n stage (source db) is valid
---
stats:
  valid: 7

command took 150ms

```

```
> qbec validate prod
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 15ms
3 components evaluated in 5ms
✔ services backend-svc1 -n prod (source back) is valid
✔ deployments backend1 -n prod (source back) is valid
✔ configmaps postgres-configuration1 -n prod (source db) is valid
✔ services frontend-svc1 -n prod (source front) is valid
✔ deployments frontend1 -n prod (source front) is valid
✔ services dbprod1 -n prod (source db) is valid
✔ statefulsets postgres-statefulset1 -n prod (source db) is valid
---
stats:
  valid: 7

```

Сделаем деплой stage и prod

```
> qbec apply stage
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 23ms
3 components evaluated in 6ms

will synchronize 7 object(s)

Do you want to continue [y/n]: y
3 components evaluated in 9ms
create configmaps postgres-configuration -n stage (source db)
create deployments backend -n stage (source back)
create deployments frontend -n stage (source front)
create statefulsets postgres-statefulset -n stage (source db)
create services backend-svc -n stage (source back)
create services dbprod -n stage (source db)
create services frontend-svc -n stage (source front)
server objects load took 603ms
---
stats:
  created:
  - configmaps postgres-configuration -n stage (source db)
  - deployments backend -n stage (source back)
  - deployments frontend -n stage (source front)
  - statefulsets postgres-statefulset -n stage (source db)
  - services backend-svc -n stage (source back)
  - services dbprod -n stage (source db)
  - services frontend-svc -n stage (source front)

waiting for readiness of 3 objects
  - deployments backend -n stage
  - deployments frontend -n stage
  - statefulsets postgres-statefulset -n stage

✓ 0s    : deployments frontend -n stage :: successfully rolled out (2 remaining)
✓ 0s    : statefulsets postgres-statefulset -n stage :: 1 new pods updated (1 remaining)
✓ 0s    : deployments backend -n stage :: successfully rolled out (0 remaining)

✓ 0s: rollout complete
command took 4.25s
```


```
> qbec apply prod
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 30ms
3 components evaluated in 3ms

will synchronize 7 object(s)

Do you want to continue [y/n]: y
3 components evaluated in 7ms
create configmaps postgres-configuration1 -n prod (source db)
create deployments backend1 -n prod (source back)
create deployments frontend1 -n prod (source front)
create statefulsets postgres-statefulset1 -n prod (source db)
create services backend-svc1 -n prod (source back)
create services dbprod1 -n prod (source db)
create services frontend-svc1 -n prod (source front)
server objects load took 609ms
---
stats:
  created:
  - configmaps postgres-configuration1 -n prod (source db)
  - deployments backend1 -n prod (source back)
  - deployments frontend1 -n prod (source front)
  - statefulsets postgres-statefulset1 -n prod (source db)
  - services backend-svc1 -n prod (source back)
  - services dbprod1 -n prod (source db)
  - services frontend-svc1 -n prod (source front)

waiting for readiness of 3 objects
  - deployments backend1 -n prod
  - deployments frontend1 -n prod
  - statefulsets postgres-statefulset1 -n prod

✓ 0s    : deployments backend1 -n prod :: successfully rolled out (2 remaining)
✓ 0s    : statefulsets postgres-statefulset1 -n prod :: 1 new pods updated (1 remaining)
  0s    : deployments frontend1 -n prod :: 1 of 3 updated replicas are available
  1s    : deployments frontend1 -n prod :: 2 of 3 updated replicas are available
✓ 1s    : deployments frontend1 -n prod :: successfully rolled out (0 remaining)

✓ 1s: rollout complete
command took 3.85s
```

Смотрим поды:

```
Every 2.0s: kubectl get pods,svc -n stage                                                                                                                               opsserver: Mon Jul 25 20:44:43 2022

NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-775d99f5fb-p6sqw   1/1     Running   0          2m12s
pod/frontend-58995dbf4-qtqv7   1/1     Running   0          2m12s
pod/postgres-statefulset-0     1/1     Running   0          2m12s

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/backend-svc    NodePort    10.233.12.62   <none>        9000:30090/TCP   2m11s
service/dbprod         ClusterIP   10.233.12.52   <none>        5432/TCP         2m11s
service/frontend-svc   NodePort    10.233.51.13   <none>        8000:30080/TCP   2m11s
```


```
Every 2.0s: kubectl get pods,svc -n prod                                                                                                                                opsserver: Mon Jul 25 20:45:16 2022

NAME                            READY   STATUS    RESTARTS   AGE
pod/backend1-656f9665b9-dwnhm   1/1     Running   0          91s
pod/backend1-656f9665b9-fsqpm   1/1     Running   0          91s
pod/backend1-656f9665b9-mctpz   1/1     Running   0          91s
pod/frontend1-58995dbf4-bgjjh   1/1     Running   0          91s
pod/frontend1-58995dbf4-sqswt   1/1     Running   0          91s
pod/frontend1-58995dbf4-sw4fx   1/1     Running   0          91s
pod/postgres-statefulset1-0     1/1     Running   0          91s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc1    NodePort    10.233.11.247   <none>        9000:30091/TCP   90s
service/dbprod1         ClusterIP   10.233.55.33    <none>        5432/TCP         89s
service/frontend-svc1   NodePort    10.233.6.21     <none>        8000:30081/TCP   89s
```



Добавим endpoint на внешний ресурс. Для эсоздадим компонент myip.jsonnet 

```
[
{
  "kind": "Service",
  "apiVersion": "v1",
  "metadata": {
    "name": "external-svc"
  },
  "spec": {
    "ports": [
      {
        "name": "web",
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80
      }
    ]
  }
},

{
  "kind": "Endpoints",
  "apiVersion": "v1",
  "metadata": {
    "name": "external-svc"
  },
  "subsets": [
    {
      "addresses": [
        {
          "ip": "34.160.111.145" # ifconfig.me
        }
      ],
      "ports": [
        {
          "port": 80,
          "name": "web"
        }
      ]
    }
  ]
}

]

```

Отредактируем файл qbec.yaml

```
apiVersion: qbec.io/v1alpha1
kind: App
metadata:
  name: mytest
spec:
  environments:
    stage:
      defaultNamespace: stage
      server: https://192.168.90.135:6443
    prod:
      defaultNamespace: prod
      server: https://192.168.90.135:6443
      includes:
        - myip     
  vars: {}
  excludes:
    - myip
```
---

Проверим делпой на prod

```
> qbec validate prod
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 25ms
4 components evaluated in 4ms
✔ deployments backend1 -n prod (source back) is valid
✔ deployments frontend1 -n prod (source front) is valid
✔ services frontend-svc1 -n prod (source front) is valid
✔ endpoints external-svc -n prod (source myip) is valid
✔ services external-svc -n prod (source myip) is valid
✔ services backend-svc1 -n prod (source back) is valid
✔ configmaps postgres-configuration1 -n prod (source db) is valid
✔ statefulsets postgres-statefulset1 -n prod (source db) is valid
✔ services dbprod1 -n prod (source db) is valid
---
stats:
  valid: 9

command took 130ms

```
Как видим, добавилис два ресурса (сервис и эндпоинт для него):
endpoints external-svc -n prod (source myip) is valid services external-svc -n prod (source myip) is valid

Проверим stage
```

> qbec validate stage
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 16ms
3 components evaluated in 4ms
✔ deployments backend -n stage (source back) is valid
✔ deployments frontend -n stage (source front) is valid
✔ services frontend-svc -n stage (source front) is valid
✔ services backend-svc -n stage (source back) is valid
✔ services dbprod -n stage (source db) is valid
✔ statefulsets postgres-statefulset -n stage (source db) is valid
✔ configmaps postgres-configuration -n stage (source db) is valid
---
stats:
  valid: 7

command took 110ms
```

На stage ничего не добавляется

применим деплой на prod:

```
> qbec apply prod
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 14ms
4 components evaluated in 5ms

will synchronize 9 object(s)

Do you want to continue [y/n]: y
4 components evaluated in 5ms
create endpoints external-svc -n prod (source myip)
create services external-svc -n prod (source myip)
server objects load took 406ms
---
stats:
  created:
  - endpoints external-svc -n prod (source myip)
  - services external-svc -n prod (source myip)
  same: 7

waiting for readiness of 3 objects
  - deployments backend1 -n prod
  - deployments frontend1 -n prod
  - statefulsets postgres-statefulset1 -n prod

✓ 0s    : deployments frontend1 -n prod :: successfully rolled out (2 remaining)
✓ 0s    : deployments backend1 -n prod :: successfully rolled out (1 remaining)
✓ 0s    : statefulsets postgres-statefulset1 -n prod :: 1 new pods updated (0 remaining)

✓ 0s: rollout complete
command took 3.85s
```

Смотрим поды и серсы на prod

```
Every 2.0s: kubectl get po,svc -n prod                                                                                                                                          opsserver: Mon Jul 25 21:16:43 2022

NAME                            READY   STATUS    RESTARTS   AGE
pod/backend1-656f9665b9-dwnhm   1/1     Running   0          32m
pod/backend1-656f9665b9-fsqpm   1/1     Running   0          32m
pod/backend1-656f9665b9-mctpz   1/1     Running   0          32m
pod/frontend1-58995dbf4-bgjjh   1/1     Running   0          32m
pod/frontend1-58995dbf4-sqswt   1/1     Running   0          32m
pod/frontend1-58995dbf4-sw4fx   1/1     Running   0          32m
pod/postgres-statefulset1-0     1/1     Running   0          32m

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc1    NodePort    10.233.11.247   <none>        9000:30091/TCP   32m
service/dbprod1         ClusterIP   10.233.55.33    <none>        5432/TCP         32m
service/external-svc    ClusterIP   10.233.63.47    <none>        80/TCP           109s
service/frontend-svc1   NodePort    10.233.6.21     <none>        8000:30081/TCP   32m
```

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
