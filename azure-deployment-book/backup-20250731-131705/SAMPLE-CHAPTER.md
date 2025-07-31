# Chapter 2: Mastering Azure CLI for Infrastructure Automation

Azure CLI represents the most direct and immediate way to interact with Azure resources programmatically. While graphical interfaces provide discoverability and visual feedback, the command-line interface offers precision, repeatability, and automation capabilities essential for Infrastructure as Code practices.

This chapter builds the foundation of the enterprise payment system using Azure CLI automation, demonstrating practical patterns that apply to real-world operational scenarios. You'll learn not just the mechanics of CLI commands, but the strategic thinking behind effective infrastructure automation.

## In this chapter, we will cover the following topics:

- Azure CLI fundamentals and authentication strategies
- Building enterprise infrastructure components systematically  
- Implementing security and networking best practices
- Monitoring and observability configuration
- Error handling and operational resilience patterns
- Integration with CI/CD pipelines and automation systems

## Technical requirements

To follow along with the examples in this chapter, you will need:

- **Azure subscription** with Contributor role permissions
- **Azure CLI version 2.50 or later** installed on your development machine
- **Text editor or IDE** (Visual Studio Code recommended) for script development
- **Git** for version control of infrastructure scripts
- **Basic familiarity** with command-line interfaces and shell scripting

The complete code examples for this chapter are available in the book's GitHub repository at: `https://github.com/[repo-name]/chapter-2-azure-cli`

> **Important:** All examples in this chapter use the `canadacentral` region to comply with organizational policies commonly found in enterprise environments. Adjust the region parameter if your organization requires different geographic locations.

## Azure CLI fundamentals and authentication

Before diving into infrastructure automation, it's essential to understand Azure CLI's authentication model and core operational patterns. The Azure CLI uses the Azure Resource Manager REST API underneath, providing a consistent interface across all Azure services.

### Setting up authentication

Azure CLI supports multiple authentication methods appropriate for different scenarios:

**Interactive authentication** for development and learning:
```bash
az login
```

This command opens a web browser for interactive sign-in and caches credentials locally. While convenient for development, interactive authentication is inappropriate for automated systems.

**Service principal authentication** for production automation:
```bash
az login --service-principal \
  --username $SERVICE_PRINCIPAL_ID \
  --password $SERVICE_PRINCIPAL_SECRET \
  --tenant $TENANT_ID
```

Service principals provide non-interactive authentication suitable for CI/CD pipelines and automated systems. They can be assigned specific permissions following the principle of least privilege.

**Managed identity authentication** for Azure-hosted automation:
```bash
az login --identity
```

When running automation from Azure resources like virtual machines or Azure Container Instances, managed identities provide authentication without managing credentials explicitly.

### Configuring default settings

Azure CLI allows setting default values for frequently used parameters, reducing repetition and improving script readability:

```bash
# Set default subscription
az account set --subscription "Production Subscription"

# Set default resource group
az configure --defaults group=rg-payment-system-prod

# Set default location
az configure --defaults location=canadacentral
```

These defaults apply to subsequent commands unless explicitly overridden, simplifying script maintenance and reducing parameter verbosity.

> **Note:** Default settings are stored per user profile. In automated environments, explicitly specify all required parameters to ensure predictable behavior regardless of the execution context.

## Building the payment system foundation

The enterprise payment system requires several foundational Azure resources that must be deployed in a specific order due to dependencies. This section demonstrates systematic infrastructure deployment using Azure CLI, implementing patterns applicable to any complex multi-tier application.

### Resource naming and tagging strategy

Consistent resource naming and comprehensive tagging are essential for operational management, cost allocation, and governance compliance. The following conventions apply throughout the payment system:

**Naming convention:**
```bash
# Resource naming pattern: {resource-type}-{project}-{component}-{environment}
RESOURCE_GROUP="rg-payment-system-dev"
VNET_NAME="vnet-payment-system-dev"  
SUBNET_NAME="subnet-payment-apps-dev"
DATABASE_NAME="psql-payment-system-dev"
```

