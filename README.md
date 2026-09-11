# Azure Hub-Spoke Architecture (Terraform)

This repository contains a professional-grade, multi-environment Hub-and-Spoke networking architecture for Microsoft Azure, fully defined in Terraform. 

## 🏗️ Architecture Overview

The codebase deploys a central **Hub** and multiple **Spokes** (Dev, Prod). 
- **Hub Environment:** Contains shared security and connectivity tools (VPN Gateway, Key Vault).
- **Spoke Environments:** Isolated networks for specific workloads (Web, App, DB tiers) that connect back to the Hub via VNet Peering.

## 📂 Repository Structure

This project is specifically structured to support **Multi-Agent Parallelism** in Azure DevOps CI/CD pipelines. State files are intentionally separated by environment to prevent state-lock errors.

```text
HUB-SPOKE/
├── terraform/
│   ├── environments/         # 🚀 ROOT DEPLOYMENTS (Each has its own state)
│   │   ├── hub/              # Deploys the Hub VNet, VPN, Key Vault
│   │   ├── spoke-dev/        # Deploys Dev VNet & Peers to Hub
│   │   └── spoke-prod/       # Deploys Prod VNet & Peers to Hub
│   │
│   └── modules/              # 🧩 REUSABLE MODULES
│       ├── key_vault/
│       ├── network/          # Dynamic VNet/Subnet generator (for_each)
│       └── vpn/
└── run-pipeline.ps1          # 🛠️ DevSecOps CI/CD Simulator
```

## 🔒 DevSecOps & Security Scanning

This repository integrates **Checkov** (Static Application Security Testing) to automatically scan the Terraform code for cloud vulnerabilities before deployment. 

The `run-pipeline.ps1` script acts as a local simulator for an Azure DevOps YAML pipeline. It performs:
1. Security Scanning (`checkov`)
2. Initialization (`terraform init -upgrade`)
3. Formatting & Validation (`terraform validate`)
4. Plan Artifact Generation (`terraform plan -out main.tfplan`)

## 🚀 Getting Started

### Prerequisites
1. [Terraform](https://developer.hashicorp.com/terraform/downloads) installed locally.
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed locally.
3. [Python/PIP](https://www.python.org/downloads/) (to run Checkov).

### How to run the pipeline simulator

1. Log into Azure via your terminal:
   ```powershell
   az login
   ```
2. Execute the ADO simulator script:
   ```powershell
   .\run-pipeline.ps1
   ```

*Note: The simulator currently points to the `terraform/environments/hub` folder. You can edit the `$TF_DIR` variable inside `run-pipeline.ps1` to test the Dev or Prod spokes.*