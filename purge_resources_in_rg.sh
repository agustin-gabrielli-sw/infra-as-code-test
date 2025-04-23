#!/bin/bash

# Purge all resources in a resource group

echo "Purging resources..."

function purge-resource-group() {
    if [ -z "$1" ]; then
        echo "Usage: purge-resource-group <resource-group-name>"
        return 1
    fi

    local rg_name=$1
    
    echo "Deleting all resources in resource group: $rg_name"
    
    # Delete all resources in the resource group
    az deployment group create \
        --resource-group $rg_name \
        --mode Complete \
        --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/100-blank-template/azuredeploy.json" \
        --parameters "{}"
    
    echo "Purging soft-deleted resources..."
    
    # Purge soft-deleted API Management services
    az rest --method get --url "/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.ApiManagement/deletedservices?api-version=2021-08-01" \
        --query "value[?resourceGroup=='$rg_name'].name" -o tsv | while read name; do
        echo "Purging API Management service: $name"
        az rest --method delete --url "/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.ApiManagement/locations/$(az group show -n $rg_name --query location -o tsv)/deletedservices/$name?api-version=2021-08-01"
    done
    
    # Purge soft-deleted Cognitive Services
    az rest --method get --url "/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.CognitiveServices/deletedAccounts?api-version=2021-10-01" \
        --query "value[?resourceGroup=='$rg_name'].name" -o tsv | while read name; do
        echo "Purging Cognitive Service: $name"
        az rest --method delete --url "/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.CognitiveServices/locations/$(az group show -n $rg_name --query location -o tsv)/deletedAccounts/$name?api-version=2021-10-01"
    done
    
    # Purge soft-deleted Application Insights
    az rest --method get --url "/subscriptions/$(az account show --query id -o tsv)/providers/microsoft.insights/components?api-version=2020-02-02" \
        --query "value[?resourceGroup=='$rg_name'].name" -o tsv | while read name; do
        echo "Purging Application Insights: $name"
        az rest --method delete --url "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rg_name/providers/microsoft.insights/components/$name?api-version=2020-02-02"
    done
    
    # We won't delete the resource group
    # echo "Deleting resource group: $rg_name"
    # az group delete --name $rg_name --yes --no-wait
    
    echo "Purge operation completed. Note: Some resources may take up to 48 hours to be completely purged."
}

# Call the function with the provided resource group name
purge-resource-group "$1"