**Tagging strategy:**
```bash
# Comprehensive tagging for governance and cost management
TAGS="Project=PaymentSystem Environment=Development CostCenter=Engineering Owner=DevOpsTeam Compliance=Required"
```

These tags enable Azure Policy compliance, cost reporting, and automated resource management across the organization.

### Creating the resource group

Resource groups provide logical containers for related Azure resources, enabling unified management, permissions, and lifecycle operations:

```bash
#!/bin/bash
# create-resource-group.sh

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration variables
RESOURCE_GROUP="rg-payment-system-dev"
LOCATION="canadacentral" 
TAGS="Project=PaymentSystem Environment=Development CostCenter=Engineering Owner=DevOpsTeam"

echo "Creating resource group: $RESOURCE_GROUP"

# Create resource group with comprehensive tagging
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags $TAGS

# Verify creation and display results
echo "Resource group created successfully:"
az group show --name "$RESOURCE_GROUP" --output table
```

The script includes several best practices for production automation:

- **Error handling** with `set -euo pipefail` to catch failures immediately
- **Variable configuration** at the top for easy modification
- **Descriptive output** to confirm successful operations
- **Verification commands** to validate deployment results

### Implementing virtual networking

The payment system requires secure networking with proper isolation between application tiers. Azure Virtual Network provides the foundation for all network communication:

```bash
#!/bin/bash
# create-networking.sh

set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-payment-system-dev"
VNET_NAME="vnet-payment-system-dev"
VNET_ADDRESS_SPACE="10.0.0.0/16"
APP_SUBNET_NAME="subnet-payment-apps-dev"
APP_SUBNET_ADDRESS="10.0.1.0/24"
DB_SUBNET_NAME="subnet-payment-database-dev"
DB_SUBNET_ADDRESS="10.0.2.0/24"
TAGS="Project=PaymentSystem Environment=Development"

echo "Creating virtual network infrastructure..."

# Create virtual network
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_ADDRESS_SPACE" \
  --tags $TAGS

# Create application subnet
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$APP_SUBNET_NAME" \
  --address-prefixes "$APP_SUBNET_ADDRESS"

# Create database subnet with delegation for PostgreSQL
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$DB_SUBNET_NAME" \
  --address-prefixes "$DB_SUBNET_ADDRESS" \
  --delegations Microsoft.DBforPostgreSQL/flexibleServers

echo "Virtual network infrastructure created successfully"

# Display network configuration
az network vnet list --resource-group "$RESOURCE_GROUP" --output table
az network vnet subnet list --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --output table
```

This networking configuration implements several security best practices:

- **Subnet segmentation** isolates application and database tiers
- **Address space planning** allows for future expansion without conflicts  
- **Service delegation** enables Azure services to configure networking automatically
- **Consistent tagging** maintains governance compliance

> **Important:** Subnet delegation for `Microsoft.DBforPostgreSQL/flexibleServers` is required for PostgreSQL Flexible Server private networking. This delegation allows Azure to configure network policies automatically.

### Deploying PostgreSQL database infrastructure

The payment system requires a highly available PostgreSQL database with enterprise security features:

```bash
#!/bin/bash
# create-database.sh

set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-payment-system-dev"
SERVER_NAME="psql-payment-system-dev"
VNET_NAME="vnet-payment-system-dev" 
SUBNET_NAME="subnet-payment-database-dev"
ADMIN_USERNAME="pgadmin"
ADMIN_PASSWORD="$(openssl rand -base64 32)" # Generate secure password
TAGS="Project=PaymentSystem Environment=Development Tier=Database"

echo "Creating PostgreSQL Flexible Server..."
echo "Generated admin password: $ADMIN_PASSWORD"
echo "Please save this password securely!"

# Get subnet ID for private networking
SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query id --output tsv)

# Create PostgreSQL Flexible Server with high availability
az postgres flexible-server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --location canadacentral \
  --admin-user "$ADMIN_USERNAME" \
  --admin-password "$ADMIN_PASSWORD" \
  --sku-name Standard_D2s_v3 \
  --tier GeneralPurpose \
  --storage-size 128 \
  --version 14 \
  --subnet "$SUBNET_ID" \
  --private-dns-zone "$SERVER_NAME.private.postgres.database.azure.com" \
  --tags $TAGS

# Configure high availability
az postgres flexible-server update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --high-availability Enabled \
  --high-availability-mode ZoneRedundant

# Configure backup retention
az postgres flexible-server parameter set \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SERVER_NAME" \
  --name backup_retention_days \
  --value 7

echo "PostgreSQL Flexible Server created with high availability"

# Display server configuration
az postgres flexible-server show --resource-group "$RESOURCE_GROUP" --name "$SERVER_NAME" --output table
```

