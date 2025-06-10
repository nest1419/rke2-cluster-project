# Manual Configuration Steps – RKE2 Cluster

Este documento describe los pasos manuales que se realizaron para configurar los nodos master, worker, el balanceador con NGINX y la instalación de Argo CD.

---

## 🔹 Nodos Master

### Requisitos previos (en cada master)
```bash
sudo hostnamectl set-hostname masterX      # X = 1, 2, 3
sudo apt update && sudo apt upgrade -y
```

### Instalación de RKE2 Server (en master1)
```bash
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="server" sh -
sudo mkdir -p /etc/rancher/rke2

# Archivo de configuración /etc/rancher/rke2/config.yaml
token: <TOKEN_COMPARTIDO>
tls-san:
  - <IP_PÚBLICA_LB>
```

```bash
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
```

### Obtener el token (en master1)
```bash
sudo cat /var/lib/rancher/rke2/server/node-token
```

### master2 y master3
```bash
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="server" sh -
sudo mkdir -p /etc/rancher/rke2

# Archivo /etc/rancher/rke2/config.yaml
server: https://<IP_PRIVADA_LB>:9345
token: <TOKEN_DEL_MASTER1>
tls-san:
  - <IP_PÚBLICA_LB>
```

```bash
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
```

---

## 🔹 Nodos Worker

### Preparación
```bash
sudo hostnamectl set-hostname workerX
sudo apt update && sudo apt upgrade -y
```

### Instalación de RKE2 Agent
```bash
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -
sudo mkdir -p /etc/rancher/rke2

# Archivo /etc/rancher/rke2/config.yaml
server: https://<IP_PRIVADA_LB>:9345
token: <TOKEN_DEL_MASTER1>
```

```bash
sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service
```

---

## 🔹 Balanceador NGINX

### Instalación con Ansible
Playbook `nginx-install.yml` automatiza la instalación desde Ubuntu:
```bash
ansible-playbook -i inventory.ini nginx-install.yml
```

### Archivo `/etc/nginx/nginx.conf`
```nginx
worker_processes auto;
events {
    worker_connections 1024;
}

stream {
    upstream rke2_api {
        server 10.0.1.94:6443;
        server 10.0.1.99:6443;
        server 10.0.1.226:6443;
    }

    upstream rke2_control {
        server 10.0.1.94:9345;
        server 10.0.1.99:9345;
        server 10.0.1.226:9345;
    }

    upstream argocd {
        server 10.0.1.39:30649;
    }

    upstream nodejs_app {
        server 10.0.1.209:30080;
        server 10.0.1.39:30080;
    }

    upstream nodejs2 {
        server 10.0.1.209:30081;
        server 10.0.1.39:30081;
    }

    server {
        listen 6443;
        proxy_pass rke2_api;
    }

    server {
        listen 9345;
        proxy_pass rke2_control;
    }

    server {
        listen 9443;
        proxy_pass argocd;
    }

    server {
        listen 9080;
        proxy_pass nodejs_app;
    }

    server {
        listen 9081;
        proxy_pass nodejs2;
    }
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 80;
        server_name localhost;
        location / {
            return 200 'NGINX TCP Balancer Ready\n';
        }
    }
}
```

---

## 🔹 Argo CD

### Instalación
```bash
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Obtener contraseña inicial
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### Acceso por Web
- Puerto en NGINX: `9443`
- URL: `https://<IP_PÚBLICA_LB>:9443`

---

## 🔹 Despliegue de Aplicaciones con Argo CD

### nodejs-app
```yaml
# apps/nodejs-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    path: app
    repoURL: https://github.com/nest1419/rke2.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### nodejs-app2
```yaml
# apps/nodejs-app2.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app2
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    path: app2
    repoURL: https://github.com/nest1419/rke2.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## ✅ Verificaciones finales

```bash
curl http://localhost:9080  # App 1
curl http://localhost:9081  # App 2
```

Ambos deben devolver su respectivo mensaje de bienvenida en Node.js.

---

**Fin del documento**