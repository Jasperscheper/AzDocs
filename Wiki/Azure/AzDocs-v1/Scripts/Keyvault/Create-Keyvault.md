[[_TOC_]]

# Description

This snippet will create a keyvault if it does not exist within a given (existing) subnet. It will also make sure that public access is denied by default. It will whitelist the application subnet so your app can connect to the keyvault within the vnet. All the needed components (private endpoint, service endpoint etc) will be created too.

This snippet also managed the following compliancy rules:

- Enable soft-delete
- Enable Diagnostic settings
- Use private endpoint
- block access from the internet
- Whitelist subnet

# Parameters

Some parameters from [General Parameter](/Azure/AzDocs-v1/Scripts) list.

| Parameter                       | Required                        | Example Value                                                                                                                                   | Description                                                                                                                                                                                                                               |
| ------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| KeyvaultName                    | <input type="checkbox" checked> | `mykeyvault-$(Release.EnvironmentName)`                                                                                                         | This is the keyvault name to use.                                                                                                                                                                                                         |
| LogAnalyticsWorkspaceResourceId | <input type="checkbox">         | `/subscriptions/<subscriptionid>/resourceGroups/<resourcegroup>/providers/Microsoft.OperationalInsights/workspaces/<loganalyticsworkspacename>` | The name of the Log Analytics Workspace for the diagnostics settings of the keyvault.                                                                                                                                                     |
| KeyvaultResourceGroupName       | <input type="checkbox">         | `MyTeam-TestApi-$(Release.EnvironmentName)`                                                                                                     | The ResourceGroup where your keyvault will reside in.                                                                                                                                                                                     |
| KeyvaultPurgeProtectionEnabled  | <input type="checkbox">         | `true`/`false`                                                                                                                                  | This will enable or disable purge protection on the keyvault. Default value is `true`.                                                                                                                                                    |
| KeyvaultSku                     | <input type="checkbox">         | `Standard`                                                                                                                                      | The tier of the keyvault. Choices are `Premium` and `Standard`. Defaults to `Standard`.                                                                                                                                                   |
| KeyvaultRetentionInDays         | <input type="checkbox">         | `90`                                                                                                                                            | The amount of days the keyvault should keep its retention. Should be between 7 and 90 days, defaults to 90.                                                                                                                               |
| ForceDisablePurgeProtection     | <input type="checkbox">         | n.a.                                                                                                                                            | If you want to disable purge protection on your keyvault, you will need to pass this extra boolean to confirm you are willingly doing this. You can pass it as a switch without a value (`-ForceDisablePurgeProtection`).                 |
| ForcePublic                     | <input type="checkbox">         | n.a.                                                                                                                                            | If you are not using any networking settings, you need to pass this boolean to confirm you are willingly creating a public resource (to avoid unintended public resources). You can pass it as a switch without a value (`-ForcePublic`). |
| DiagnosticSettingsLogs          | <input type="checkbox">         | `@('Requests';'MongoRequests';)`                                                                                                                | If you want to enable a specific set of diagnostic settings for the category 'Logs'. By default, all categories for 'Logs' will be enabled.                                                                                               |
| DiagnosticSettingsMetrics       | <input type="checkbox">         | `@('Requests';'MongoRequests';)`                                                                                                                | If you want to enable a specific set of diagnostic settings for the category 'Metrics'. By default, all categories for 'Metrics' will be enabled.                                                                                         |
| DiagnosticSettingsDisabled      | <input type="checkbox">         | n.a.                                                                                                                                            | If you don't want to enable any diagnostic settings, you can pass this as a switch witout a value(`-DiagnosticsettingsDisabled`).                                                                                                         |
| KeyvaultBypassTraffic           | <input type="checkbox">         | `None`/`AzureServices`                                                                                                                          | The switch to allow trusted Microsoft services to bypass the firewall. Defaults to `None`                                                                                                                                                 |

# VNET Whitelisting Parameters

If you want to use "vnet whitelisting" on your resource. Use these parameters. Using VNET Whitelisting is the recommended way of building & connecting your application stack within Azure.

> NOTE: These parameters are only required when you want to use the VNet whitelisting feature for this resource.

| Parameter                        | Required for VNET Whitelisting  | Example Value                        | Description                                                         |
| -------------------------------- | ------------------------------- | ------------------------------------ | ------------------------------------------------------------------- |
| ApplicationVnetResourceGroupName | <input type="checkbox" checked> | `sharedservices-rg`                  | The ResourceGroup where your VNET, for your appservice, resides in. |
| ApplicationVnetName              | <input type="checkbox" checked> | `my-vnet-$(Release.EnvironmentName)` | The name of the VNET the appservice is in                           |
| ApplicationSubnetName            | <input type="checkbox" checked> | `app-subnet-3`                       | The subnetname for the subnet whitelist on the keyvault.            |

# Private Endpoint Parameters

If you want to use private endpoints on your resource. Use these parameters. Private Endpoints are used for connecting to your Azure Resources from on-premises.

> NOTE: These parameters are only required when you want to use a private endpoint for this resource.

