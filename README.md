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
git clone https://github.com/your-username/cloud-network-architecture.git
cd cloud-network-architecture
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
├── network_connectivity.tf      # Network connectivity (VPN, ExpressRoute)
├── network_security.tf         # Network security (DDoS, Firewall, NSG)
├── database.tf                 # Database configuration (SQL, NoSQL, parameterization)
├── alerts.tf                   # Alert definitions and notification rules
├── variables.tf                # Terraform variables for modular deployment
├── terraform.yml               # CI/CD pipeline GitHub Actions for automatic deployment
├── README.md                   # Project documentation and setup guide
├── LICENSE                     # License file (MIT, Apache 2.0, or custom)
```

---
## **5. Deployed Resources**
This Terraform configuration **deploys the following Azure resources**:

Networking (Hub-and-Spoke Architecture)

		
  hub_and_spoke.tf
	•	azurerm_virtual_network – Creates the Hub and Spoke VNets for network segmentation.
	•	azurerm_subnet – Defines subnets for workloads, firewalls, and gateways.
	•	azurerm_virtual_network_peering – Establishes connectivity between Hub and Spoke VNets.

	network_connectivity.tf
	•	azurerm_express_route_circuit – Enables ExpressRoute for secure on-premises connectivity.

 Monitoring

	monitoring.tf
	•	azurerm_monitor_diagnostic_setting – Enables diagnostic logging for network and security components.
	•	azurerm_log_analytics_workspace – Stores logs for performance monitoring and security insights.
	•	azurerm_sentinel_log_analytics_workspace_onboarding – Connects Log Analytics to Azure Sentinel for advanced security analytics.
	•	azurerm_monitor_metric_alert – Triggers alerts based on network and security events. 

Database Configuration

	database.tf
	•	azurerm_mssql_server – Deploys a managed SQL Server instance.
	•	azurerm_mssql_database – Creates and configures SQL databases.
	•	azurerm_cosmosdb_account – Deploys a CosmosDB instance for NoSQL workloads.

Alerts and Notifications

	alerts.tf
	•	azurerm_monitor_action_group – Defines action groups for alert notifications.
	•	azurerm_monitor_activity_log_alert – Triggers alerts based on Azure activity logs.

Terraform and CI/CD

	terraform.yml
	•	GitHub Actions – Automates Terraform deployment, validation, and security checks.
	•	variables.tf
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
