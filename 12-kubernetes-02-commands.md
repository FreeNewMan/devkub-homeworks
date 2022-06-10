# Домашнее задание к занятию "12.2 Команды для работы с Kubernetes"
Кластер — это сложная система, с которой крайне редко работает один человек. Квалифицированный devops умеет наладить работу всей команды, занимающейся каким-либо сервисом.
После знакомства с кластером вас попросили выдать доступ нескольким разработчикам. Помимо этого требуется служебный аккаунт для просмотра логов.

## Задание 1: Запуск пода из образа в деплойменте
Для начала следует разобраться с прямым запуском приложений из консоли. Такой подход поможет быстро развернуть инструменты отладки в кластере. Требуется запустить деплоймент на основе образа из hello world уже через deployment. Сразу стоит запустить 2 копии приложения (replicas=2). 

Требования:
 * пример из hello world запущен в качестве deployment
 * количество реплик в deployment установлено в 2
 * наличие deployment можно проверить командой kubectl get deployment
 * наличие подов можно проверить командой kubectl get pods

```
Создание деполймента на основе образа
kubectl create deployment hello-node --image=hello-node:v1
```

```
Изменяем количество реплик (экземпляров)
kubectl edit deployment/hello-node

изменяем значение replicas
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2022-06-06T06:35:45Z"
  generation: 4
  labels:
    app: hello-node
  name: hello-node
  namespace: default
  resourceVersion: "30455"
  uid: 39282e4c-3814-46a1-bc42-f19e00905b46
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: hello-node
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-node
    spec:
      containers:
      - image: hello-node:v1
        imagePullPolicy: IfNotPresent
        name: hello-node
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2022-06-06T06:35:45Z"
    lastUpdateTime: "2022-06-06T06:35:47Z"
    message: ReplicaSet "hello-node-bd6795698" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  - lastTransitionTime: "2022-06-09T11:26:15Z"
    lastUpdateTime: "2022-06-09T11:26:15Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  observedGeneration: 4
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
```

```
root@ubuntu2010:~# kubectl get deployment
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   2/2     2            2           3d4h
```

```
root@ubuntu2010:~# kubectl get pods
NAME                         READY   STATUS    RESTARTS      AGE
hello-node-bd6795698-dpxm6   1/1     Running   0             6m50s
hello-node-bd6795698-nc8zb   1/1     Running   2 (18h ago)   3d4h
```

## Задание 2: Просмотр логов для разработки
Разработчикам крайне важно получать обратную связь от штатно работающего приложения и, еще важнее, об ошибках в его работе. 
Требуется создать пользователя и выдать ему доступ на чтение конфигурации и логов подов в app-namespace.

Требования: 
 * создан новый токен доступа для пользователя
 * пользователь прописан в локальный конфиг (~/.kube/config, блок users)
 * пользователь может просматривать логи подов и их конфигурацию (kubectl logs pod <pod_id>, kubectl describe pod <pod_id>)

```
Проверяем включен ли RBAC. Ищем строку: --authorization-mode=Node,RBAC

kubectl describe pod -n kube-system -l component=kube-apiserver

```
```
root@ubuntu2010:~# kubectl describe pod -n kube-system -l component=kube-apiserver
Name:                 kube-apiserver-ubuntu2010.localdomain
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Node:                 ubuntu2010.localdomain/192.168.186.157
Start Time:           Thu, 09 Jun 2022 11:16:30 +0000
Labels:               component=kube-apiserver
                      tier=control-plane
Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.186.157:8443
                      kubernetes.io/config.hash: 87632580708f0f2ab1df44b2c1457c17
                      kubernetes.io/config.mirror: 87632580708f0f2ab1df44b2c1457c17
                      kubernetes.io/config.seen: 2022-06-01T15:52:37.473561655Z
                      kubernetes.io/config.source: file
                      seccomp.security.alpha.kubernetes.io/pod: runtime/default
Status:               Running
IP:                   192.168.186.157
IPs:
  IP:           192.168.186.157
Controlled By:  Node/ubuntu2010.localdomain
Containers:
  kube-apiserver:
    Container ID:  docker://b32eab8cc9d264b0c72da29657490d0b7bfda6cae7dcdd01d13012cda4cc7f87
    Image:         k8s.gcr.io/kube-apiserver:v1.23.3
    Image ID:      docker-pullable://k8s.gcr.io/kube-apiserver@sha256:b8eba88862bab7d3d7cdddad669ff1ece006baa10d3a3df119683434497a0949
    Port:          <none>
    Host Port:     <none>
    Command:
      kube-apiserver
      --advertise-address=192.168.186.157
      --allow-privileged=true
      --authorization-mode=Node,RBAC
      --client-ca-file=/var/lib/minikube/certs/ca.crt
      --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota
      --enable-bootstrap-token-auth=true

```

