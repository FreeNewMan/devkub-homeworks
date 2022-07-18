# Домашнее задание к занятию "13.4 инструменты для упрощения написания конфигурационных файлов. Helm и Jsonnet"
В работе часто приходится применять системы автоматической генерации конфигураций. Для изучения нюансов использования разных инструментов нужно попробовать упаковать приложение каждым из них.

## Задание 1: подготовить helm чарт для приложения
Необходимо упаковать приложение в чарт для деплоя в разные окружения. Требования:
* каждый компонент приложения деплоится отдельным deployment’ом/statefulset’ом;
* в переменных чарта измените образ приложения для изменения версии.

### Ответ:

Создадим шаблон проекта: 
```
helm create myfirst
```
В каталоге templates оставим только NOTES.txt и _helpers.tpl

В NOTES.txt сделаем так:

```
---------------------------------------------------------

Content of NOTES.txt appears after deploy.
Deployed to {{ .Values.namespace }} namespace.

---------------------------------------------------------
```

В файл values.yaml вынесем значения всех перменных приложения

```
namespace: prod

configMap:
  name: postgres-configuration

db:
  replicaCount: 1
  statefulSetName: postgres-statefulset
  serviceName: dbprod
  image: 
    repository: postgres
    tag: 13-alpine
  port: 5432
  credentials:
    POSTGRES_DB: news
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres

back:
  replicaCount: 1
  deploymentName: backend
  serviceName: backend-svc
  image: 
    repository:  lutovp/test-backend
    tag: 0.0.1 
  port: 9000
  nodePort: 30090

front: 
  replicaCount: 1
  deploymentName: frontend 
  serviceName: frontend-svc
  image: 
    repository:  lutovp/test-frontend
    tag: 0.0.7 
  port: 8000
  targetPort: 80
  nodePort: 30080

```

Доработаем манифесты проекта из предыдущего дз

База данных:

```
#10-db-configmap.yml

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.configMap.name }}
  namespace: {{ .Values.namespace }}
  labels:
    app: postgres
data:
{{- toYaml .Values.db.credentials | nindent 2 }}
```

```
#11-db-statefulset.yml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Values.db.statefulSetName }}  
  namespace: {{ .Values.namespace }}  
  labels:
    app: postgres
spec:
  serviceName: "postgres"
  replicas:  {{ .Values.db.replicaCount }}
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: {{ .Values.db.image.repository }}:{{ .Values.db.image.tag }}
        envFrom:
        - configMapRef:
            name: {{ .Values.configMap.name }} 
        ports:
        - containerPort: {{.Values.db.port }}
          name: postgresdb

```


```
#12-db-service.yml

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.db.serviceName }} 
  namespace: {{ .Values.namespace }}  
  labels:
    app: postgres
spec:
  ports:
  - port: {{ .Values.db.port }}
    name: postgres
  type: ClusterIP 
  selector:
    app: postgres
```

Бекенд

```
#20-bk-backend.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: backend
  name: {{ .Values.back.deploymentName }} 
  namespace: {{ .Values.namespace }}    
spec:
  replicas: {{ .Values.back.replicaCount }}
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - image:  {{ .Values.back.image.repository }}:{{ .Values.back.image.tag }} 
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: {{ .Values.back.port }}
          env:
            - name: DATABASE_URL
              value: postgres://{{ .Values.db.credentials.POSTGRES_USER }}:{{ .Values.db.credentials.POSTGRES_PASSWORD }}@{{ .Values.db.serviceName }}:{{ .Values.db.port }}/{{ .Values.db.credentials.POSTGRES_DB }} 


```

```
#21-bk-service.yml

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.back.serviceName }}
  namespace: {{ .Values.namespace }}  
spec:
  ports:
    - name: web
      port:  {{ .Values.back.port }}
      targetPort:  {{ .Values.back.port }}  
      nodePort:  {{ .Values.back.nodePort }}            
  selector:
    app: backend
  type: NodePort
```

Фронтэнд

```
#30-fr-frontend.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: frontend
  name: {{ .Values.front.deploymentName }} 
  namespace: {{ .Values.namespace }}   
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - image:  {{ .Values.front.image.repository }}:{{ .Values.front.image.tag }} 
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: {{ .Values.front.port }}       

```

