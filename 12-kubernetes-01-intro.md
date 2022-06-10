# Домашнее задание к занятию "12.1 Компоненты Kubernetes"

Вы DevOps инженер в крупной компании с большим парком сервисов. Ваша задача — разворачивать эти продукты в корпоративном кластере. 

## Задача 1: Установить Minikube

Для экспериментов и валидации ваших решений вам нужно подготовить тестовую среду для работы с Kubernetes. Оптимальное решение — развернуть на рабочей машине Minikube.

### Как поставить на AWS:
- создать EC2 виртуальную машину (Ubuntu Server 20.04 LTS (HVM), SSD Volume Type) с типом **t3.small**. Для работы потребуется настроить Security Group для доступа по ssh. Не забудьте указать keypair, он потребуется для подключения.
- подключитесь к серверу по ssh (ssh ubuntu@<ipv4_public_ip> -i <keypair>.pem)
- установите миникуб и докер следующими командами:
  - curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
  - chmod +x ./kubectl
  - sudo mv ./kubectl /usr/local/bin/kubectl
  - sudo apt-get update && sudo apt-get install docker.io conntrack -y
  - curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
- проверить версию можно командой minikube version
```
opuser@ubuntu20:~$ minikube version
minikube version: v1.25.2
commit: 362d5fdc0a3dbee389b3d3f1034e8023e72bd3a7

```

- переключаемся на root и запускаем миникуб: minikube start --vm-driver=none

```
root@ubuntu20:~# minikube start --vm-driver=none
* minikube v1.25.2 on Ubuntu 20.04 (amd64)
* Using the none driver based on user configuration
* Starting control plane node minikube in cluster minikube
* Running on localhost (CPUs=2, Memory=3931MB, Disk=15058MB) ...
* OS release is Ubuntu 20.04.4 LTS
* Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
  - kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
  - kubelet.housekeeping-interval=5m
    > kubelet.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubeadm.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl: 44.43 MiB / 44.43 MiB [-----------] 100.00% 278.61 MiB p/s 400ms
    > kubeadm: 43.12 MiB / 43.12 MiB [-----------] 100.00% 219.39 MiB p/s 400ms
    > kubelet: 118.75 MiB / 118.75 MiB [----------] 100.00% 108.43 MiB p/s 1.3s
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Configuring local host environment ...
* 
! The 'none' driver is designed for experts who need to integrate with an existing VM
* Most users should use the newer 'docker' driver instead, which does not require root!
* For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/
* 
! kubectl and minikube configuration will be stored in /root
! To use kubectl or minikube commands as your own user, you may need to relocate them. For example, to overwrite your own settings, run:
* 
  - sudo mv /root/.kube /root/.minikube $HOME
  - sudo chown -R $USER $HOME/.kube $HOME/.minikube
* 
* This can also be done automatically by setting the env var CHANGE_MINIKUBE_NONE_USER=true
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
root@ubuntu20:~# 

```

- после запуска стоит проверить статус: minikube status

```
root@ubuntu20:~# minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

```
- запущенные служебные компоненты можно увидеть командой: kubectl get pods --namespace=kube-system

```
root@ubuntu20:~# kubectl get pods --namespace=kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-64897985d-jsmcq            1/1     Running   0          68s
etcd-ubuntu20                      1/1     Running   0          78s
kube-apiserver-ubuntu20            1/1     Running   0          79s
kube-controller-manager-ubuntu20   1/1     Running   0          78s
kube-proxy-zntfs                   1/1     Running   0          68s
kube-scheduler-ubuntu20            1/1     Running   0          78s
storage-provisioner                1/1     Running   0          75s

```