```
Создаем пользователя

vagrant@ubuntu2010:/home$  sudo adduser codeman
Adding user `codeman' ...
Adding new group `codeman' (1001) ...
Adding new user `codeman' (1001) with group `codeman' ...
Creating home directory `/home/codeman' ...
Copying files from `/etc/skel' ...
New password:
Retype new password:
passwd: password updated successfully
```

```
Добавлем его в группу sudo и логинимся под ним
sudo usermod -aG sudo newuser

```
```
Создаем заккрытый ключ и запрос CSR

codeman@ubuntu2010:/home$ cd codeman
codeman@ubuntu2010:/home/codeman$ sudo openssl genrsa -out codeman.key 2048
codeman@ubuntu2010:sudo openssl req -new -key codeman.key   -out codeman.csr   -subj "/CN=codeman"

Появилось два файла
codeman@ubuntu2010:/home/codeman$ ls
codeman.csr  codeman.key

```

```
Подписываем сертификат 

sudo openssl x509 -req -in codeman.csr \
  -CA /root/.minikube/ca.crt \
  -CAkey /root/.minikube/ca.key \
  -CAcreateserial \
  -out codeman.crt -days 500

```

```
Создаем каталог для хранения открытого и закрытого ключа пользователя и перемещаем туда файлы
mkdir .certs
mv codeman.crt codeman.key .certs

```
```
Создаем пользователя внутри minikube

kubectl config set-credentials codeman \
  --client-certificate=/home/codeman/.certs/codeman.crt \
  --client-key=/home/codeman/.certs/codeman.key
```
```
codeman@ubuntu2010:/home/codeman$ kubectl config set-credentials codeman \
>   --client-certificate=/home/codeman/.certs/codeman.crt \
>   --client-key=/home/codeman/.certs/codeman.key
User "codeman" set.
```

```
Создаем контекст пользователя
kubectl config set-context codeman-context \
  --cluster=kubernetes --user=codeman
```

```
codeman@ubuntu2010:/home/codeman$ kubectl config set-context codeman-context \
>   --cluster=kubernetes --user=codeman
Context "codeman-context" created.
```

```
Редактируем файл конфигурации ~/.kube/config. Значение для certificate-authority-data берем из /etc/kubernetes/admin.conf

apiVersion: v1
clusters:
- cluster:
   certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCakNDQWU2Z0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwdGFXNXAKYTNWaVpVTkJNQj>
   server: https://192.168.186.157:8443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: codeman
  name: codeman-context
current-context: codeman-context
kind: Config
preferences: {}
users:
- name: codeman
  user:
    client-certificate: /home/codeman/.certs/codeman.crt
    client-key: /home/codeman/.certs/codeman.key


```

```
Пока пользователю не назначено никакой роли, он ничего делать не может. Попробуем посмотреть логи пода:
codeman@ubuntu2010:~$ kubectl logs hello-node-bd6795698-dpxm6
Error from server (Forbidden): pods "hello-node-bd6795698-dpxm6" is forbidden: User "codeman" cannot get resource "pods" in API group "" in the namespace "default"