| Parameter                                    | Required for Pvt Endpoint       | Example Value                           | Description                                                                                                                     |
| -------------------------------------------- | ------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| KeyvaultPrivateEndpointVnetResourceGroupName | <input type="checkbox" checked> | `sharedservices-rg`                     | The ResourceGroup where your VNET, for your SQL Server Private Endpoint, resides in.                                            |
| KeyvaultPrivateEndpointVnetName              | <input type="checkbox" checked> | `my-vnet-$(Release.EnvironmentName)`    | The name of the VNET to place the Keyvault Private Endpoint in.                                                                 |
| KeyvaultPrivateEndpointSubnetName            | <input type="checkbox" checked> | `app-subnet-3`                          | The name of the subnet where the keyvault's private endpoint will reside in.                                                    |
| DNSZoneResourceGroupName                     | <input type="checkbox" checked> | `MyDNSZones-$(Release.EnvironmentName)` | Make sure to use the shared DNS Zone resource group (you can only register a zone once per subscription).                       |
| KeyvaultPrivateDnsZoneName                   | <input type="checkbox" checked> | `privatelink.vaultcore.azure.net`       | Generally this will be `privatelink.vaultcore.azure.net`. This defines which DNS Zone to use for the private keyvault endpoint. |

# YAML

Be aware that this YAML example contains all parameters that can be used with this script. You'll need to pick and choose the parameters that are needed for your desired action.

```yaml
- task: AzureCLI@2
  displayName: "Create Keyvault"
  condition: and(succeeded(), eq(variables['DeployInfra'], 'true'))
  inputs:
    azureSubscription: "${{ parameters.SubscriptionName }}"
    scriptType: pscore
    scriptPath: "$(Pipeline.Workspace)/AzDocs/Keyvault/Create-Keyvault.ps1"
    arguments: "-KeyvaultName '$(KeyvaultName)' -KeyvaultResourceGroupName '$(KeyvaultResourceGroupName)' -ResourceTags $(ResourceTags) -LogAnalyticsWorkspaceResourceId '$(LogAnalyticsWorkspaceResourceId)' -ApplicationVnetResourceGroupName '$(ApplicationVnetResourceGroupName)' -ApplicationVnetName '$(ApplicationVnetName)' -ApplicationSubnetName '$(ApplicationSubnetName)' -KeyvaultPrivateEndpointVnetResourceGroupName '$(KeyvaultPrivateEndpointVnetResourceGroupName)' -KeyvaultPrivateEndpointVnetName '$(KeyvaultPrivateEndpointVnetName)' -KeyvaultPrivateEndpointSubnetName '$(KeyvaultPrivateEndpointSubnetName)' -DNSZoneResourceGroupName '$(DNSZoneResourceGroupName)' -KeyvaultPrivateDnsZoneName '$(KeyvaultPrivateDnsZoneName)' -KeyvaultRetentionInDays '$(KeyvaultRetentionInDays)' -DiagnosticSettingsLogs $(DiagnosticSettingsLogs) -DiagnosticSettingsDisabled $(DiagnosticSettingsDisabled) -KeyvaultBypassTraffic '$(KeyvaultBypassTraffic)'"
```

# Code

[Click here to download this script](../../../../src/Keyvault/Create-Keyvault.ps1)

# Links

[Azure CLI - az-keyvault-create](https://docs.microsoft.com/en-us/cli/azure/keyvault?view=azure-cli-latest#az-keyvault-create)

[Azure CLI - Keyvault softdelete](https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-cli)

[Azure CLI - az-network-vnet-subnet-update](https://docs.microsoft.com/en-us/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-update)

[Azure CLI - az-keyvault-show](https://docs.microsoft.com/en-us/cli/azure/keyvault?view=azure-cli-latest#az-keyvault-show)

[Azure CLI - az-network-private-endpoint-create](https://docs.microsoft.com/en-us/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create)

[Azure CLI - az-network-private-dns-zone-show](https://docs.microsoft.com/en-us/cli/azure/ext/privatedns/network/private-dns/zone?view=azure-cli-latest#ext-privatedns-az-network-private-dns-zone-show)

[Azure CLI - az-network-private-dns-zone-create](https://docs.microsoft.com/en-us/cli/azure/ext/privatedns/network/private-dns/zone?view=azure-cli-latest#ext-privatedns-az-network-private-dns-zone-create)

[Azure CLI - az-network-private-dns-link-vnet-show](https://docs.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-show)

[Azure CLI - az-network-private-dns-link-vnet-create](https://docs.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-create)

[Azure CLI - az-network-private-endpoint-dns-zone-group-create](https://docs.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group?view=azure-cli-latest#az-network-private-endpoint-dns-zone-group-create)

[Azure CLI - az-network-vnet-subnet-show](https://docs.microsoft.com/en-us/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-show)

[Azure CLI - az-keyvault-network-rule-add](https://docs.microsoft.com/en-us/cli/azure/keyvault/network-rule?view=azure-cli-latest#az-keyvault-network-rule-add)

[Azure CLI - az-network-private-link-resource-list](https://docs.microsoft.com/en-us/cli/azure/network/private-link-resource?view=azure-cli-latest#az-network-private-link-resource-list)

[Create Diagnostics settings](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings)

[Azure CLI - Create Diagnostics settings](http://techgenix.com/azure-diagnostic-settings/)
