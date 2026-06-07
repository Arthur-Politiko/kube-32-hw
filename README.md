# Домашнее задание к занятию «Установка Kubernetes»

## Цель задания

Установить кластер K8s.

### Чеклист готовности к домашнему заданию

1. Развёрнутые ВМ с ОС Ubuntu 20.04-lts.


### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Инструкция по установке kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).
2. [Документация kubespray](https://kubespray.io/).
3. [Документация Terraform Yandex Provider](https://terraform-provider.yandexcloud.net/).
4. [Документация Ansible](https://docs.ansible.com/).

-----\n

### Задание 1. Установить кластер k8s с 1 master node

1. Подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды.
2. В качестве CRI — containerd.
3. Запуск etcd производить на мастере.
4. Способ установки выбрать самостоятельно.

------
### Задание 2*. Установить HA кластер

1. Установить кластер в режиме HA.
2. Использовать нечётное количество Master-node.
3. Для cluster ip использовать keepalived или другой способ.


## Решение

Установка кластера k8s
Установка cli от облачного провайдера:
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
Затем прикручиваем yc к нашему аккаунту провайдера, выбираем облако, рабочий каталог и зону по умолчанию:
```bash
yc init --username=<email_address>
# yc config set cloud-id <cloud-id>
# yc config set folder-id <folder-id>
# yc config set zone <zone>
```
Для проверки вызовем команду:
```bash
yc config get cloud-id
yc config get folder-id
yc config get zone
```
Далее нам нужен ключ для работы tf от УЗ sa.
[Здесь](https://yandex.cloud/ru/docs/cli/operations/authentication/service-account) описано как это сделать.

Последовательность такая:
Получим список sa из текущего каталога:
```bash
yc iam service-account list
# или указав нужный folder-id
yc iam service-account --folder-id $(yc config get folder-id)  list
```
Генерируем новый ключ для sa:
```bash
yc iam key create \
  --service-account-name <service-account-name> \
  --output <key-file> \
  --folder-id <folder-id>
```

Инициализируем проект:
```bash
terraform init
```
Проверяем синтаксис:
```bash
terraform validate
```
Ну и последний шаг - применяем конфигурацию:
```bash
terraform apply
```
Пересоздать отдельный ресурс terraform
```bash
terraform apply -replace='yandex_compute_instance.vms["k8s-master"]' --auto-approve
```

## Использование Ansible для установки Kubernetes

В качестве способа установки Kubernetes выбран Ansible. Это позволяет гибко управлять процессом установки, обеспечивает идемпотентность и упрощает отладку.

### Структура Ansible проекта

```
ansible/
├── ansible.cfg        # Конфигурация Ansible
├── bootstrap.yml      # Установка Python 3.9 (только для master)
├── inventory.ini      # Генерируется Terraform
├── main.yaml          # Установка Kubernetes + containerd на master
├── worker.yaml        # Установка Kubernetes + containerd на workers
├── kubeadm-init.yaml  # Инициализация кластера на master
├── kubeadm-join.yaml  # Присоединение workers к кластеру
└── install-k8s.yaml   # Головной playbook (оркестрация всех этапов)
```

### Подготовка инфраструктуры

1. Установите Yandex Cloud CLI и настройте доступ:
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init --username=<email_address>
yc config set cloud-id <cloud-id>
yc config set folder-id <folder-id>
yc config set zone <zone>
```

2. Создайте сервисный аккаунт и ключ:
```bash
yc iam service-account list
yc iam key create \
  --service-account-name <service-account-name> \
  --output ../vault/cloud-sa-key.json \
  --folder-id $(yc config get folder-id)
```

3. Сгенерируйте SSH-ключи:
```bash
ssh-keygen -t ed25519 -f ../vault/id_ed25519
```

4. Примените Terraform конфигурацию:
```bash
cd tf
terraform init
terraform apply -auto-approve
```

### Установка Kubernetes через Ansible

После создания VM запустите установку Kubernetes:

```bash
cd ansible
ansible-playbook install-k8s.yaml
```

Плейбук выполнит следующие этапы:

1. **bootstrap.yml** — установка Python 3.9 на master (необходим для Ansible)
2. **main.yaml** — установка Kubernetes (containerd, kubelet, kubeadm, kubectl) на master:
   - Обновление пакетов
   - Отключение swap
   - Настройка ядра (modprobe overlay, br_netfilter)
   - Настройка sysctl параметров
   - Установка containerd с настройкой SystemdCgroup=true
   - Установка kubelet, kubeadm, kubectl
3. **worker.yaml** — установка Kubernetes на worker-ноды
4. **kubeadm-init.yaml** — инициализация кластера:
   - `kubeadm init` с параметрами:
     - Kubernetes 1.32.0
     - Pod CIDR: 10.244.0.0/16
     - Service CIDR: 10.96.0.0/12
   - Настройка kubeconfig для пользователя ubuntu
   - Установка Flannel CNI-плагина
   - Ожидание готовности master-ноды
5. **kubeadm-join.yaml** — присоединение worker-нод к кластеру



Запуск kubeadm init
   - Создание сертификатов CA
   - Создание сертификатов etcd (или external etcd)
   - Генерация kubeconfig файлов для компонентов
   - Запуск control plane компонентов как static pods:
     * kube-apiserver
     * kube-controller-manager
     * kube-scheduler
     * etcd (если не external)
   - Создание bootstrap токена   

Настройка kubectl
   - mkdir -p $HOME/.kube
   - cp /etc/kubernetes/admin.conf $HOME/.kube/config
   - Настройка для пользователя ubuntu (опционально)



Только на master ноде:

Установка сетевого плагина
   - Flannel: kubectl apply -f kube-flannel.yml
   - Calico: kubectl apply -f calico.yaml
   - Weave, Cilium, и т.д.

Ожидание готовности core pods
    - kube-system namespace pods должны запуститься
    - CNI должен инициализироваться (может занять 1-2 минуты)


Присоединение worker нод
На master ноде:
Генерация join token
    - kubeadm token create --print-join-command
    - Сохранить команду для воркеров    

На каждой worker ноде:
Выполнение join команды
    - kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
    - Безопасное получение CA cert hash


### Проверка и верификация
На master ноде:

После завершения установки проверьте статус кластера:

```bash
# Подключитесь к мастер-ноде
ssh ubuntu@<master-ip> -i ../vault/id_ed25519

# Проверьте узлы
kubectl get nodes

# Проверьте поды в системных неймспейсах
kubectl get pods -A
```

Пример вывода:
```
NAME             STATUS   ROLES           AGE   VERSION
k8s-master       Ready    control-plane   5m    v1.32.0
k8s-worker-01    Ready    <none>          3m    v1.32.0
k8s-worker-02    Ready    <none>          3m    v1.32.0
k8s-worker-03    Ready    <none>          3m    v1.32.0
k8s-worker-04    Ready    <none>          3m    v1.32.0
k8s-worker-05    Ready    <none>          3m    v1.32.0
```

### Структура проекта

```
kube-32-hw/
├── ansible/           # Ansible конфигурация
│   ├── ansible.cfg
│   ├── bootstrap.yml
│   ├── inventory.ini
│   ├── main.yaml
│   ├── worker.yaml
│   ├── kubeadm-init.yaml
│   ├── kubeadm-join.yaml
│   └── install-k8s.yaml
├── tf/                # Terraform конфигурация
│   ├── 00-providers.tf
│   ├── 01-variables.tf
│   ├── 02-network.tf
│   ├── 10-instance.tf
│   ├── 90-output.tf
│   ├── deploy/        # Cloud-init скрипты
│   └── templates/     # Шаблоны
└── vault/             # Конфиденциальные данные
    ├── cloud-sa-key.json
    ├── id_ed25519
    └── id_ed25519.pub
```
