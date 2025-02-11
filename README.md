# **Cloud Network Architecture: Hub-and-Spoke Model with Terraform**

## **Overview**
This project provides a **scalable, secure, and production-ready cloud networking architecture** using the **Hub-and-Spoke model**.  
The infrastructure is **fully automated with Terraform** and follows best practices for security, monitoring, and CI/CD.

---

## **1. Introduction**
This document describes a **professional-grade cloud network architecture** using the **Hub-and-Spoke model**, integrating both **cloud-based** and **on-premise** environments.  
It provides a **structured Terraform infrastructure** covering networking, security, monitoring, and CI/CD principles with well-defined resource groupings.

### **Why Hub-and-Spoke?**
The **Hub-and-Spoke model** is an **industry-standard** approach that provides:
- **Centralized Security & Connectivity** – The Hub acts as a single control point for security policies, gateways, and monitoring.
- **Workload Isolation** – Spokes allow for separate environments (e.g., Dev, Test, Prod) while maintaining interconnectivity.
- **Scalability & Flexibility** – New Spokes can be added as needed without disrupting the core network.
- **Efficient On-Premise Integration** – Secure and optimized connectivity to local data centers.

[Learn more about the Hub-and-Spoke model](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology?utm_source=chatgpt.com)

---

## **2. Prerequisites**
Before deploying, ensure you have the following installed:

