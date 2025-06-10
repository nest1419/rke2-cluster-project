# Manual Configuration Steps – RKE2 Cluster

This document outlines the manual steps taken to configure master and worker nodes, the NGINX load balancer, and Argo CD.

## 🔹 Master Nodes

### Prerequisites (on each master)
```bash
sudo hostnamectl set-hostname masterX
sudo apt update && sudo apt upgrade -y
```

### Install RKE2 Server (master1)
```bash
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="server" sh -
sudo mkdir -p /etc/rancher/rke2

# config.yaml
token: <SHARED_TOKEN>
tls-san:
  - <PUBLIC_LB_IP>

sudo systemctl enable rke2-server
sudo systemctl start rke2-server
```

### Retrieve token (master1)
```bash
sudo cat /var/lib/rancher/rke2/server/node-token
```

### Setup master2 & master3
Same as master1, but with `server: https://<PRIVATE_LB_IP>:9345` in config.yaml

## 🔹 Worker Nodes

### Preparation & Installation
```bash
sudo hostnamectl set-hostname workerX
sudo apt update && sudo apt upgrade -y
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -

# config.yaml
server: https://<PRIVATE_LB_IP>:9345
token: <TOKEN_FROM_MASTER1>

sudo systemctl enable rke2-agent
sudo systemctl start rke2-agent
```

## 🔹 NGINX Load Balancer

Installed using Ansible playbook:
```bash
ansible-playbook -i inventory.ini nginx-install.yml
```

## 🔹 Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Web access via: `https://<LB_IP>:9443`

## 🔹 Argo CD Applications

Declared via Git:
- `apps/nodejs-app.yaml`
- `apps/nodejs-app2.yaml`

## ✅ Final Test
```bash
curl http://localhost:9080
curl http://localhost:9081
```

Both should return Node.js welcome messages.