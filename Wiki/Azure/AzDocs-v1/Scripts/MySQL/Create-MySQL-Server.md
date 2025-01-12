[[_TOC_]]

# Description

This snippet will create a MySQL Server if it does not exist. There are two options of connecting your application to this MySQL Server.

## VNET Whitelisting (uses the "public interface")

Microsoft does some neat tricks where you can whitelist your vnet/subnet op the MySQL server without your MySQL server having to be inside the vnet itself (public/private address translation).
This script will whitelist the application subnet so your app can connect to the MySQL Server over the public endpoint, while blocking all other traffic (internet traffic for example). Service Endpoints will also be provisioned if needed on the subnet.

## Private Endpoints

There is an option where it will create private endpoints for you & also disables public access if desired. All the needed components (private endpoint, DNS etc.) will be created too.

# Parameters

Some parameters from [General Parameter](/Azure/AzDocs-v1/Scripts) list.

| Parameter                       | Required                        | Example Value                                                                                                                                   | Description                                                                                                                                                                                                                               |
| ------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MySqlServerLocation             | <input type="checkbox" checked> | `westeurope`                                                                                                                                    | The location of your MySQL Server. It's very likely you can use `$(Location)` here (see the ) [General Parameter](/Azure/AzDocs-v1/Scripts) list.                                                                                         |
| MySqlServerName                 | <input type="checkbox" checked> | `somemysqlserver$(Release.EnvironmentName)`                                                                                                     | The name for the MySQL Server resource. It's recommended to use just alphanumerical characters without hyphens etc.                                                                                                                       |
| MySqlServerUsername             | <input type="checkbox" checked> | `rob`                                                                                                                                           | The admin username for the MySQL Server                                                                                                                                                                                                   |
| MySqlServerPassword             | <input type="checkbox" checked> | `#$mydatabas**e`                                                                                                                                | The password corresponding to MySqlServerUsername                                                                                                                                                                                         |
| MySqlServerResourceGroupName    | <input type="checkbox" checked> | `myteam-testapi-$(Release.EnvironmentName)`                                                                                                     | The name of the resourcegroup you want your MySql server to be created in                                                                                                                                                                 |
| MySqlServerSkuName              | <input type="checkbox" checked> | `GP_Gen5_4`                                                                                                                                     | The name of the sku. Follows the convention {pricing tier}{compute generation}{vCores} in shorthand. Examples: `B_Gen5_1`, `GP_Gen5_4`, `MO_Gen5_16`.                                                                                     |
| MySqlServerStorageSizeInMB      | <input type="checkbox" checked> | `51200`                                                                                                                                         | The storage capacity of the server (unit is megabytes).                                                                                                                                                                                   |
| MySqlServerMinimalTlsVersion    | <input type="checkbox">         | `TLS1_2`                                                                                                                                        | The minimal TLS version to use. Defaults to `TLS1_2`. Options are `TLS1_0`, `TLS1_1`, `TLS1_2` or `TLSEnforcementDisabled`. It's strongly recommended to use `TLS1_2` at the time of writing.                                             |
| MySqlServerSslEnforcement       | <input type="checkbox">         | `Enabled`/`Disabled`                                                                                                                            | Enables the enforcement of SSL connections. Default value is `Enabled`. It is strongly recommended to leave this `Enabled`.                                                                                                               |
| LogAnalyticsWorkspaceResourceId | <input type="checkbox" checked> | `/subscriptions/<subscriptionid>/resourceGroups/<resourcegroup>/providers/Microsoft.OperationalInsights/workspaces/<loganalyticsworkspacename>` | The Log Analytics Workspace the diagnostic setting will be linked to.                                                                                                                                                                     |
| ForcePublic                     | <input type="checkbox">         | n.a.                                                                                                                                            | If you are not using any networking settings, you need to pass this boolean to confirm you are willingly creating a public resource (to avoid unintended public resources). You can pass it as a switch without a value (`-ForcePublic`). |
| ForceDisableTLS                 | <input type="checkbox">         | n.a.                                                                                                                                            | If you are willingly creating a the resource without any TLS version enforce, you need to pass this boolean to confirm you want to do this. You can pass it as a switch without a value (`-ForceDisableTLS`)                              |
| DiagnosticSettingsLogs          | <input type="checkbox">         | `@('Requests';'MongoRequests';)`                                                                                                                | If you want to enable a specific set of diagnostic settings for the category 'Logs'. By default, all categories for 'Logs' will be enabled.                                                                                               |
| DiagnosticSettingsMetrics       | <input type="checkbox">         | `@('Requests';'MongoRequests';)`                                                                                                                | If you want to enable a specific set of diagnostic settings for the category 'Metrics'. By default, all categories for 'Metrics' will be enabled.                                                                                         |
| DiagnosticSettingsDisabled      | <input type="checkbox">         | n.a.                                                                                                                                            | If you don't want to enable any diagnostic settings, you can pass this as a switch witout a value(`-DiagnosticsettingsDisabled`).                                                                                                         |

# VNET Whitelisting Parameters

If you want to use "vnet whitelisting" on your resource. Use these parameters. Using VNET Whitelisting is the recommended way of building & connecting your application stack within Azure.

> NOTE: These parameters are only required when you want to use the VNet whitelisting feature for this resource.

