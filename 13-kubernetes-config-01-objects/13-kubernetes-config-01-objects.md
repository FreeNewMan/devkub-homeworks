# Домашнее задание к занятию "13.1 контейнеры, поды, deployment, statefulset, services, endpoints"
Настроив кластер, подготовьте приложение к запуску в нём. Приложение стандартное: бекенд, фронтенд, база данных. Его можно найти в папке 13-kubernetes-config.

## Задание 1: подготовить тестовый конфиг для запуска приложения
Для начала следует подготовить запуск приложения в stage окружении с простыми настройками. Требования:
* под содержит в себе 2 контейнера — фронтенд, бекенд;
* регулируется с помощью deployment фронтенд и бекенд;
* база данных — через statefulset.

#### Ответ:
Фронтенд часть приложение написано на js. По описанию Dockerfile и файлу настроек config.js видно, что для доступа к данным нужен URL беэенда, переменная BASE_URL:

Ее значение задаем в файле .env перед сборкой. Укажем там адрес кластера и порт через которые можно получить даныне бекенда

BASE_URL=http://192.168.90.135:30090

Соберем frontend контейнер и загрузим его в репозиторий
```
docker build -t lutovp/test-frontend:0.0.7 .
```
```
docker push lutovp/test-frontend:0.0.7 
```
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/13-kubernetes-config/frontend$ docker build -t lutovp/test-frontend:0.0.7 .
Sending build context to Docker daemon  430.6kB
Step 1/14 : FROM node:lts-buster as builder
 ---> b9f398d30e45
Step 2/14 : RUN mkdir /app
 ---> Using cache

```
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/13-kubernetes-config/frontend$ docker push lutovp/test-frontend:0.0.7 
The push refers to repository [docker.io/lutovp/test-frontend]
206bf5621531: Pushed 
069df5ac6784: Pushed 
ce194e6833cf: Pushed 
a7efede9ac60: Pushed 
e7344f8a29a3: Pushed 
44193d3f4ea2: Pushed 
41451f050aa8: Pushed 
b2f82de68e0d: Pushed 
d5b40e80384b: Pushed 
08249ce7456a: Pushed 
0.0.1: digest: sha256:b83697085a07a13a76a4dcbcb470359e01977a2358289c36954c655c638e1f30 size: 2401
```

Соберем backend контейнер и загрузим его в репозиторий

```
docker build -t lutovp/test-backend:0.0.1 .
```
```
docker push lutovp/test-backend:0.0.1 
```
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/13-kubernetes-config/backend$ docker build -t lutovp/test-backend:0.0.1 .
Sending build context to Docker daemon  19.46kB
Step 1/8 : FROM python:3.9-buster
 ---> 999912f2c071
Step 2/8 : RUN mkdir /app && python -m pip install pipenv
 ---> Using cache
 ---> d9b78c6d5427
Step 3/8 : WORKDIR /app
 ---> Using cache
```

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/13-kubernetes-config/backend$ docker push lutovp/test-backend:0.0.1 The push refers to repository [docker.io/lutovp/test-backend]
40760574ce65: Pushed 
297faeb707de: Pushed 
22fc1da79ed0: Pushed 
f536b816f39e: Pushed 
579e7afd94b3: Pushed 
843f990feb92: Mounted from library/python 
70dce5ebf427: Mounted from library/python 
aba5ac262080: Mounted from library/python 
2df8715307ad: Mounted from library/python 
e6fd4ebbaaab: Mounted from library/python 
261e5d6450d3: Mounted from library/python 
65d22717bade: Mounted from library/python 
3abde9518332: Mounted from library/python 
0c8724a82628: Mounted from library/python 
0.0.1: digest: sha256:60c31aab3f08b69e1085cc2cf0031818478f8b2ad8b45a0c5ede5fb0cd818601 size: 3264

```
 Создадим Namespace stage
```
kubectl create ns stage
```

Создадим манифесты для postgres. 


```
#сonfigmap.yml 

apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-configuration
  namespace: stage  
  labels:
    app: postgres
data:
  POSTGRES_DB: news
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
```

```
#statefulset.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-statefulset
  namespace: stage  
  labels:
    app: postgres
spec:
  serviceName: "postgres"
  replicas: 1
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
#service.yml Сервис нужен чтобы можно было подключиться из других подов и извне кластрера 

apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: stage  
  labels:
    app: postgres
spec:
  ports:
  - port: 5432
    name: postgres
  type: ClusterIP 
  selector:
    app: postgres
```

Складываем в папку database и применяем
```
kubectl apply -f database/ -n stage
```


Создадим deployment для приложения:
```
#frontandback.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: news
  name: news
  namespace: stage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: news
  template:
    metadata:
      labels:
        app: news
    spec:
      containers:
        - image: lutovp/test-backend:0.0.1
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: 9000
        - image: lutovp/test-frontend:0.0.7
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 80

```
Cоздадим сервис типа NodePort для frontend
```
#service-front.yml

apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: stage
spec:
  ports:
    - name: web
      port: 8000
      targetPort: 80
      protocol: TCP      
      nodePort: 30080      
  selector:
    app: news
  type: NodePort


```
Бэкенд работает на 9000 порту. Чтобы бекенд был доступен по ранее указнному BASE_URL, сделам сервис типа NodePort и пропишем порт 30090
```
service-back.yml

apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: stage
spec:
  ports:
    - name: web
      port: 9000
      targetPort: 9000
      protocol: TCP      
      nodePort: 30090            
  selector:
    app: news
  type: NodePort

```

