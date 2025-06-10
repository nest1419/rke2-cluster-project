# RKE2 Kubernetes Cluster on AWS using Terraform, Ansible, and Argo CD

This project deploys a Kubernetes cluster based on **RKE2 (Rancher Kubernetes Engine 2)** on **AWS**, using **Terraform** for infrastructure provisioning, **Ansible** for NGINX load balancer configuration, and **Argo CD** as a GitOps tool to deploy Node.js applications.

## 🧱 Architecture

- **3 Master Nodes** (RKE2 control-plane)
- **2 Worker Nodes**
- **1 Load Balancer Node (lb)** with **NGINX Open Source** (stream TCP mode)
- **1 Custom VPC** with:
  - Public subnet (for SSH access, lb, etc.)
  - Private subnet (internal communication)
- **Configured Security Groups** including:
  - SSH Access (port 22)
  - RKE2 API (port 6443)
  - RKE2 Control Plane (port 9345)
  - NodePorts for apps and ArgoCD
  - Load Balanced Ports: `9080`, `9081`, `9443`

## 🛠️ Tools Used

- **Terraform**: AWS infrastructure (EC2, VPC, SG, subnets)
- **Ansible**: NGINX installation and configuration
- **NGINX Open Source**: TCP load balancing for RKE2 and services
- **RKE2**: Installed manually on each node
- **Argo CD**: Installed via manifest and publicly accessible
- **Node.js**: Two apps deployed using GitOps

## 📁 Repository Structure

```
infra/aws/rke2-cluster/
├── terraform/
│   └── modules/
│       ├── ec2/
│       └── vpc/
├── ansible/
│   ├── inventory.ini
│   ├── nginx-install.yml
│   └── files/nginx.conf
├── scripts/
│   └── rke2-install.sh
├── README.md
└── MANUAL-STEPS NODES.md
```

## 🚀 Application Deployment via Argo CD

Two simple Node.js apps were deployed:
- **App 1:** `http://<LB_IP>:9080`
- **App 2:** `http://<LB_IP>:9081`

## 🔑 Argo CD Access

- URL: `https://<LB_IP>:9443`
- User: `admin`
- Password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 📝 Notes

- No Ingress controller used; TCP load balancing via NGINX.
- All resources compatible with AWS Free Tier.

## 📌 Requirements

- AWS Account
- Docker + Git + Terraform + Ansible
- VSCode with WSL or Linux
- Docker Hub account

## 📤 Author

**José Rogelio Martínez**  
Cloud & Infrastructure Architect