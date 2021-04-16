[[_TOC_]]

# Description
This snippet will create a fileshare inside a specified (pre-existing) storageaccount.

# Parameters
Some parameters from [General Parameter](/Azure/Azure-CLI-Snippets) list.

| Parameter | Example Value | Description |
|--|--|--|
| FileshareStorageAccountResourceGroupname | `MyTeam-TestApi-$(Release.EnvironmentName)` | The resourcegroup where the storageaccount resides in |
| FileshareStorageAccountName | `myteststgaccount$(Release.EnvironmentName)` | The name of the storageaccount which will be used |
| FileshareName | `images` | The name of the fileshare |
| FileshareVnetName | `my-vnet-$(Release.EnvironmentName)` | The name of the VNET to use for creating the Fileshare in. |
| FileshareVnetResourceGroupName | `sharedservices-rg` | The ResourceGroup where the Fileshare VNET resides in. |
| SubnetToWhitelistOnStorageAccount | `app-subnet-4` | The name for the subnet to whitelist on the storage account. |
| FileshareStorageAccountIsInVnet | n.a. | If you pass this switch (as `-storageAccountIsInVnet` without any value) it will make sure the subnet (you need to whitelist your Azure DevOps subnet before you can create a fileshare in a private storage account) agent is whitelisted. |

# Code
[Click here to download this script](../../../../src/Storage-Accounts/Create-Fileshare-in-Storageaccount.ps1)

# Links

[Azure CLI - az storage share create](https://docs.microsoft.com/en-us/cli/azure/storage/share?view=azure-cli-latest#az_storage_share_create)