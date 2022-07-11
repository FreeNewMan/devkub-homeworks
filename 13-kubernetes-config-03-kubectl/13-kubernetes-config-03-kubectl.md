# Домашнее задание к занятию "13.3 работа с kubectl"
## Задание 1: проверить работоспособность каждого компонента
Для проверки работы можно использовать 2 способа: port-forward и exec. Используя оба способа, проверьте каждый компонент:
* сделайте запросы к бекенду;
* сделайте запросы к фронту;
* подключитесь к базе данных.

```
opsuser@opsserver:~/home_works$ 
> kubectl get po,svc -n prod
NAME                           READY   STATUS    RESTARTS      AGE
pod/backend-775d99f5fb-k7mvs   1/1     Running   0             83s
pod/frontend-5867f477d-gqgk7   1/1     Running   1 (53m ago)   4h54m
pod/postgres-statefulset-0     1/1     Running   1 (53m ago)   4h55m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc    NodePort    10.233.61.246   <none>        9000:30090/TCP   83s
service/dbprod         ClusterIP   10.233.7.219    <none>        5432/TCP         4h55m
service/frontend-svc   NodePort    10.233.17.12    <none>        8000:30080/TCP   4h54m
```

Проверим трафик из пода  фронтенда в бекенд:

```
> kubectl exec frontend-5867f477d-gqgk7 -n prod -- curl backend-svc:9000
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    22  100    22    0     0   4400      0 --:--:-- --:--:-- --:--:--  4400
{"detail":"Not Found"}opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-03-kubectl/manifests$ 
```
Ответ есть!

Поднимем multotool для проверки текщих подов из другого пода

```
#multitool.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: multitool
  name: multitool
  namespace: prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multitool
  template:
    metadata:
      labels:
        app: multitool
    spec:
      containers:
        - image: praqma/network-multitool:alpine-extra
          imagePullPolicy: IfNotPresent
          name: network-multitool
      terminationGracePeriodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: multitool
  namespace: prod
spec:
  ports:
    - name: web
      port: 80
  selector:
    app: multitool

```

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-03-kubectl/manifests$ 
> kubectl apply -f multitool.yml 
deployment.apps/multitool created
service/multitool created
```

Смотрим что сейчас есть:

```
Every 2.0s: kubectl get po,svc -n prod                                                                                 opsserver: Mon Jul 11 16:16:34 2022

NAME                             READY   STATUS    RESTARTS      AGE
pod/backend-775d99f5fb-k7mvs     1/1     Running   0             5m59s
pod/frontend-5867f477d-gqgk7     1/1     Running   1 (58m ago)   4h59m
pod/multitool-5958664c8b-7l4zp   1/1     Running   0             28s
pod/postgres-statefulset-0       1/1     Running   1 (58m ago)   4h59m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc    NodePort    10.233.61.246   <none>        9000:30090/TCP   5m59s
service/dbprod         ClusterIP   10.233.7.219    <none>        5432/TCP         4h59m
service/frontend-svc   NodePort    10.233.17.12    <none>        8000:30080/TCP   4h59m
service/multitool      ClusterIP   10.233.48.97    <none>        80/TCP           28s
```

Проверим подключение из multitool к фронтенду, к бекенду и к базе данных

```
> kubectl exec multitool-5958664c8b-7l4zp -n prod -- curl backend-svc:9000
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    22  100    22    0     0   5962      0 --:--:-- --:--:-- --:--:--  7333{"detail":"Not Found"}
```
Бекенд ок

```
> kubectl exec multitool-5958664c8b-7l4zp -n prod -- curl frontend-svc:8000
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0<!DOCTYPE html>
<html lang="ru">
<head>
    <title>Список</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/build/main.css" rel="stylesheet">
</head>
<body>
    <main class="b-page">
        <h1 class="b-page__title">Список</h1>
        <div class="b-page__content b-items js-list"></div>
    </main>
    <script src="/build/main.js"></script>
</body>
100   448  100   448    0     0   129k      0 --:--:-- --:--:-- --:--:--  145k

```
Фронт ок


```
> kubectl exec multitool-5958664c8b-7l4zp -n prod -- psql postgres://postgres:postgres@dbprod:5432/news -c "select count(*) from news"
 count 
-------
    25
(1 row)
```
Подключение к базе есть



## Задание 2: ручное масштабирование

При работе с приложением иногда может потребоваться вручную добавить пару копий. Используя команду kubectl scale, попробуйте увеличить количество бекенда и фронта до 3. Проверьте, на каких нодах оказались копии после каждого действия (kubectl describe, kubectl get pods -o wide). После уменьшите количество копий до 1.

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
> kubectl scale --replicas=3 deployments.apps/backend -n prod
deployment.apps/backend scaled
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
> kubectl scale --replicas=3 deployments.apps/frontend -n prod
deployment.apps/frontend scaled

```


```
Every 2.0s: kubectl get po,svc -n prod                                                                                 opsserver: Mon Jul 11 16:30:45 2022

NAME                             READY   STATUS    RESTARTS      AGE
pod/backend-775d99f5fb-b2pxt     1/1     Running   0             52s
pod/backend-775d99f5fb-k7mvs     1/1     Running   0             20m
pod/backend-775d99f5fb-xjvrw     1/1     Running   0             52s
pod/frontend-5867f477d-gqgk7     1/1     Running   1 (72m ago)   5h13m
pod/frontend-5867f477d-h5pqs     1/1     Running   0             32s
pod/frontend-5867f477d-x7nhn     1/1     Running   0             32s
pod/multitool-5958664c8b-7l4zp   1/1     Running   0             14m
pod/postgres-statefulset-0       1/1     Running   1 (72m ago)   5h13m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc    NodePort    10.233.61.246   <none>        9000:30090/TCP   20m
service/dbprod         ClusterIP   10.233.7.219    <none>        5432/TCP         5h13m
service/frontend-svc   NodePort    10.233.17.12    <none>        8000:30080/TCP   5h13m
service/multitool      ClusterIP   10.233.48.97    <none>        80/TCP           14m

```

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
> kubectl scale --replicas=1 deployments.apps/backend -n prod
deployment.apps/backend scaled
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
> kubectl scale --replicas=1 deployments.apps/frontend -n prod
deployment.apps/frontend scaled
```

```
Every 2.0s: kubectl get po,svc -n prod                                                                                 opsserver: Mon Jul 11 16:31:59 2022

NAME                             READY   STATUS    RESTARTS      AGE
pod/backend-775d99f5fb-k7mvs     1/1     Running   0             21m
pod/frontend-5867f477d-x7nhn     1/1     Running   0             106s
pod/multitool-5958664c8b-7l4zp   1/1     Running   0             15m
pod/postgres-statefulset-0       1/1     Running   1 (73m ago)   5h15m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-svc    NodePort    10.233.61.246   <none>        9000:30090/TCP   21m
service/dbprod         ClusterIP   10.233.7.219    <none>        5432/TCP         5h15m
service/frontend-svc   NodePort    10.233.17.12    <none>        8000:30080/TCP   5h14m
service/multitool      ClusterIP   10.233.48.97    <none>        80/TCP           15m


```
---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
