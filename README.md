
# RKE2 Kubernetes Cluster en AWS con Terraform, Ansible y Argo CD

Este proyecto despliega un clúster de Kubernetes basado en **RKE2 (Rancher Kubernetes Engine 2)** en **AWS**, utilizando **Terraform** para la infraestructura, **Ansible** para configurar el balanceador NGINX, y **Argo CD** como gestor GitOps para desplegar aplicaciones Node.js.

---

## 🧱 Arquitectura

- **3 Nodos Master** (RKE2 control-plane)
- **2 Nodos Worker**
- **1 Nodo Balanceador (lb)** con **NGINX Open Source** (modo stream TCP)
- **1 VPC personalizada** con:
  - Subnet pública (para acceso SSH, lb, etc.)
  - Subnet privada (comunicación interna)
- **Security Groups configurados**
  - Acceso SSH (puerto 22)
  - API RKE2 (puerto 6443)
  - Canal de control RKE2 (puerto 9345)
  - NodePorts de apps y ArgoCD
  - Puertos balanceados: `9080`, `9081`, `9443`

---

## 🛠️ Herramientas usadas

- **Terraform**: Infraestructura en AWS (EC2, VPC, SG, subnets)
- **Ansible**: Instalación y configuración de NGINX
- **NGINX Open Source**: Balanceo TCP para RKE2 y aplicaciones
- **RKE2**: Instalado manualmente en cada nodo
- **Argo CD**: Instalado vía manifest y accesible públicamente
- **Node.js**: Dos aplicaciones desplegadas usando GitOps

---

## 📁 Estructura del repositorio

```
infra/aws/rke2-cluster/
├── terraform/                # Código Terraform (VPC, EC2, SG, etc.)
│   └── modules/
│       ├── ec2/
│       └── vpc/
├── ansible/
│   ├── inventory.ini         # Inventario para Ansible (lb)
│   ├── nginx-install.yml     # Playbook para instalar NGINX
│   └── files/nginx.conf      # Configuración completa de NGINX
├── scripts/
│   └── rke2-install.sh       # Script base de instalación para RKE2
├── README.md
└── MANUAL-STEPS NODES.md     # Pasos manuales para unir masters y workers
```

---

## 🚀 Despliegue de aplicaciones con Argo CD

Se crearon dos apps simples con Node.js:

- **App 1:** `http://<IP_LB>:9080`
- **App 2:** `http://<IP_LB>:9081`

El manifiesto declarativo de Argo CD (`Application`) para cada app está versionado en el mismo repositorio.

---

## 🔑 Acceso a Argo CD

- URL: `https://<IP_LB>:9443`
- Usuario: `admin`
- Contraseña: Obtenida desde el secret en el namespace `argocd`:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📝 Notas adicionales

- El clúster fue construido con enfoque de producción simulado.
- No se usó Ingress Controller HTTP; el balanceo se realiza con NGINX modo TCP (stream).
- Toda la infraestructura es compatible con el AWS Free Tier.

---

## 📌 Requisitos previos

- Cuenta en AWS
- Docker + Git + Terraform + Ansible instalados
- VSCode con WSL (Ubuntu) o sistema Linux
- Docker Hub para subir imágenes Node.js

---

## 📤 Autor

**José Rogelio Martínez**  
Cloud & Infrastructure Architect
