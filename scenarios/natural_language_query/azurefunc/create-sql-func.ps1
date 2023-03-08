﻿# Create a single database and configure a firewall rule
# .\create-sql-func.ps1  "East US" "RGautomateddep1" "openaisqlautodep1" "openaisqldbautodep1" "azureuser" "test123456&%" "49f0b8a0-fd55-4abf-a2b8-afa7a09bb368" "16b3c013-d300-468d-ac64-7eda0820b6d3" "openaistact11" "openaifuc121"
param($location,$resourceGroup,$server,$database,$login,$password,$subscription,$tenantid,$storageaccountname,$functionname)

$tag="create-and-configure-database"
# Specify appropriate IP address values for your environment
# to limit access to the SQL Database server
$startIp="0.0.0.0"
$endIp="255.255.255.255"


az account set -s $subscription
echo "Using resource group $resourceGroup with login: $login, password: $password..."
echo "Creating $resourceGroup in $location..."

az group create --name $resourceGroup --location "$location" --tags $tag
echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
echo "Configuring firewall..."
az sql server firewall-rule create --resource-group $resourceGroup --server $server -n AllowYourIp --start-ip-address $startIp --end-ip-address $endIp
echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen5 --capacity 2 --zone-redundant true # zone redundancy is only supported on premium and business critical service tiers


az storage account create --name $storageaccountname --location $location --resource-group $resourceGroup --sku "Standard_LRS"  
echo "Creating function : $functionname"
az functionapp create --name $functionname --storage-account $storageaccountname --consumption-plan-location eastus --resource-group $resourceGroup --os-type Linux --runtime python --runtime-version 3.9 --functions-version 4

az webapp cors add --resource-group $resourceGroup --name $functionname --allowed-origins 'https://ms.portal.azure.com'

echo "Deploying function : $functionname"

Start-Sleep -Seconds 30  
func azure functionapp publish $functionname --force --python