### **Required Tools**
- [Terraform](https://developer.hashicorp.com/terraform/tutorials) (version 1.5.6 or later)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (for authentication)
- [GitHub CLI](https://cli.github.com/) (if using GitHub Actions)
- [jq](https://stedolan.github.io/jq/) (for JSON parsing, optional)

### **Azure Account Setup**
1. **Login to Azure CLI**:  
   ```bash
   az login
   ```
2. **Set subscription (if needed)**:  
   ```bash
   az account set --subscription <SUBSCRIPTION_ID>
   ```

---

## **3. Deployment Steps**

### **Step 1: Clone the Repository**
```bash
git clone (https://github.com/Vitmer/Hub_and_Spoke_Model_with_Terraform.git)
cd Hub_and_Spoke_Model_with_Terraform
```

### **Step 2: Configure Terraform Variables**
Edit the `terraform.tfvars` file or export variables manually:
```bash
export TF_VAR_subscription_id="your-subscription-id"
export TF_VAR_resource_group_name="your-resource-group"
export TF_VAR_location="westeurope"
```

### **Step 3: Initialize Terraform**
```bash
terraform init
```

### **Step 4: Plan Deployment**
```bash
terraform plan
```

### **Step 5: Apply Deployment**
```bash
terraform apply -auto-approve
```

This will provision the **entire Hub-and-Spoke network, security policies, monitoring, and CI/CD pipelines**.

---

## **4. File Structure**
```
├── hub_and_spoke.tf            # Hub-and-Spoke network configuration (VNet, Peering, Load Balancer)
├── security.tf                 # Security configuration (RBAC, NSG, Key Vault, Zero Trust policies)
├── monitoring.tf               # Monitoring (Azure Monitor, Log Analytics, alert rules)
├── network_connectivity.tf      # Network connectivity (VPN, ExpressRoute, Virtual WAN)
├── network_security.tf         # Network security (DDoS Protection, Firewall, NSG, Route Tables)
├── database.tf                 # Database configuration (SQL Server with Private Endpoints)
├── alerts.tf                   # Alert definitions and notification rules (VPN, SQL Server Storage)
├── private_endpoints.tf        # Private Endpoints configuration (Secure access to SQL Server and internal services)
├── variables.tf                # Terraform variables for modular deployment
├── terraform.yml               # CI/CD pipeline with GitHub Actions for automatic deployment
├── README.md                   # Project documentation and setup guide
├── LICENSE                     # License file (MIT, Apache 2.0, or custom)
```

---
## **5. Deployed Resources**
This Terraform configuration **deploys the following Azure resources**:

Networking (Hub-and-Spoke Architecture)

hub_and_spoke.tf
	•	azurerm_virtual_network – Defines the Hub and Spoke VNets for network segmentation.
	•	azurerm_subnet – Configures subnets for workloads, firewalls, and gateways.
	•	azurerm_virtual_network_peering – Establishes connectivity between Hub and Spoke VNets.
	•	azurerm_virtual_hub – Creates a Virtual Hub for centralized routing.
	•	azurerm_virtual_hub_connection – Connects the Hub to Spoke VNets.

network_connectivity.tf
	•	azurerm_express_route_circuit – Enables ExpressRoute for secure hybrid connectivity.
	•	azurerm_virtual_network_gateway – Deploys a VPN Gateway for secure remote access.
	•	azurerm_virtual_network_gateway_connection – Establishes a VPN tunnel to on-premises networks.
	•	azurerm_local_network_gateway – Defines on-premises VPN connectivity.

Security and Network Protection

network_security.tf
	•	azurerm_firewall – Deploys an Azure Firewall to control inbound and outbound traffic.
	•	azurerm_firewall_policy – Defines firewall rules and security policies.
	•	azurerm_network_security_group – Enforces security rules at the subnet level.
	•	azurerm_subnet_network_security_group_association – Associates NSG with subnets.
	•	azurerm_route_table – Configures custom route tables for traffic filtering.

security.tf
	•	azurerm_key_vault – Creates a secure Key Vault for storing secrets.
	•	azurerm_key_vault_secret – Stores sensitive credentials inside Key Vault.
	•	azurerm_network_ddos_protection_plan – Provides DDoS protection for network security.
	•	azurerm_role_assignment – Implements RBAC for controlled access to Azure resources.  

Monitoring and Observability

monitoring.tf
	•	azurerm_monitor_diagnostic_setting – Enables diagnostic logging for network and security components.
	•	azurerm_log_analytics_workspace – Stores logs for security insights and monitoring.
	•	azurerm_monitor_metric_alert – Defines alerts for VPN connectivity and SQL Server storage.
	•	azurerm_monitor_action_group – Sends notifications when alerts are triggered.

Database Configuration

database.tf
	•	azurerm_mssql_server – Deploys a managed SQL Server instance.
	•	azurerm_private_endpoint – Ensures private connectivity to SQL Server.

Private Endpoints & Secure Connectivity

private_endpoints.tf
	•	azurerm_private_dns_zone – Manages DNS resolution for private endpoints.
	•	azurerm_private_endpoint – Enables secure private access to services.
	•	azurerm_private_dns_zone_virtual_network_link – Links the DNS zone to the Hub VNet.

Alerts and Notifications

alerts.tf
	•	azurerm_monitor_action_group – Defines action groups for email notifications.
	•	azurerm_monitor_metric_alert – Monitors VPN connectivity and SQL Server storage utilization.

Terraform and CI/CD

terraform.yml
	•	GitHub Actions – Automates Terraform deployment, validation, and security checks.

variables.tf
	•	Stores reusable Terraform variables for modular infrastructure deployment.

## **6. CI/CD Pipeline**
- This project uses **GitHub Actions** for **automatic deployment**.
- The CI/CD pipeline will:
  - Run `terraform fmt`, `terraform validate`, and `terraform plan` on pull requests.
  - Apply Terraform changes on merges to `main`.

**GitHub Actions Configuration:** (`terraform.yml`)
```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.6
      - name: Terraform Init & Apply
        run: |
          terraform init
          terraform apply -auto-approve
```

---

## **7. Cleanup**
To destroy the infrastructure, run:
```bash
terraform destroy -auto-approve
```

---

## **8. Best Practices for Cloud Networking Architecture**
✅ **Infrastructure as Code (IaC)** – Maintainable, version-controlled network infrastructure.  
✅ **Security-First Approach** – Zero Trust, RBAC, and strong encryption policies.  
✅ **Observability & Monitoring** – Real-time tracking of network health and security threats.  
✅ **Scalability & Resilience** – Automated scaling with disaster recovery mechanisms.  
✅ **Continuous Deployment** – CI/CD pipelines for rapid and reliable network updates.  

---

## **9. License**
This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## **10. Additional Resources**
- [Microsoft Azure: Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/tutorials)
- [GitHub Actions Guide](https://docs.github.com/en/actions)