```
#31-fr-service.yml

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.front.serviceName }}
  namespace: {{ .Values.namespace }}  
spec:
  ports:
    - name: web
      port: {{ .Values.front.port }} 
      targetPort: {{ .Values.front.targetPort }}      
      nodePort:  {{ .Values.front.nodePort }}      
  selector:
    app: frontend
  type: NodePort

```

В Файле описания чарта пропишем версию приложения и самого чарта

```
apiVersion: v2
name: myfirst
description: A Helm chart for Kubernetes

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
type: application

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
# Versions are expected to follow Semantic Versioning (https://semver.org/)
version: 0.0.1

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application. Versions are not expected to
# follow Semantic Versioning. They should reflect the version the application is using.
# It is recommended to use it with quotes.
appVersion: "0.0.1"


```

Проверяем генерацию манифестов:

```
 helm template myfirst

opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm template myfirst/
---
# Source: myfirst/templates/10-db-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-configuration
  namespace: prod
  labels:
    app: postgres
data:
  POSTGRES_DB: news
  POSTGRES_PASSWORD: postgres
  POSTGRES_USER: postgres
---
# Source: myfirst/templates/12-db-service.yml
apiVersion: v1
kind: Service
metadata:
  name: dbprod 
  namespace: prod  
  labels:
    app: postgres
spec:
  ports:
  - port: 5432
    name: postgres
  type: ClusterIP 
  selector:
    app: postgres
---
# Source: myfirst/templates/21-bk-service.yml
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: prod  
spec:
  ports:
    - name: web
      port:  9000
      targetPort:  9000  
      nodePort:  30090            
  selector:
    app: backend
  type: NodePort
---
# Source: myfirst/templates/31-fr-service.yml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: prod  
spec:
  ports:
    - name: web
      port: 8000 
      targetPort: 80      
      nodePort:  30080      
  selector:
    app: frontend
  type: NodePort
---
# Source: myfirst/templates/20-bk-backend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: backend
  name: backend 
  namespace: prod    
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - image:  lutovp/test-backend:0.0.1 
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: 9000
          env:
            - name: DATABASE_URL
              value: postgres://postgres:postgres@dbprod:5432/news
---
# Source: myfirst/templates/30-fr-frontend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: frontend
  name: frontend 
  namespace: prod   
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - image:  lutovp/test-frontend:0.0.7 
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 8000
---
# Source: myfirst/templates/11-db-statefulset.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-statefulset  
  namespace: prod  
  labels:
    app: postgres
spec:
  serviceName: "postgres"
  replicas:  1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        envFrom:
        - configMapRef:
            name: postgres-configuration 
        ports:
        - containerPort: 5432
          name: postgresdb


```

```
Отредактирем файл values.yaml. Изменим тег/версию образа фронтеда 
0.0.7 на 0.0.1 и запустим генерацию общего манифеста
```

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm template myfirst/
---
# Source: myfirst/templates/10-db-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-configuration
  namespace: prod
  labels:
    app: postgres
data:
  POSTGRES_DB: news
  POSTGRES_PASSWORD: postgres
  POSTGRES_USER: postgres
---
# Source: myfirst/templates/12-db-service.yml
apiVersion: v1
kind: Service
metadata:
  name: dbprod 
  namespace: prod  
  labels:
    app: postgres
spec:
  ports:
  - port: 5432
    name: postgres
  type: ClusterIP 
  selector:
    app: postgres
---
# Source: myfirst/templates/21-bk-service.yml
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: prod  
spec:
  ports:
    - name: web
      port:  9000
      targetPort:  9000  
      nodePort:  30090            
  selector:
    app: backend
  type: NodePort
---
# Source: myfirst/templates/31-fr-service.yml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: prod  
spec:
  ports:
    - name: web
      port: 8000 
      targetPort: 80      
      nodePort:  30080      
  selector:
    app: frontend
  type: NodePort
---
# Source: myfirst/templates/20-bk-backend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: backend
  name: backend 
  namespace: prod    
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - image:  lutovp/test-backend:0.0.1 
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: 9000
          env:
            - name: DATABASE_URL
              value: postgres://postgres:postgres@dbprod:5432/news