```

```
Создадим описание роли файл 
codeman@ubuntu2010:~$ nano pod_read.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods" ,"pods/log"]
  verbs: ["get", "watch", "list"]

```
```
Создадим описание привязки роли с пользователем 
codeman@ubuntu2010:~$ nano pod_read_bind.yaml

apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "codeman" to read pods in the "default" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# You can specify more than one "subject"
- kind: User
  name: codeman # "name" is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io

```

```
Применим настройки

codeman@ubuntu2010:~$ sudo kubectl apply -f pod_read.yaml
[sudo] password for codeman: 
Warning: resource roles/pod-reader is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
role.rbac.authorization.k8s.io/pod-reader configured
codeman@ubuntu2010:~$ sudo kubectl apply -f pod_read_bind.yaml
rolebinding.rbac.authorization.k8s.io/read-pods created

```

```
Проверяем:

codeman@ubuntu2010:~$ sudo kubectl get pods
NAME                         READY   STATUS    RESTARTS      AGE
hello-node-bd6795698-dpxm6   1/1     Running   0             19h
hello-node-bd6795698-nc8zb   1/1     Running   2 (38h ago)   4d


codeman@ubuntu2010:~$ kubectl logs hello-node-bd6795698-dpxm6
Получен запрос на URL: /
Получен запрос на URL: /favicon.ico
codeman@ubuntu2010:~$ kubectl logs hello-node-bd6795698-nc8zb
Получен запрос на URL: /
Получен запрос на URL: /
Получен запрос на URL: /favicon.ico
Получен запрос на URL: /
Получен запрос на URL: /
Получен запрос на URL: /favicon.ico
codeman@ubuntu2010:~$ 

codeman@ubuntu2010:~$ kubectl describe pod hello-node-bd6795698-nc8zb
Name:         hello-node-bd6795698-nc8zb
Namespace:    default
Priority:     0
Node:         ubuntu2010.localdomain/192.168.186.157
Start Time:   Mon, 06 Jun 2022 06:35:45 +0000
Labels:       app=hello-node
              pod-template-hash=bd6795698
Annotations:  <none>
Status:       Running
IP:           172.17.0.5
IPs:
  IP:           172.17.0.5
Controlled By:  ReplicaSet/hello-node-bd6795698
Containers:
  hello-node:
    Container ID:   docker://53decc30c2d555707b7f882bc559b681eaf1a8bcc601c0f7c1486949903cf4ef
    Image:          hello-node:v1
    Image ID:       docker://sha256:0667f4e5a187b9b8ec7019b60dc4cc0b03c8dda79cf6e3e34588cea04e8ef1d7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 09 Jun 2022 11:16:46 +0000
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Wed, 08 Jun 2022 16:58:00 +0000
      Finished:     Wed, 08 Jun 2022 17:01:18 +0000
    Ready:          True
    Restart Count:  2
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-grg86 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-grg86:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

```



## Задание 3: Изменение количества реплик 
Поработав с приложением, вы получили запрос на увеличение количества реплик приложения для нагрузки. Необходимо изменить запущенный deployment, увеличив количество реплик до 5. Посмотрите статус запущенных подов после увеличения реплик. 

Требования:
 * в deployment из задания 1 изменено количество реплик на 5
```
codeman@ubuntu2010:~$ sudo kubectl scale --current-replicas=2 --replicas=5 deployment/hello-node
deployment.apps/hello-node scaled

```
 * проверить что все поды перешли в статус running (kubectl get pods)

```
codeman@ubuntu2010:~$ kubectl get pods
NAME                         READY   STATUS    RESTARTS      AGE
hello-node-bd6795698-29vhj   1/1     Running   0             8s
hello-node-bd6795698-6gc6c   1/1     Running   0             8s
hello-node-bd6795698-dpxm6   1/1     Running   0             19h
hello-node-bd6795698-fv8dz   1/1     Running   0             8s
hello-node-bd6795698-nc8zb   1/1     Running   2 (38h ago)   4d

```
---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
