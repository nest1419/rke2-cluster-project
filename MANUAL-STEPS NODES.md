Manual Configuration Steps – RKE2 Cluster

🔧 Configuración Manual de los Nodos
Estos pasos fueron realizados manualmente en las instancias EC2 creadas con Terraform para instalar y unir los nodos al clúster RKE2. El entorno incluye 3 nodos master, 2 nodos worker y 1 nodo balanceador (NGINX).

1️⃣ Balanceador – lb (NGINX)
Sistema Operativo: Ubuntu 24.04 LTS
Instalación automática con Ansible:
ansible-playbook -i inventory.ini nginx-install.yml
Archivo de configuración /etc/nginx/nginx.conf:
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

    server { listen 9443; proxy_pass argocd; }
    server { listen 6443; proxy_pass rke2_api; }
    server { listen 9345; proxy_pass rke2_control; }
    server { listen 9080; proxy_pass nodejs_app; }
    server { listen 9081; proxy_pass nodejs2; }
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name localhost;
        location / {
            return 200 'NGINX TCP Balancer Ready\n';
        }
    }
}

2️⃣ Master 1
Sistema Operativo: Ubuntu 24.04 LTS
Instalación de RKE2 server:
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
Configuración:
mkdir -p /etc/rancher/rke2
nano /etc/rancher/rke2/config.yaml

write-kubeconfig-mode: "0644"
tls-san:
  - 98.84.108.255
token: rke2-cluster-secret-token
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"

Inicio:
systemctl enable rke2-server --now

3️⃣ Master 2 y Master 3
Mismos pasos que Master 1, con esta diferencia en la config:
server: https://<IP_DEL_BALANCER>:6443

Y luego:
systemctl enable rke2-server --now

4️⃣ Worker 1 y Worker 2
Sistema Operativo: Ubuntu 24.04 LTS
Instalación de RKE2 agent:
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -

Configuración:
mkdir -p /etc/rancher/rke2
nano /etc/rancher/rke2/config.yaml

server: https://<IP_DEL_BALANCER>:6443
token: rke2-cluster-secret-token

Inicio:
systemctl enable rke2-agent --now

5️⃣ Validación desde master1
kubectl get nodes

6️⃣ Instalación de Argo CD
Instalación:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Exponer ArgoCD por NodePort (ejemplo):
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

Obtener contraseña:
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

7️⃣ Despliegue de Aplicaciones vía Argo CD
Se crearon dos apps Node.js con 3 réplicas cada una.
Expuestas por NodePort y balanceadas vía NGINX:

http://98.84.108.255:9080 → App 1
http://98.84.108.255:9081 → App 2