---
# Source: myfirst/templates/30-fr-frontend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: frontend
  name: frontend 
  namespace: prod   
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - image:  lutovp/test-frontend:0.0.1 
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 8000
---
# Source: myfirst/templates/11-db-statefulset.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-statefulset  
  namespace: prod  
  labels:
    app: postgres
spec:
  serviceName: "postgres"
  replicas:  1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        envFrom:
        - configMapRef:
            name: postgres-configuration 
        ports:
        - containerPort: 5432
          name: postgresdb
```


## Задание 2: запустить 2 версии в разных неймспейсах
Подготовив чарт, необходимо его проверить. Попробуйте запустить несколько копий приложения:
* одну версию в namespace=app1;
* вторую версию в том же неймспейсе;
* третью версию в namespace=app2.



Создадим namspace app1
```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> kubectl create ns app1
namespace/app1 created

```

Установим первую версию в namspace app1

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm install release1 --set namespace=app1 --namespace=app1 myfirst
NAME: release1
LAST DEPLOYED: Mon Jul 18 11:48:00 2022
NAMESPACE: app1
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
---------------------------------------------------------

Content of NOTES.txt appears after deploy.
Deployed to app1 namespace.

---------------------------------------------------------
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm list -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
release1        app1            1               2022-07-18 11:48:00.760636895 +0500 +05 deployed        myfirst-0.0.1   0.0.1   

```

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> kubectl get pods -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS       AGE
app1          backend-775d99f5fb-dcc2z          1/1     Running   0              13s
app1          frontend-58995dbf4-zmwk9          1/1     Running   0              13s
app1          postgres-statefulset-0            1/1     Running   0              12s
```


Чтобы установить другую версию в тот же нейспейс нужно изменить values.
Изменим именя ресурсов, и nodeport чтобы не было пересечений. Также изменим версию в файле Chart.yaml
 Сделаем копию файла values
```
#values-app1-v2.yaml
namespace: app1

configMap:
  name: postgres-configuration1

db:
  replicaCount: 1
  statefulSetName: postgres-statefulset2
  serviceName: dbprod2
  image: 
    repository: postgres
    tag: 13-alpine
  port: 5432
  credentials:
    POSTGRES_DB: news
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres

back:
  replicaCount: 1
  deploymentName: backend2
  serviceName: backend-svc2
  image: 
    repository:  lutovp/test-backend
    tag: 0.0.1 
  port: 9000
  nodePort: 30091

front: 
  replicaCount: 1
  deploymentName: frontend2 
  serviceName: frontend-svc2
  image: 
    repository:  lutovp/test-frontend
    tag: 0.0.7 
  port: 8000
  targetPort: 80
  nodePort: 30081

```

Установим новую версию в тот же namespace.

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm install release2 --set namespace=app1 --namespace=app1 -f myfirst/values-app1-v2.yaml  myfirst
NAME: release2
LAST DEPLOYED: Mon Jul 18 12:00:46 2022
NAMESPACE: app1
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
---------------------------------------------------------

Content of NOTES.txt appears after deploy.
Deployed to app1 namespace.

---------------------------------------------------------

```
Проверим поды и сервисы

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> kubectl get po,svc -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS       AGE
app1          pod/backend-775d99f5fb-dcc2z          1/1     Running   0              16m
app1          pod/backend2-7598889bf6-gcggf         1/1     Running   0              3m25s
app1          pod/frontend-58995dbf4-zmwk9          1/1     Running   0              16m
app1          pod/frontend2-58995dbf4-52hfv         1/1     Running   0              3m25s
app1          pod/postgres-statefulset-0            1/1     Running   0              16m
app1          pod/postgres-statefulset2-0           1/1     Running   0              3m25s
kube-system   pod/calico-node-72dnh                 1/1     Running   13 (77m ago)   8d
kube-system   pod/calico-node-tmkjs                 1/1     Running   13 (77m ago)   8d
kube-system   pod/calico-node-tsvs9                 1/1     Running   14 (77m ago)   8d
kube-system   pod/coredns-666959ff67-5kbm7          1/1     Running   13 (77m ago)   8d
kube-system   pod/coredns-666959ff67-b58fl          1/1     Running   13 (77m ago)   8d
kube-system   pod/dns-autoscaler-59b8867c86-4xnvh   1/1     Running   13 (77m ago)   8d
kube-system   pod/kube-apiserver-cp1                1/1     Running   14 (77m ago)   8d
kube-system   pod/kube-controller-manager-cp1       1/1     Running   15 (77m ago)   8d
kube-system   pod/kube-proxy-gfdsf                  1/1     Running   13 (77m ago)   8d
kube-system   pod/kube-proxy-qb22v                  1/1     Running   13 (77m ago)   8d
kube-system   pod/kube-proxy-st2bh                  1/1     Running   13 (77m ago)   8d
kube-system   pod/kube-scheduler-cp1                1/1     Running   15 (77m ago)   8d
kube-system   pod/nginx-proxy-node1                 1/1     Running   13 (77m ago)   8d
kube-system   pod/nginx-proxy-node2                 1/1     Running   14 (77m ago)   8d
kube-system   pod/nodelocaldns-2njjf                1/1     Running   26 (77m ago)   8d
kube-system   pod/nodelocaldns-cqqqg                1/1     Running   50 (77m ago)   8d
kube-system   pod/nodelocaldns-q66km                1/1     Running   50 (77m ago)   8d

