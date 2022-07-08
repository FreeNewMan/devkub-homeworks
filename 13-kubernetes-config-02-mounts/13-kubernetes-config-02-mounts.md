# Домашнее задание к занятию "13.2 разделы и монтирование"
Приложение запущено и работает, но время от времени появляется необходимость передавать между бекендами данные. А сам бекенд генерирует статику для фронта. Нужно оптимизировать это.
Для настройки NFS сервера можно воспользоваться следующей инструкцией (производить под пользователем на сервере, у которого есть доступ до kubectl):
* установить helm: curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
* добавить репозиторий чартов: helm repo add stable https://charts.helm.sh/stable && helm repo update
* установить nfs-server через helm: helm install nfs-server stable/nfs-server-provisioner

В конце установки будет выдан пример создания PVC для этого сервера.

## Задание 1: подключить для тестового конфига общую папку
В stage окружении часто возникает необходимость отдавать статику бекенда сразу фронтом. Проще всего сделать это через общую папку. Требования:
* в поде подключена общая папка между контейнерами (например, /static);
* после записи чего-либо в контейнере с беком файлы можно получить из контейнера с фронтом.

### Ответ:
Создадим namespace stage
'''
kubectl create ns stage
'''

Внесем изменения в deployment. Укажем наличие тома my-volume типа emptyDir и укажем его в секции контейнеров. В контейнере backend укажем папку static_bk и  В контейнере frontend укажем папку static_ft. Файлы в них общими для обоих контйренров
'''
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
          volumeMounts:
            - mountPath: "/static_bk"
              name: my-volume            
        - image: lutovp/test-frontend:0.0.1
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 80    
          volumeMounts:
            - mountPath: "/static_fr"
              name: my-volume               
      volumes:
        - name: my-volume
          emptyDir: {}
'''

Применим деплоймент

```
kubectl apply -f frontback/
```
Проверим наличие пода
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl get pods -n stage
NAME                    READY   STATUS    RESTARTS   AGE
news-78db6b46b6-n2pz9   2/2     Running   0          3m19s
```

Проверим в поде backend наличие папки и что она пуста
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c backend -n stage -- sh -c "ls -la /static_bk"
total 8
drwxrwxrwx 2 root root 4096 Jul  8 08:26 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
```

Проверим в поде frontend наличие папки и что она пуста

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c frontend -n stage -- sh -c "ls -la /static_fr"
total 8
drwxrwxrwx 2 root root 4096 Jul  8 08:26 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
```

Создадим файл в контейнере backend в папке  /static_bk

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c backend -n stage -- sh -c "echo '99' > /static_bk/99.txt"
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c backend -n stage -- sh -c "ls -la /static_bk"
total 12
drwxrwxrwx 2 root root 4096 Jul  8 08:35 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
-rw-r--r-- 1 root root    3 Jul  8 08:35 99.txt

```

Проверим наличие файла 99.txt через контйнера frontend
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c frontend -n stage -- sh -c "ls -la /static_fr"
total 12
drwxrwxrwx 2 root root 4096 Jul  8 08:35 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
-rw-r--r-- 1 root root    3 Jul  8 08:35 99.txt
```

Создадим файл через контенйре frontend и проверим его наличие в backend


```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c frontend -n stage -- sh -c "echo '55' > /static_fr/55.txt"
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c frontend -n stage -- sh -c "ls -la /static_fr"
total 16
drwxrwxrwx 2 root root 4096 Jul  8 08:39 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
-rw-r--r-- 1 root root    3 Jul  8 08:39 55.txt
-rw-r--r-- 1 root root    3 Jul  8 08:35 99.txt
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/stage$
> kubectl exec news-78db6b46b6-n2pz9 -c backend -n stage -- sh -c "ls -la /static_bk"
total 16
drwxrwxrwx 2 root root 4096 Jul  8 08:39 .
drwxr-xr-x 1 root root 4096 Jul  8 08:26 ..
-rw-r--r-- 1 root root    3 Jul  8 08:39 55.txt
-rw-r--r-- 1 root root    3 Jul  8 08:35 99.txt

