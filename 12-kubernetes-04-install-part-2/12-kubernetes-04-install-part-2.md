# Домашнее задание к занятию "12.4 Развертывание кластера на собственных серверах, лекция 2"
Новые проекты пошли стабильным потоком. Каждый проект требует себе несколько кластеров: под тесты и продуктив. Делать все руками — не вариант, поэтому стоит автоматизировать подготовку новых кластеров.

## Задание 1: Подготовить инвентарь kubespray
Новые тестовые кластеры требуют типичных простых настроек. Нужно подготовить инвентарь и проверить его работу. Требования к инвентарю:
* подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды;
* в качестве CRI — containerd;
* запуск etcd производить на мастере.


```
devuser@devuser-virtual-machine:~/home_works/12-kubernetes-04-install-part-2/kubespray/12_kubespray_1/kubespray$ ansible --version
ansible [core 2.12.5]
  config file = /home/devuser/home_works/12-kubernetes-04-install-part-2/kubespray/12_kubespray_1/kubespray/ansible.cfg
  configured module search path = ['/home/devuser/home_works/12-kubernetes-04-install-part-2/kubespray/12_kubespray_1/kubespray/library']
  ansible python module location = /home/devuser/.local/lib/python3.8/site-packages/ansible
  ansible collection location = /home/devuser/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/devuser/.local/bin/ansible
  python version = 3.8.10 (default, Mar 15 2022, 12:22:08) [GCC 9.4.0]
  jinja version = 2.11.3
  libyaml = True
```

```
git clone https://github.com/kubernetes-sigs/kubespray
# Установка зависимостей
sudo pip3 install -r requirements.txt

# Копирование примера в папку с вашей конфигурацией
cp -rfp inventory/sample inventory/mycluster
```

```
Создаем машины
devuser@devuser-virtual-machine:~/home_works/12-3-install-kub-1$ . list-vms.sh 
+----------------------+-------+---------------+---------+---------------+-------------+
|          ID          | NAME  |    ZONE ID    | STATUS  |  EXTERNAL IP  | INTERNAL IP |
+----------------------+-------+---------------+---------+---------------+-------------+
| fhm8gsa03s6lf8ahq964 | node1 | ru-central1-a | RUNNING | 51.250.91.66  | 10.128.0.27 |
| fhmpaaddh9ugv58qjvef | cp1   | ru-central1-a | RUNNING | 51.250.80.230 | 10.128.0.22 |
+----------------------+-------+---------------+---------+---------------+-------------+

Генерим файл настроек хостов

declare -a IPS=(51.250.80.230 51.250.91.66)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

```

```
Вносим изменения в полученный файл
all:
  hosts:
    cp1:
      ansible_host: 51.250.80.230
      ansible_user: yc-user
    node1:
      ansible_host: 51.250.91.66
      ansible_user: yc-user
  children:
    kube_control_plane:
      hosts:
        cp1:
    kube_node:
      hosts:
        node1:
    etcd:
      hosts:
        cp1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}

```


```
Для доступа извне прописываем в k8s-cluster.yml

supplementary_addresses_in_ssl_keys: [51.250.80.230]
```

```
Запускаем плейбук

ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v
```

```
После установки заходим на мастер ноду кластера делам доступ не из под root

devuser@devuser-virtual-machine:~/home_works/12-3-install-kub-1$ ssh yc-user@51.250.80.230
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wed Jun 15 16:23:58 2022 from 90.151.87.170

yc-user@cp1:~$ {
>     mkdir -p $HOME/.kube
>     sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
>     sudo chown $(id -u):$(id -g) $HOME/.kube/config
> }

```

```
Проверяем 

yc-user@cp1:~$ kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
cp1     Ready    control-plane   35m   v1.24.1
node1   Ready    <none>          34m   v1.24.1

```

```
Забираем креды из конфига мастер ноды чтобы прописать их на локальной машине (certificate-authority-data, user )

yc-user@cp1:~$ sudo cat /etc/kubernetes/admin.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <key data>
    server: https://127.0.0.1:6443
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubernetes-admin
  name: kubernetes-admin@cluster.local
current-context: kubernetes-admin@cluster.local
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <key data>
    client-key-data: <key data>
```


```
devuser@devuser-virtual-machine:~/home_works/12-3-install-kub-1$ cat ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <key>
    server: https://51.250.91.122:6443
  name: netology
- cluster:
    certificate-authority-data: <key>
    server: https://51.250.80.230:6443
  name: netology2
contexts:
- context:
    cluster: netology
    namespace: kube-system
    user: netology-user
  name: netology
- context:
    cluster: netology2
    namespace: kube-system
    user: netology-user1
  name: netology2
current-context: netology2
kind: Config
preferences: {}
users:
- name: netology-user
  user:
    client-certificate-data: <key>
    client-key-data: <key>
- name: netology-user1
  user:
    client-certificate-data: <key>
    client-key-data: <key>
```

```
Проверяем доступ с локальной машины
devuser@devuser-virtual-machine:~/home_works/12-3-install-kub-1$ kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
cp1     Ready    control-plane   42m   v1.24.1
node1   Ready    <none>          40m   v1.24.1
```

## Задание 2 (*): подготовить и проверить инвентарь для кластера в AWS
Часть новых проектов хотят запускать на мощностях AWS. Требования похожи:
* разворачивать 5 нод: 1 мастер и 4 рабочие ноды;
* работать должны на минимально допустимых EC2 — t3.small.

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