| Parameter                        | Required for VNET Whitelisting  | Example Value                        | Description                                                         |
| -------------------------------- | ------------------------------- | ------------------------------------ | ------------------------------------------------------------------- |
| ApplicationVnetResourceGroupName | <input type="checkbox" checked> | `sharedservices-rg`                  | The ResourceGroup where your VNET, for your appservice, resides in. |
| ApplicationVnetName              | <input type="checkbox" checked> | `my-vnet-$(Release.EnvironmentName)` | The name of the VNET the appservice is in                           |
| ApplicationSubnetName            | <input type="checkbox" checked> | `app-subnet-4`                       | The name of the subnet the appservice is in                         |

# Private Endpoint Parameters

If you want to use private endpoints on your resource. Use these parameters. Private Endpoints are used for connecting to your Azure Resources from on-premises.

> NOTE: These parameters are only required when you want to use a private endpoint for this resource.

| Parameter                                       | Required for Pvt Endpoint       | Example Value                           | Description                                                                                                                       |
| ----------------------------------------------- | ------------------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| MySqlServerPrivateEndpointVnetResourceGroupName | <input type="checkbox" checked> | `sharedservices-rg`                     | The ResourceGroup where your VNET, for your MySql Server Private Endpoint, resides in.                                            |
| MySqlServerPrivateEndpointVnetName              | <input type="checkbox" checked> | `my-vnet-$(Release.EnvironmentName)`    | The name of the VNET to place the MySql Server Private Endpoint in.                                                               |
| MySqlServerPrivateEndpointSubnetName            | <input type="checkbox" checked> | `app-subnet-3`                          | The name of the subnet you want your MySql server's private endpoint to be in                                                     |
| DNSZoneResourceGroupName                        | <input type="checkbox" checked> | `MyDNSZones-$(Release.EnvironmentName)` | Make sure to use the shared DNS Zone resource group (you can only register a zone once per subscription).                         |
| MySqlServerPrivateDnsZoneName                   | <input type="checkbox" checked> | `privatelink.mysql.database.azure.com`  | The name of DNS zone where your private endpoint will be created in. If you are unsure use `privatelink.mysql.database.azure.com` |

# YAML

Be aware that this YAML example contains all parameters that can be used with this script. You'll need to pick and choose the parameters that are needed for your desired action.

```yaml
- task: AzureCLI@2
  displayName: "Create MySQL Server"
  condition: and(succeeded(), eq(variables['DeployInfra'], 'true'))
  inputs:
    azureSubscription: "${{ parameters.SubscriptionName }}"
    scriptType: pscore
    scriptPath: "$(Pipeline.Workspace)/AzDocs/MySQL/Create-MySQL-Server.ps1"
    arguments: "-MySqlServerLocation '$(MySqlServerLocation)' -MySqlServerName '$(MySqlServerName)' -MySqlServerUsername '$(MySqlServerUsername)' -MySqlServerPassword '$(MySqlServerPassword)' -MySqlServerResourceGroupName '$(MySqlServerResourceGroupName)' -MySqlServerSkuName '$(MySqlServerSkuName)' -MySqlServerStorageSizeInMB '$(MySqlServerStorageSizeInMB)' -ResourceTags $(ResourceTags) -MySqlServerMinimalTlsVersion '$(MySqlServerMinimalTlsVersion)' -MySqlServerSslEnforcement '$(MySqlServerSslEnforcement)' -ApplicationVnetResourceGroupName '$(ApplicationVnetResourceGroupName)' -ApplicationVnetName '$(ApplicationVnetName)' -ApplicationSubnetName '$(ApplicationSubnetName)' -MySqlServerPrivateEndpointVnetResourceGroupName '$(MySqlServerPrivateEndpointVnetResourceGroupName)' -MySqlServerPrivateEndpointVnetName '$(MySqlServerPrivateEndpointVnetName)' -MySqlServerPrivateEndpointSubnetName '$(MySqlServerPrivateEndpointSubnetName)' -MySqlServerPrivateDnsZoneName '$(MySqlServerPrivateDnsZoneName)' -DNSZoneResourceGroupName '$(DNSZoneResourceGroupName)' -LogAnalyticsWorkspaceResourceId '$(LogAnalyticsWorkspaceResourceId)' -DiagnosticSettingsLogs $(DiagnosticSettingsLogs) -DiagnosticSettingsDisabled $(DiagnosticSettingsDisabled)"
```

# Code

[Click here to download this script](../../../../src/MySQL/Create-MySQL-Server.ps1)

# Links

[Azure CLI - az mysql server show](https://docs.microsoft.com/en-us/cli/azure/mysql/server?view=azure-cli-latest#az_mysql_server_show)

[Azure CLI - az mysql server create](https://docs.microsoft.com/en-us/cli/azure/mysql/server?view=azure-cli-latest#az_mysql_server_create)

[Azure CLI - az network vnet show](https://docs.microsoft.com/en-us/cli/azure/network/vnet?view=azure-cli-latest#az_network_vnet_show)

[Azure CLI - az network vnet subnet show](https://docs.microsoft.com/en-us/cli/azure/network/vnet/subnet?view=azure-cli-latest#az_network_vnet_subnet_show)

[Azure CLI - az mysql server vnet-rule create](https://docs.microsoft.com/en-us/cli/azure/mysql/server/vnet-rule?view=azure-cli-latest#az_mysql_server_vnet_rule_create)

[Azure CLI - az monitor diagnostic-settings-create](https://docs.microsoft.com/nl-nl/cli/azure/monitor/diagnostic-settings?view=azure-cli-latest#az_monitor_diagnostic_settings_create)