NAMESPACE     NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
app1          service/backend-svc     NodePort    10.233.35.209   <none>        9000:30090/TCP           16m
app1          service/backend-svc2    NodePort    10.233.51.34    <none>        9000:30091/TCP           3m25s
app1          service/dbprod          ClusterIP   10.233.17.211   <none>        5432/TCP                 16m
app1          service/dbprod2         ClusterIP   10.233.24.108   <none>        5432/TCP                 3m25s
app1          service/frontend-svc    NodePort    10.233.0.31     <none>        8000:30080/TCP           16m
app1          service/frontend-svc2   NodePort    10.233.30.163   <none>        8000:30081/TCP           3m25s
default       service/kubernetes      ClusterIP   10.233.0.1      <none>        443/TCP                  8d
kube-system   service/coredns         ClusterIP   10.233.0.3      <none>        53/UDP,53/TCP,9153/TCP   8d
```


Создадим namespace app2

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> kubectl create ns app2
namespace/app2 created

```
Создадим новый конфиг с новыми именами и nodePort

```
#values-app2-v3.yaml

namespace: app2

configMap:
  name: postgres-configuration2

db:
  replicaCount: 1
  statefulSetName: postgres-statefulset3
  serviceName: dbprod3
  image: 
    repository: postgres
    tag: 13-alpine
  port: 5432
  credentials:
    POSTGRES_DB: news
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres

back:
  replicaCount: 1
  deploymentName: backend3
  serviceName: backend-svc3
  image: 
    repository:  lutovp/test-backend
    tag: 0.0.1 
  port: 9000
  nodePort: 30092

front: 
  replicaCount: 1
  deploymentName: frontend3 
  serviceName: frontend-svc3
  image: 
    repository:  lutovp/test-frontend
    tag: 0.0.7 
  port: 8000
  targetPort: 80
  nodePort: 30082


```
Отредактирем Chart.yaml

```
apiVersion: v2
name: myfirst
description: A Helm chart for Kubernetes

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
type: application

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
# Versions are expected to follow Semantic Versioning (https://semver.org/)
version: 0.0.1

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application. Versions are not expected to
# follow Semantic Versioning. They should reflect the version the application is using.
# It is recommended to use it with quotes.
appVersion: "0.0.3"

```

Деплоим новый релиз и смотрим что получилось

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm install release3 --set namespace=app2 --namespace=app2 -f myfirst/values-app2-v3.yaml  myfirst
NAME: release3
LAST DEPLOYED: Mon Jul 18 12:11:52 2022
NAMESPACE: app2
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
---------------------------------------------------------

Content of NOTES.txt appears after deploy.
Deployed to app2 namespace.

