[[_TOC_]]

# Description

This snippet will whitelist the specified IP Range from the Azure Database for MySQL server. If you leave the `CIDRToWhitelist` parameter empty, it will use the outgoing IP from where you execute this script.

# Parameters

| Parameter                              | Required                        | Example Value                               | Description                                                                                                                                                                                                                               |
| -------------------------------------- | ------------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MySqlServerResourceGroupName           | <input type="checkbox" checked> | `myteam-testapi-$(Release.EnvironmentName)` | The name of the resource group the MySQL Server is in.                                                                                                                                                                                    |
| MySqlServerName                        | <input type="checkbox" checked> | `somemysqlserver$(Release.EnvironmentName)` | The name for the MySQL Server resource. It's recommended to use just alphanumerical characters without hyphens etc.                                                                                                                       |
| AccessRuleName                         | <input type="checkbox">         | `company hq`                                | You can override the name for this accessrule. If you leave this empty, the `CIDRToWhitelist` will be used for the naming (automatically). We recommend to leave this empty for ephemeral whitelists like Azure DevOps Hosted Agent ip's. |
| CIDRToWhitelist                        | <input type="checkbox">         | `52.43.65.123/32`                           | IP range in [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) notation that should be whitelisted. If you leave this value empty, it will whitelist the machine's ip where you're running the script from.             |
| SubnetToWhitelistSubnetName            | <input type="checkbox">         | `gateway2-subnet`                           | The name of the subnet you want to get whitelisted.                                                                                                                                                                                       |
| SubnetToWhitelistVnetName              | <input type="checkbox">         | `sp-dc-dev-001-vnet`                        | The vnetname of the subnet you want to get whitelisted.                                                                                                                                                                                   |
| SubnetToWhitelistVnetResourceGroupName | <input type="checkbox">         | `sharedservices-rg`                         | The VnetResourceGroupName your Vnet resides in.                                                                                                                                                                                           |
| ForcePublic                            | <input type="checkbox">         | n.a.                                        | If you are not using any networking settings, you need to pass this boolean to confirm you are willingly creating a public resource (to avoid unintended public resources). You can pass it as a switch without a value (`-ForcePublic`). |

# YAML

Be aware that this YAML example contains all parameters that can be used with this script. You'll need to pick and choose the parameters that are needed for your desired action.

```yaml
- task: AzureCLI@2
  displayName: "Add Network Whitelist to MySQL"
  condition: and(succeeded(), eq(variables['DeployInfra'], 'true'))
  inputs:
    azureSubscription: "${{ parameters.SubscriptionName }}"
    scriptType: pscore
    scriptPath: "$(Pipeline.Workspace)/AzDocs/MySQL/Add-Network-Whitelist-to-MySQL.ps1"
    arguments: "-MySqlServerName '$(MySqlServerName)' -MySqlServerResourceGroupName '$(MySqlServerResourceGroupName)' -AccessRuleName '$(AccessRuleName)' -CIDRToWhitelist '$(CIDRToWhitelist)' -SubnetToWhitelistSubnetName '$(SubnetToWhitelistSubnetName)' -SubnetToWhitelistVnetName '$(SubnetToWhitelistVnetName)' -SubnetToWhitelistVnetResourceGroupName '$(SubnetToWhitelistVnetResourceGroupName)'"
```

# Code

[Click here to download this script](../../../../src/MySQL/Add-IP-Whitelist-to-MySQL.ps1)

# Links

[Azure CLI - az mysql server firewall-rule create](https://docs.microsoft.com/nl-nl/cli/azure/mysql/server/firewall-rule?view=azure-cli-latest#az_mysql_server_firewall_rule_create)
