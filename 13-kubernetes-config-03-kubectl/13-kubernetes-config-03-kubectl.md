# Домашнее задание к занятию "13.3 работа с kubectl"
## Задание 1: проверить работоспособность каждого компонента
Для проверки работы можно использовать 2 способа: port-forward и exec. Используя оба способа, проверьте каждый компонент:
* сделайте запросы к бекенду;
* сделайте запросы к фронту;
* подключитесь к базе данных.

```
opsuser@opsserver:~/home_works$ 
> kubectl get po,svc -n prod
NAME                               READY   STATUS    RESTARTS      AGE
pod/backend-svc-775d99f5fb-8tgsm   1/1     Running   1 (22m ago)   4h23m
pod/frontend-5867f477d-gqgk7       1/1     Running   1 (22m ago)   4h23m
pod/postgres-statefulset-0         1/1     Running   1 (22m ago)   4h23m

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/backend        NodePort    10.233.4.80    <none>        9000:30090/TCP   4h23m
service/dbprod         ClusterIP   10.233.7.219   <none>        5432/TCP         4h23m
service/frontend-svc   NodePort    10.233.17.12   <none>        8000:30080/TCP   4h23m
```

Проверим трафик из пода  фронтенда в бекенд:

```
opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
> kubectl exec frontend-5867f477d-gqgk7 -n prod -- curl backend:9000
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    22  100    22    0     0   3666      0 --:--:-- --:--:-- --:--:--  4400
{"detail":"Not Found"}opsuser@opsserver:~/home_works/devkub-homeworks/13-kubernetes-config-01-objects/manifests/prod$ 
```
Ответ есть!

Поднимем multotool для проверки текщих подов из другого пода




## Задание 2: ручное масштабирование

При работе с приложением иногда может потребоваться вручную добавить пару копий. Используя команду kubectl scale, попробуйте увеличить количество бекенда и фронта до 3. Проверьте, на каких нодах оказались копии после каждого действия (kubectl describe, kubectl get pods -o wide). После уменьшите количество копий до 1.

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