### Для сброса кластера стоит удалить кластер и создать заново:
- minikube delete
```
root@ubuntu20:~# kubectl get pods --namespace=kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-64897985d-jsmcq            1/1     Running   0          68s
etcd-ubuntu20                      1/1     Running   0          78s
kube-apiserver-ubuntu20            1/1     Running   0          79s
kube-controller-manager-ubuntu20   1/1     Running   0          78s
kube-proxy-zntfs                   1/1     Running   0          68s
kube-scheduler-ubuntu20            1/1     Running   0          78s
storage-provisioner                1/1     Running   0          75s
root@ubuntu20:~# minikube delete
* Uninstalling Kubernetes v1.23.3 using kubeadm ...
* Deleting "minikube" in none ...
* Trying to delete invalid profile minikube
root@ubuntu20:~# 


root@ubuntu20:~# sudo sysctl fs.protected_regular=0
fs.protected_regular = 0

root@ubuntu20:~#  minikube start --vm-driver=none
* minikube v1.25.2 on Ubuntu 20.04 (amd64)
* Using the none driver based on user configuration
* Starting control plane node minikube in cluster minikube
* Running on localhost (CPUs=2, Memory=3931MB, Disk=15058MB) ...
* OS release is Ubuntu 20.04.4 LTS
* Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
  - kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
  - kubelet.housekeeping-interval=5m
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Configuring local host environment ...
* 
! The 'none' driver is designed for experts who need to integrate with an existing VM
* Most users should use the newer 'docker' driver instead, which does not require root!
* For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/
* 
! kubectl and minikube configuration will be stored in /root
! To use kubectl or minikube commands as your own user, you may need to relocate them. For example, to overwrite your own settings, run:
* 
  - sudo mv /root/.kube /root/.minikube $HOME
  - sudo chown -R $USER $HOME/.kube $HOME/.minikube
* 
* This can also be done automatically by setting the env var CHANGE_MINIKUBE_NONE_USER=true
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

root@ubuntu2010:~# kubectl get pods --namespace=kube-system
NAME                                             READY   STATUS    RESTARTS   AGE
etcd-ubuntu2010.localdomain                      1/1     Running   1          14s
kube-apiserver-ubuntu2010.localdomain            1/1     Running   1          10s
kube-controller-manager-ubuntu2010.localdomain   1/1     Running   1          10s
kube-scheduler-ubuntu2010.localdomain            1/1     Running   1          10s
storage-provisioner                              0/1     Pending   0          8s
root@ubuntu2010:~# minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

root@ubuntu20:~# kubectl get pods --namespace=kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-64897985d-6vq87            1/1     Running   0          33s
etcd-ubuntu20                      1/1     Running   1          45s
kube-apiserver-ubuntu20            1/1     Running   1          44s
kube-controller-manager-ubuntu20   1/1     Running   1          44s
kube-proxy-v8h4r                   1/1     Running   0          33s
kube-scheduler-ubuntu20            1/1     Running   1          45s
storage-provisioner                1/1     Running   0          42s

```


Возможно, для повторного запуска потребуется выполнить команду: sudo sysctl fs.protected_regular=0

Инструкция по установке Minikube - [ссылка](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)

**Важно**: t3.small не входит во free tier, следите за бюджетом аккаунта и удаляйте виртуалку.

## Задача 2: Запуск Hello World
После установки Minikube требуется его проверить. Для этого подойдет стандартное приложение hello world. А для доступа к нему потребуется ingress.