---------------------------------------------------------
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> helm list -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
release1        app1            1               2022-07-18 11:48:00.760636895 +0500 +05 deployed        myfirst-0.0.1   0.0.1      
release2        app1            1               2022-07-18 12:00:46.966022311 +0500 +05 deployed        myfirst-0.0.1   0.0.2      
release3        app2            1               2022-07-18 12:11:52.767800772 +0500 +05 deployed        myfirst-0.0.1   0.0.3      
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-04-helm/charts$ 
> kubectl get po,svc -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS       AGE
app1          pod/backend-775d99f5fb-dcc2z          1/1     Running   0              24m
app1          pod/backend2-7598889bf6-gcggf         1/1     Running   0              11m
app1          pod/frontend-58995dbf4-zmwk9          1/1     Running   0              24m
app1          pod/frontend2-58995dbf4-52hfv         1/1     Running   0              11m
app1          pod/postgres-statefulset-0            1/1     Running   0              24m
app1          pod/postgres-statefulset2-0           1/1     Running   0              11m
app2          pod/backend3-54595f9b9f-qhq4s         1/1     Running   0              24s
app2          pod/frontend3-58995dbf4-752x5         1/1     Running   0              24s
app2          pod/postgres-statefulset3-0           1/1     Running   0              24s
kube-system   pod/calico-node-72dnh                 1/1     Running   13 (85m ago)   8d
kube-system   pod/calico-node-tmkjs                 1/1     Running   13 (85m ago)   8d
kube-system   pod/calico-node-tsvs9                 1/1     Running   14 (85m ago)   8d
kube-system   pod/coredns-666959ff67-5kbm7          1/1     Running   13 (85m ago)   8d
kube-system   pod/coredns-666959ff67-b58fl          1/1     Running   13 (85m ago)   8d
kube-system   pod/dns-autoscaler-59b8867c86-4xnvh   1/1     Running   13 (85m ago)   8d
kube-system   pod/kube-apiserver-cp1                1/1     Running   14 (85m ago)   8d
kube-system   pod/kube-controller-manager-cp1       1/1     Running   15 (85m ago)   8d
kube-system   pod/kube-proxy-gfdsf                  1/1     Running   13 (85m ago)   8d
kube-system   pod/kube-proxy-qb22v                  1/1     Running   13 (85m ago)   8d
kube-system   pod/kube-proxy-st2bh                  1/1     Running   13 (85m ago)   8d
kube-system   pod/kube-scheduler-cp1                1/1     Running   15 (85m ago)   8d
kube-system   pod/nginx-proxy-node1                 1/1     Running   13 (85m ago)   8d
kube-system   pod/nginx-proxy-node2                 1/1     Running   14 (85m ago)   8d
kube-system   pod/nodelocaldns-2njjf                1/1     Running   26 (85m ago)   8d
kube-system   pod/nodelocaldns-cqqqg                1/1     Running   50 (85m ago)   8d
kube-system   pod/nodelocaldns-q66km                1/1     Running   50 (85m ago)   8d

NAMESPACE     NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
app1          service/backend-svc     NodePort    10.233.35.209   <none>        9000:30090/TCP           24m
app1          service/backend-svc2    NodePort    10.233.51.34    <none>        9000:30091/TCP           11m
app1          service/dbprod          ClusterIP   10.233.17.211   <none>        5432/TCP                 24m
app1          service/dbprod2         ClusterIP   10.233.24.108   <none>        5432/TCP                 11m
app1          service/frontend-svc    NodePort    10.233.0.31     <none>        8000:30080/TCP           24m
app1          service/frontend-svc2   NodePort    10.233.30.163   <none>        8000:30081/TCP           11m
app2          service/backend-svc3    NodePort    10.233.34.27    <none>        9000:30092/TCP           24s
app2          service/dbprod3         ClusterIP   10.233.35.161   <none>        5432/TCP                 24s
app2          service/frontend-svc3   NodePort    10.233.56.93    <none>        8000:30082/TCP           24s
default       service/kubernetes      ClusterIP   10.233.0.1      <none>        443/TCP                  8d
kube-system   service/coredns         ClusterIP   10.233.0.3      <none>        53/UDP,53/TCP,9153/TCP   8d

```


## Задание 3 (*): повторить упаковку на jsonnet
Для изучения другого инструмента стоит попробовать повторить опыт упаковки из задания 1, только теперь с помощью инструмента jsonnet.

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