Применим манифесты:
```
kubectl apply -f frontback/ -n stage
``` 


В результате получаем:
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/stage$ kubectl get pods -n stage
NAME                         READY   STATUS    RESTARTS      AGE
multitool-5958664c8b-6869f   1/1     Running   1 (95m ago)   20h
news-86c7cd5c7-rlltx         2/2     Running   0             2m57s
postgres-statefulset-0       1/1     Running   1 (95m ago)   20h
```

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/stage$ kubectl get services -n stage
> kubectl get services -n stage
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
backend-svc    NodePort    10.233.35.249   <none>        9000:30090/TCP    2m24s
db             ClusterIP   10.233.5.240    <none>        5432/TCP          20h
frontend-svc   NodePort    10.233.60.106   <none>        8000:30080/TCP    2m24s
multitool      ClusterIP   10.233.15.247   <none>        80/TCP            20h
news           ClusterIP   10.233.46.13    <none>        9000/TCP,80/TCP   6h2m
```

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-01-objects/stage$ kubectl get deployments -n stage
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
news   1/1     1            1           23h
```

пробуем подключиться
![image info](images/pic1.png)


# Задание 2: подготовить конфиг для production окружения
Следующим шагом будет запуск приложения в production окружении. Требования сложнее:
* каждый компонент (база, бекенд, фронтенд) запускаются в своем поде, регулируются отдельными deployment’ами;
* для связи используются service (у каждого компонента свой);
* в окружении фронта прописан адрес сервиса бекенда;
* в окружении бекенда прописан адрес сервиса базы данных.

На prod будем открывать во внешний мир те же порты 30080 и 30090. 

Чтобы не было конфликтов удаляем namespace stage


Создадим Namespace prod
```
kubectl create ns prod
```
Для базы данных манифесты будут те же, за исключеним названия сервиса. В  stage было db, в prod сделаем dbprod. Чтобы было отличие от значние по умолчанию указанное в контейнере backend

```
#configmap.yml

apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-configuration
  namespace: prod  
  labels:
    app: postgres
data:
  POSTGRES_DB: news
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
```

```
#statefulset.yml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-statefulset
  namespace: prod  
  labels:
    app: postgres
spec:
  serviceName: "postgres"
  replicas: 1
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
#service.yml

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
```

Манифесты для backend
Пропишем переменную окружения для связи с базой указав в ней имя сервиса dbprod
DATABASE_URL
```
#backend.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: backend
  name: backend-svc
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
        - image: lutovp/test-backend:0.0.1
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: 9000
          env:  
            - name: DATABASE_URL
              value: "postgres://postgres:postgres@dbprod:5432/news"
```

Сервис для backend
```
#service.yml

apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: prod
spec:
  ports:
    - name: web
      port: 9000
      targetPort: 9000  
      nodePort: 30090            
  selector:
    app: backend
  type: NodePort
```


Манифесты для frontend
```
#frontend.yml

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
        - image: lutovp/test-frontend:0.0.7
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 80       

```

Сервис для frontend

```
#service.yml

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
      nodePort: 30080    
  selector:
    app: frontend
  type: NodePort

```
В итоге получаем:

Манифесты для базы: `manifests/prod/database/` 

Манифесты для бекенда: `manifests/prod/backend/` 

Манифесты для фронтенда: `manifests/prod/frontend/`

Применяем:

```
kubectl apply -f database/ 

kubectl apply -f backend/ 

kubectl apply -f frontend/ 
```

```
Every 2.0s: kubectl get pods,service -n prod                          opsserver: Sun Jul 10 19:58:02 2022

NAME                               READY   STATUS    RESTARTS   AGE
pod/backend-svc-775d99f5fb-d9fzd   1/1     Running   0          28m
pod/frontend-5867f477d-mqmcp       1/1     Running   0          38m
pod/postgres-statefulset-0         1/1     Running   0          28m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend        NodePort    10.233.39.52    <none>        9000:30090/TCP   28m
service/dbprod         ClusterIP   10.233.47.230   <none>        5432/TCP         28m
service/frontend-svc   NodePort    10.233.35.210   <none>        8000:30080/TCP   39m
```



## Задание 3 (*): добавить endpoint на внешний ресурс api
Приложению потребовалось внешнее api, и для его использования лучше добавить endpoint в кластер, направленный на это api. Требования:
* добавлен endpoint до внешнего api (например, геокодер).

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

В качестве решения прикрепите к ДЗ конфиг файлы для деплоя. Прикрепите скриншоты вывода команды kubectl со списком запущенных объектов каждого типа (pods, deployments, statefulset, service) или скриншот из самого Kubernetes, что сервисы подняты и работают.

---