- развернуть через Minikube тестовое приложение по [туториалу](https://kubernetes.io/ru/docs/tutorials/hello-minikube/#%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0-minikube)

```
Создаем файл server.js c содержимым:

var http = require('http');

var handleRequest = function(request, response) {
  console.log('Получен запрос на URL: ' + request.url);
  response.writeHead(200);
  response.end('Hello World!'+'\r\n');
};
var www = http.createServer(handleRequest);
www.listen(8080);
```

```
Создаем Dockerfile:

FROM node:6.14.2
EXPOSE 8080
COPY server.js .
CMD [ "node", "server.js" ]

```

```
Собираем образ:

root@ubuntu20:~# docker build -t hello-node:v1 .
Sending build context to Docker daemon  219.6MB
Step 1/4 : FROM node:6.14.2
6.14.2: Pulling from library/node
3d77ce4481b1: Pull complete 
7d2f32934963: Pull complete 
0c5cf711b890: Pull complete 
9593dc852d6b: Pull complete 
4e3b8a1eb914: Pull complete 
ddcf13cc1951: Pull complete 
2e460d114172: Pull complete 
d94b1226fbf2: Pull complete 
Digest: sha256:62b9d88be259a344eb0b4e0dd1b12347acfe41c1bb0f84c3980262f8032acc5a
Status: Downloaded newer image for node:6.14.2
 ---> 00165cd5d0c0
Step 2/4 : EXPOSE 8080
 ---> Running in d9a47504122a
Removing intermediate container d9a47504122a
 ---> 9ea41c775b78
Step 3/4 : COPY server.js .
 ---> 7c5f4ad9ad1f
Step 4/4 : CMD [ "node", "server.js" ]
 ---> Running in 2d1e1209651e
Removing intermediate container 2d1e1209651e
 ---> 160ad868dc48
Successfully built 160ad868dc48
Successfully tagged hello-node:v1

```
```
Проверяем, работосопсобоность контейнера:
root@ubuntu20:~# docker run -d -p 80:8080 hello-node:v1

root@ubuntu20:~# docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS                                   NAMES
c4463315e7aa   hello-node:v1          "node server.js"         7 seconds ago    Up 7 seconds    0.0.0.0:80->8080/tcp, :::80->8080/tcp   quirky_lederberg


root@ubuntu20:~# curl 127.0.0.1
Hello World!
root@ubuntu20:~# 

```
```
Останавливаем и удаляем контейнер
docker rm -f c4463315e7aa
```

```
Создаем Deployment
root@ubuntu20:~# kubectl create deployment hello-node --image=hello-node:v1
deployment.apps/hello-node created

root@ubuntu20:~# kubectl get deployments
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   1/1     1            1           41s

root@ubuntu20:~# kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
hello-node-bd6795698-4fb5p   1/1     Running   0          70s


root@ubuntu20:~# kubectl get events
LAST SEEN   TYPE     REASON                    OBJECT                            MESSAGE
108s        Normal   Scheduled                 pod/hello-node-bd6795698-4fb5p    Successfully assigned default/hello-node-bd6795698-4fb5p to ubuntu20
108s        Normal   Pulled                    pod/hello-node-bd6795698-4fb5p    Container image "hello-node:v1" already present on machine
107s        Normal   Created                   pod/hello-node-bd6795698-4fb5p    Created container hello-node
107s        Normal   Started                   pod/hello-node-bd6795698-4fb5p    Started container hello-node
108s        Normal   SuccessfulCreate          replicaset/hello-node-bd6795698   Created pod: hello-node-bd6795698-4fb5p
108s        Normal   ScalingReplicaSet         deployment/hello-node             Scaled up replica set hello-node-bd6795698 to 1
39m         Normal   Starting                  node/ubuntu20                     Starting kubelet.
39m         Normal   NodeHasSufficientMemory   node/ubuntu20                     Node ubuntu20 status is now: NodeHasSufficientMemory
39m         Normal   NodeHasNoDiskPressure     node/ubuntu20                     Node ubuntu20 status is now: NodeHasNoDiskPressure
39m         Normal   NodeHasSufficientPID      node/ubuntu20                     Node ubuntu20 status is now: NodeHasSufficientPID
39m         Normal   NodeAllocatableEnforced   node/ubuntu20                     Updated Node Allocatable limit across pods
39m         Normal   NodeReady                 node/ubuntu20                     Node ubuntu20 status is now: NodeReady
39m         Normal   RegisteredNode            node/ubuntu20                     Node ubuntu20 event: Registered Node ubuntu20 in Controller
39m         Normal   Starting                  node/ubuntu20                     


root@ubuntu20:~# kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /root/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Sun, 05 Jun 2022 11:40:48 UTC
        provider: minikube.sigs.k8s.io
        version: v1.25.2
      name: cluster_info
    server: https://10.128.0.32:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Sun, 05 Jun 2022 11:40:48 UTC
        provider: minikube.sigs.k8s.io
        version: v1.25.2
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /root/.minikube/profiles/minikube/client.crt
    client-key: /root/.minikube/profiles/minikube/client.key


```

```
root@ubuntu20:~# kubectl expose deployment hello-node --type=LoadBalancer --port=8080
service/hello-node exposed

root@ubuntu20:~# kubectl get services
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
hello-node   LoadBalancer   10.108.66.210   <pending>     8080:30626/TCP   31s
kubernetes   ClusterIP      10.96.0.1       <none>        443/TCP          41m


```



- установить аддоны ingress и dashboard
```
root@ubuntu20:~# minikube addons enable ingress
  - Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
  - Using image k8s.gcr.io/ingress-nginx/controller:v1.1.1
  - Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
* Verifying ingress addon...
* The 'ingress' addon is enabled

```

```
root@ubuntu20:~# minikube service hello-node --url
http://10.128.0.32:30626


root@ubuntu20:~# curl http://10.128.0.32:30626

Hello World!
```
## Задача 3: Установить kubectl

Подготовить рабочую машину для управления корпоративным кластером. Установить клиентское приложение kubectl.
- подключиться к minikube 
- проверить работу приложения из задания 2, запустив port-forward до кластера

```
root@ubuntu20:~# kubectl get services
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
hello-node   LoadBalancer   10.98.1.193   <pending>     8080:32266/TCP   114m
kubernetes   ClusterIP      10.96.0.1     <none>        443/TCP          3h3m

```

```
kubectl port-forward service/hello-node 9000:8080
```

```
opuser@ubuntu20:~$ curl localhost:9000
Hello World!
opuser@ubuntu20:~$ 

```

## Задача 4 (*): собрать через ansible (необязательное)

Профессионалы не делают одну и ту же задачу два раза. Давайте закрепим полученные навыки, автоматизировав выполнение заданий  ansible-скриптами. При выполнении задания обратите внимание на доступные модули для k8s под ansible.
 - собрать роль для установки minikube на aws сервисе (с установкой ingress)
 - собрать роль для запуска в кластере hello world
  
  ---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