```



## Задание 2: подключить общую папку для прода
Поработав на stage, доработки нужно отправить на прод. В продуктиве у нас контейнеры крутятся в разных подах, поэтому потребуется PV и связь через PVC. Сам PV должен быть связан с NFS сервером. Требования:
* все бекенды подключаются к одному PV в режиме ReadWriteMany;
* фронтенды тоже подключаются к этому же PV с таким же режимом;
* файлы, созданные бекендом, должны быть доступны фронту.

### Ответ:
Создадим namespace prod
'''
kubectl create ns prod
'''


в деплоймент бекэнда пропишем монтирование volume внутри контйнера по пути /static_bk.
В разделе volume пропишем ссылку на заявку выделения тома c названием pvc2.
'''
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
        - image: lutovp/test-backend:0.0.1
          imagePullPolicy: IfNotPresent
          name: backend
          ports:
            - containerPort: 9000
          volumeMounts:
            - mountPath: "/static_bk"
              name: my-volume            

      volumes:
        - name: my-volume
          persistentVolumeClaim:
            claimName: pvc2

'''
Для frontend аналогично. Сыылка на заявку та же pvc1.

```
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
        - image: lutovp/test-frontend:0.0.1
          imagePullPolicy: IfNotPresent
          name: frontend
          ports:
            - containerPort: 80       
          volumeMounts:
            - mountPath: "/static_fr"
              name: my-volume            

      volumes:
        - name: my-volume
          persistentVolumeClaim:
            claimName: pvc2
```

Применим манифесты:
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl apply -f backend/
deployment.apps/backend created
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl apply -f frontend/
deployment.apps/frontend created
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl get po,pv,pvc -n prod
NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-f978b6888-4chck     0/1     Pending   0          4s
pod/frontend-85445946d4-m5bf6   0/1     Pending   0          11s
```

Как видно, поды в состоянии ожижания, т.к. нет выделенного тома и самой завки

Создадим манифест для выделения тома 

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv2
spec:
  storageClassName: "nfs"
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 100Mi
  hostPath:
    path: /data/pv2
```

Применим и проверим. 
```
 kubectl apply -f pv/
```

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
>  kubectl get po,pv,pvc -n prod
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-f978b6888-4chck     0/1     Pending   0          2m37s
pod/frontend-85445946d4-m5bf6   0/1     Pending   0          2m44s

NAME                   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
persistentvolume/pv2   100Mi      RWX            Retain           Available           nfs                     23s
```
Том создан, Поды в состоянии ожидания, т.к. нет самой заявки

Создадим манифест заявки:

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc2
  namespace: prod
spec:
  storageClassName: "nfs"
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
```

Применим
```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl apply -f pvc/
persistentvolumeclaim/pvc created
```
Смотрим что получилось. Через некторое время, контейнеры перейдут в состояни running

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> watch kubectl get po,pv,pvc -n prod

NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-f978b6888-4chck     1/1     Running   0          5m15s
pod/frontend-85445946d4-m5bf6   1/1     Running   0          5m22s

NAME                   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM       STORAGECLASS
REASON   AGE
persistentvolume/pv2   100Mi      RWX            Retain           Bound    prod/pvc2   nfs
         3m1s

NAME                         STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc2   Bound    pv2      100Mi      RWX            nfs            51s

```


Проверим в бекенде что папка есть и она пуста:
```
kubectl exec backend-f978b6888-4chck -c backend -n prod -- sh -c "ls -la /static_bk"


devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl exec backend-f978b6888-4chck -c backend -n prod -- sh -c "ls -la /static_bk"
total 8
drwxr-xr-x 2 root root 4096 Jul  8 10:54 .
drwxr-xr-x 1 root root 4096 Jul  8 11:00 ..
```

Создадим файл в backend и проверим его через frontend 

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl exec backend-f978b6888-4chck -c backend -n prod -- sh -c  "echo '777' > /static_bk/777.txt"

devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl exec frontend-85445946d4-m5bf6 -c frontend -n prod -- sh -c "ls -la /static_fr"
total 12
drwxr-xr-x 2 root root 4096 Jul  8 11:08 .
drwxr-xr-x 1 root root 4096 Jul  8 11:00 ..
-rw-r--r-- 1 root root    4 Jul  8 11:08 777.txt

```

Создадим файл в frontend и проверим его через backend  

```
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl exec frontend-85445946d4-m5bf6 -c frontend -n prod -- sh -c  "echo '999' > /static_fr/999.txt"
devuser@devuser-virtual-machine:~/home_works/13-kubernetes-config-02-mounts/manifests/prod$
> kubectl exec backend-f978b6888-4chck -c backend -n prod -- sh -c "ls -la /static_bk"
total 16
drwxr-xr-x 2 root root 4096 Jul  8 11:12 .
drwxr-xr-x 1 root root 4096 Jul  8 11:00 ..
-rw-r--r-- 1 root root    4 Jul  8 11:08 777.txt
-rw-r--r-- 1 root root    4 Jul  8 11:12 999.txt

```
---


### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
