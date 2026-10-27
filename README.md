<div align="center">

# 🕸️ Azure Enterprise Hub-and-Spoke Infrastructure
### Production-Grade Network Topology & CAF Segmentation via Terraform

[![Platform](https://img.shields.io/badge/Platform-Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![IaC](https://img.shields.io/badge/IaC-Terraform_Modular-7B2CBF?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![Security Gate](https://img.shields.io/badge/Security_Gate-Checkov_CIS_Passed-00FF66?style=for-the-badge&logo=bridgecrew&logoColor=0B0813)](https://www.checkov.io)
[![State Isolation](https://img.shields.io/badge/State-Decoupled_Multi--State-00E5FF?style=for-the-badge&logo=azureartifacts&logoColor=0B0813)](#-state-isolation-strategy)

**Designed by [Mihir Maurya](https://github.com/MihirMaurya-dev) · Enterprise Cloud Architect & DevSecOps**

</div>

---

## 🏗️ Architectural Topology

This repository delivers an enterprise-grade **Hub-and-Spoke Network Architecture** aligned with the **Microsoft Cloud Adoption Framework (CAF)**. It isolates shared connectivity and security appliances inside a centralized Hub VNet, while segmenting application workloads into dedicated Spokes (`Dev` and `Prod`) connected via low-latency Virtual Network Peering.

```mermaid
flowchart TD
    subgraph Hub["🏢 Central Connectivity Hub (vnet-hub: 10.0.0.0/16)"]
        H_FW["🔥 Azure Firewall Subnet\n(10.0.0.0/26)"]
        H_AGW["🌐 App Gateway Subnet\n(10.0.1.0/27)"]
        H_BST["🛡️ Azure Bastion Subnet\n(10.0.2.0/27)"]
        H_GW["⚡ VPN Gateway Subnet\n(10.0.3.0/27)"]
        H_MGMT["🖥️ Management Subnet\n(10.0.4.0/24)"]
        H_KV["🔑 Shared Key Vault\n(Private Endpoint)"]
    end

    subgraph SpokeDev["🧪 Spoke Dev (vnet-spoke-dev: 10.1.0.0/16)"]
        DEV_WEB["🌐 Web Tier (10.1.1.0/24)"]
        DEV_APP["⚙️ App Tier (10.1.2.0/24)"]
        DEV_DB["🗄️ Database Tier (10.1.3.0/24)"]
    end

    subgraph SpokeProd["🚀 Spoke Prod (vnet-spoke-prod: 10.2.0.0/16)"]
        PROD_WEB["🌐 Web Tier (10.2.1.0/24)"]
        PROD_APP["⚙️ App Tier (10.2.2.0/24)"]
        PROD_DB["🗄️ Database Tier (10.2.3.0/24)"]
    end

    Hub <===>|"Bidirectional VNet Peering"| SpokeDev
    Hub <===>|"Bidirectional VNet Peering"| SpokeProd

    classDef hubStyle fill:#1d0738,stroke:#9d4edd,stroke-width:2px,color:#fff;
    classDef devStyle fill:#051b2e,stroke:#00e5ff,stroke-width:2px,color:#fff;
    classDef prodStyle fill:#032111,stroke:#00ff66,stroke-width:2px,color:#fff;

    class Hub,H_FW,H_AGW,H_BST,H_GW,H_MGMT,H_KV hubStyle;
    class SpokeDev,DEV_WEB,DEV_APP,DEV_DB devStyle;
    class SpokeProd,PROD_WEB,PROD_APP,PROD_DB prodStyle;
```

---

## 📊 IP Addressing & CIDR Allocation Plan

| Network Zone | Resource | CIDR Block | Usable IPs | Purpose / Security Role |
|---|---|---|:---:|---|
| **Hub VNet** | `AzureFirewallSubnet` | `10.0.0.0/26` | 59 | Central egress/ingress TLS inspection |
| **Hub VNet** | `ApplicationGatewaySubnet` | `10.0.1.0/27` | 27 | Layer 7 reverse proxy & WAF v2 |
| **Hub VNet** | `BastionSubnet` | `10.0.2.0/27` | 27 | Zero public IP jumpbox access |
| **Hub VNet** | `GatewaySubnet` | `10.0.3.0/27` | 27 | VPN & ExpressRoute hybrid connectivity |
| **Hub VNet** | `ManagementSubnet` | `10.0.4.0/24` | 251 | Jump hosts, build runners & telemetry |
| **Spoke Dev** | `vnet-spoke-dev` | `10.1.0.0/16` | 65,531 | Development environment workload space |
| **Spoke Prod** | `vnet-spoke-prod` | `10.2.0.0/16` | 65,531 | Production mission-critical workloads |

---

## 📂 Repository File System Architecture

```text
HUB-SPOKE/
├── azure-pipelines.yml       # 🔄 Azure DevOps Multi-Stage CI/CD pipeline
├── run-pipeline.ps1          # 🛠️ Shift-Left Checkov + Terraform execution harness
└── terraform/
    ├── environments/         # 🚀 ROOT DEPLOYMENTS (Decoupled State Backends)
    │   ├── hub/              # Central Hub: VNet, VPN Gateway, Key Vault
    │   ├── spoke-dev/        # Dev Workload VNet & Peering to Hub
    │   └── spoke-prod/       # Prod Workload VNet & Peering to Hub
    │
    └── modules/              # 🧩 REUSABLE TERRAFORM MODULES
        ├── key_vault/        # Private Key Vault with RBAC & Access Policies
        ├── network/          # Dynamic VNet/Subnet generator via for_each
        └── vpn/              # Enterprise Gateway & P2S / S2S VPN
```

---

## 🔒 Security & Shift-Left DevSecOps Gates

Every infrastructure change in this repository is strictly governed before merge:

1. **Static Analysis & CIS Benchmark (Checkov)**:
   - Scans all Terraform modules for non-compliant configurations (e.g., exposed storage accounts, unencrypted disks, permissive NSGs).
2. **Zero Blast-Radius State Decoupling**:
   - Each environment (`hub`, `spoke-dev`, `spoke-prod`) maintains its own isolated Terraform state file in Azure Blob Storage with lease-locking. A failure in `spoke-dev` can never corrupt or lock `spoke-prod`.
3. **Plan Artifact Verification**:
   - Deployments strictly consume immutable compiled `.tfplan` files to guarantee that what was approved in CI is exactly what is applied in CD.

---

## ⚡ Local Pipeline Simulation Harness (`run-pipeline.ps1`)

To test the entire deployment lifecycle locally prior to committing to Azure DevOps:

```powershell
# 1. Authenticate with Azure CLI
az login

# 2. Run the automated DevSecOps simulator
.\run-pipeline.ps1
```

The harness automatically executes:
- Checkov vulnerability scanning with threshold suppression
- `terraform init -upgrade` & provider lockfile verification
- `terraform fmt -check` & `terraform validate`
- `terraform plan -out main.tfplan` generation

---

<div align="center">

**[Explore Portfolio](https://b18g119.online)** · **[Connect on LinkedIn](https://linkedin.com/in/mihirmauryaa)** · **[DevOps Knowledge Vault](https://github.com/MihirMaurya-dev/DevOps-Notes)**

</div>