This database configuration implements enterprise requirements:

- **High availability** with zone-redundant deployment for 99.99% SLA
- **Private networking** preventing internet access to database
- **Secure password generation** using cryptographically strong methods
- **Backup retention** configured for operational requirements
- **Resource tagging** for governance and cost management

## Implementing security and networking best practices

Security must be implemented systematically across all infrastructure components. This section demonstrates practical security hardening using Azure CLI, focusing on network security groups, private endpoints, and access controls.

### Network security groups and rules

Network Security Groups (NSGs) provide distributed firewall capabilities for controlling traffic flow between subnets and individual network interfaces:

```bash
#!/bin/bash
# create-network-security.sh

set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-payment-system-dev"
APP_NSG_NAME="nsg-payment-apps-dev"
DB_NSG_NAME="nsg-payment-database-dev"
APP_SUBNET_NAME="subnet-payment-apps-dev"
DB_SUBNET_NAME="subnet-payment-database-dev"
VNET_NAME="vnet-payment-system-dev"

echo "Creating network security groups..."

# Create application tier NSG
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NSG_NAME" \
  --location canadacentral

# Allow HTTP traffic from Application Gateway
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$APP_NSG_NAME" \
  --name "AllowApplicationGateway" \
  --protocol Tcp \
  --direction Inbound \
  --priority 1000 \
  --source-address-prefixes "10.0.0.0/24" \
  --destination-port-ranges 80 443 \
  --access Allow

# Allow container apps internal communication
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$APP_NSG_NAME" \
  --name "AllowContainerAppsInternal" \
  --protocol Tcp \
  --direction Inbound \
  --priority 1100 \
  --source-address-prefixes "10.0.1.0/24" \
  --destination-port-ranges 80-8080 \
  --access Allow

# Create database tier NSG
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_NSG_NAME" \
  --location canadacentral

# Allow PostgreSQL access only from application subnet
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$DB_NSG_NAME" \
  --name "AllowPostgreSQLFromApps" \
  --protocol Tcp \
  --direction Inbound \
  --priority 1000 \
  --source-address-prefixes "10.0.1.0/24" \
  --destination-port-ranges 5432 \
  --access Allow

# Associate NSGs with subnets
az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$APP_SUBNET_NAME" \
  --network-security-group "$APP_NSG_NAME"

az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$DB_SUBNET_NAME" \
  --network-security-group "$DB_NSG_NAME"

echo "Network security groups created and associated with subnets"

# Display NSG rules
az network nsg list --resource-group "$RESOURCE_GROUP" --output table
```

This security configuration implements defense-in-depth principles:

- **Least privilege access** allowing only necessary traffic between tiers
- **Source-based filtering** restricting database access to application subnet only
- **Protocol-specific rules** limiting attack surface to required services
- **Priority-based ordering** ensuring critical rules take precedence

## What we learned

This chapter demonstrated fundamental Azure CLI patterns for infrastructure automation, using the enterprise payment system as a practical example. Key concepts covered include:

**Authentication and configuration** strategies appropriate for different deployment scenarios, from development to production automation.

**Systematic deployment patterns** that handle resource dependencies and ensure consistent results across environments.

**Security implementation** using network security groups, private networking, and access controls that follow enterprise best practices.

**Error handling and validation** techniques that make automation scripts robust and suitable for production use.

**Resource organization** using naming conventions, tagging strategies, and logical grouping that supports operational management and governance requirements.

The next chapter builds upon this foundation by exploring operational excellence patterns, including error handling, environment management, and CI/CD integration for Azure CLI automation.
