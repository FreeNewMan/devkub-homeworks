# Домашнее задание к занятию "12.5 Сетевые решения CNI"
После работы с Flannel появилась необходимость обеспечить безопасность для приложения. Для этого лучше всего подойдет Calico.
## Задание 1: установить в кластер CNI плагин Calico
Для проверки других сетевых решений стоит поставить отличный от Flannel плагин — например, Calico. Требования: 
* установка производится через ansible/kubespray;
* после применения следует настроить политику доступа к hello-world извне. Инструкции [kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/network-policies/), [Calico](https://docs.projectcalico.org/about/about-network-policy)

```
Задача: 
1. Нужно чтобы front видел back
2. Back видит Cache
3. Back не должен видеть Front
4. Cache не должен видеть Front
```

```
Подготовим docker образ приложения, который будет запущен в виде 3 подов в качестве frontend, backend, cache

```
```
Файл server js:

var http = require('http');

var os = require("os");
var hostname = os.hostname();

var handleRequest = function(request, response) {
  console.log('Получен запрос на URL: ' + request.url);
  response.writeHead(200);
  response.end('Hello World! I am '+hostname+'\r\n');
};
var www = http.createServer(handleRequest);
www.listen(8080);

```

```
Dockerfile

FROM node:6.14.2
EXPOSE 8080
COPY server.js .
CMD [ "node", "server.js" ]

```

```
Соберем образ и отправим в репозиторий

docker build -t lutovp/hello-node

devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ docker build -t lutovp/hello-node:v1.0.1 .
Sending build context to Docker daemon  3.072kB
Step 1/4 : FROM node:6.14.2
 ---> 00165cd5d0c0
Step 2/4 : EXPOSE 8080
 ---> Using cache
 ---> c88c87b96fe5
Step 3/4 : COPY server.js .
 ---> b86d45f032f8
Step 4/4 : CMD [ "node", "server.js" ]
 ---> Running in 09a4ae54559d
Removing intermediate container 09a4ae54559d
 ---> d827f4d5801b
Successfully built d827f4d5801b
Successfully tagged lutovp/hello-node:v1.0.1
```

```
Отправим во внешний репозиторий

docker push lutovp/hello-node:v1.0.1
The push refers to repository [docker.io/lutovp/hello-node]
d3e8a823ce93: Pushed 
aeaa1edefd60: Layer already exists 
6e650662f0e3: Layer already exists 
8c825a971eaf: Layer already exists 
bf769027dbbd: Layer already exists 
f3693db46abb: Layer already exists 
bb6d734b467e: Layer already exists 
5f349fdc9028: Layer already exists 
2c833f307fd8: Layer already exists 
v1.0.1: digest: sha256:96990944aea387c4e5f33388a8cd9b729e23a2fb66d0570a8b7d95b3f77b3a20 size: 2214

```


```
Создадим 3 деплоймента и поднимем поды:
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl create deployment hello-node-front --image=lutovp/hello-node:v1.0.1
deployment.apps/hello-node-front created
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl create deployment hello-node-back --image=lutovp/hello-node:v1.0.1
deployment.apps/hello-node-back created
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl create deployment hello-node-cache --image=lutovp/hello-node:v1.0.1
deployment.apps/hello-node-cache created


devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl expose deployment hello-node-front --type=LoadBalancer --port=8080
service/hello-node-front exposed
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl expose deployment hello-node-back --type=LoadBalancer --port=8080
service/hello-node-back exposed
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl expose deployment hello-node-cache --type=LoadBalancer --port=8080
service/hello-node-cache exposed
de
```

```
Смотрим что поды появились

devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl get pods 
NAME                                READY   STATUS    RESTARTS   AGE
hello-node-back-7b8bfc4d9b-pl68w    1/1     Running   0          22s
hello-node-cache-6c94dc75cf-kr8vh   1/1     Running   0          10s
hello-node-front-544b9f98d8-hmd2v   1/1     Running   0          54s


```

```
Пока никаких политик не настроено проверяем что поды видят друг друга:

1. Проверяем
kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-back:8080


devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-front:8080
Hello World! I am hello-node-front-544b9f98d8-hmd2v
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-cache:8080
Hello World! I am hello-node-cache-6c94dc75cf-kr8vh
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-back:8080
Hello World! I am hello-node-back-7b8bfc4d9b-pl68w


kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-back:8080

devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-front:8080
Hello World! I am hello-node-front-544b9f98d8-hmd2v
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-cache:8080
Hello World! I am hello-node-cache-6c94dc75cf-kr8vh
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-back:8080
Hello World! I am hello-node-back-7b8bfc4d9b-pl68w

kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-back:8080

devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-front:8080
Hello World! I am hello-node-front-544b9f98d8-hmd2v
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-cache:8080
Hello World! I am hello-node-cache-6c94dc75cf-kr8vh
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-back:8080
Hello World! I am hello-node-back-7b8bfc4d9b-pl68w
```

``` 
Настроим политики
1. 00-default.yaml
Запрещаем все входящие запросы ()


apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress

```

```
2. Разрешаем все входящие на front 10-frontend.yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: hello-node-front
  policyTypes:
    - Ingress

```

```
3. Разрешаем все входящие на back от front по порту 8080 
20-backend.yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: hello-node-back
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: hello-node-front
      ports:
        - protocol: TCP
          port: 8080          

```
```
4. Разрешаем все входящие на cache от back по порту 8080, и заперащаем все исходящие (Egress) из cache
30-cache.yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cache
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: hello-node-cache
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: hello-node-back
      ports:
        - protocol: TCP
          port: 8080
```

```
Применим политики:
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl apply -f manifests/network-policy
networkpolicy.networking.k8s.io/default-deny-ingress created
networkpolicy.networking.k8s.io/frontend created
networkpolicy.networking.k8s.io/backend created
networkpolicy.networking.k8s.io/cache created
```

```
Проверяем трафик из back:

kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-back:8080


devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-front:8080
command terminated with exit code 28
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-cache:8080
Hello World! I am hello-node-cache-6c94dc75cf-kr8vh
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-back-7b8bfc4d9b-pl68w -- curl -s -m 5 hello-node-back:8080
command terminated with exit code 28

back to front доступа нет

back to cache доступа есть

back to back доступа нет


```

```
Проверяем трафик из front:

kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-back:8080



devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-front:8080
command terminated with exit code 28
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-cache:8080
command terminated with exit code 28
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-front-544b9f98d8-hmd2v -- curl -s -m 5 hello-node-back:8080
Hello World! I am hello-node-back-7b8bfc4d9b-pl68w

front to front доступа нет

front to cache доступа нет

front to back доступа есть

```
```
Проверяем трафик из cache:

kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-front:8080
kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-cache:8080
kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-back:8080

devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-front:8080
command terminated with exit code 28
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-cache:8080
command terminated with exit code 28
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-05-cni$ kubectl exec hello-node-cache-6c94dc75cf-kr8vh  -- curl -s -m 5 hello-node-back:8080
command terminated with exit code 28

Из cache доступа никуда нет
```

## Задание 2: изучить, что запущено по умолчанию
Самый простой способ — проверить командой calicoctl get <type>. Для проверки стоит получить список нод, ipPool и profile.
Требования: 
* установить утилиту calicoctl;
* получить 3 вышеописанных типа в консоли.

```
Установка Calicoctl

1. Переходим в каталог /usr/local/bin/

2. Скачиваем бинарник
curl -L https://github.com/projectcalico/calico/releases/download/v3.23.1/calicoctl-linux-amd64 -o calicoctl

3. Даем права на запуск
chmod +x ./calicoctl

```

```
Список нод
evuser@devuser-virtual-machine:/usr/local/bin$ kubectl-calico get nodes
NAME    
cp1     
node1 
```

```
devuser@devuser-virtual-machine:/usr/local/bin$ kubectl-calico get ipPool
NAME           CIDR             SELECTOR   
default-pool   10.233.64.0/18   all()      

```

```
devuser@devuser-virtual-machine:/usr/local/bin$ kubectl-calico get profile
NAME                                                 
projectcalico-default-allow                          
kns.default                                          
kns.kube-node-lease                                  
kns.kube-public                                      
kns.kube-system                                      
ksa.default.default                                  
ksa.kube-node-lease.default                          
ksa.kube-public.default                              
ksa.kube-system.attachdetach-controller              
ksa.kube-system.bootstrap-signer                     
ksa.kube-system.calico-node                          
ksa.kube-system.certificate-controller               
ksa.kube-system.clusterrole-aggregation-controller   
ksa.kube-system.coredns                              
ksa.kube-system.cronjob-controller                   
ksa.kube-system.daemon-set-controller                
ksa.kube-system.default                              
ksa.kube-system.deployment-controller                
ksa.kube-system.disruption-controller                
ksa.kube-system.dns-autoscaler                       
ksa.kube-system.endpoint-controller                  
ksa.kube-system.endpointslice-controller             
ksa.kube-system.endpointslicemirroring-controller    
ksa.kube-system.ephemeral-volume-controller          
ksa.kube-system.expand-controller                    
ksa.kube-system.generic-garbage-collector            
ksa.kube-system.horizontal-pod-autoscaler            
ksa.kube-system.job-controller                       
ksa.kube-system.kube-proxy                           
ksa.kube-system.namespace-controller                 
ksa.kube-system.node-controller                      
ksa.kube-system.nodelocaldns                         
ksa.kube-system.persistent-volume-binder             
ksa.kube-system.pod-garbage-collector                
ksa.kube-system.pv-protection-controller             
ksa.kube-system.pvc-protection-controller            
ksa.kube-system.replicaset-controller                
ksa.kube-system.replication-controller               
ksa.kube-system.resourcequota-controller             
ksa.kube-system.root-ca-cert-publisher               
ksa.kube-system.service-account-controller           
ksa.kube-system.service-controller                   
ksa.kube-system.statefulset-controller               
ksa.kube-system.token-cleaner                        
ksa.kube-system.ttl-after-finished-controller        
ksa.kube-system.ttl-controller
```
### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
