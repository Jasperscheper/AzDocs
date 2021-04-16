[[_TOC_]]

# Description
You need to use a manual process to acquire a SSL certificate (Internal or External). Mostly the Service Now process is used for this. This article assumes you have gone through this process and have a .pfx at your disposal including a possible password for this file.

This code will allow you to upload/import this pfx on the given (existing) Keyvault for which you have the necessary access rights to do so. You can alter or check these rights when going to the Keyvault and click "Access Policies". Select "Add Access Policy". Select the correct permissions (or use a template) and add your bhr_  account at "Select Principal". Save.

Assuming you have the .pfx on your local disk, the easiest way is to upload this file to the Cloud Shell in the Azure Portal. From there you run below snippets (where you replace the variables with your own values. 

# Parameters
Some parameters from [General Parameter](/Azure/Azure-CLI-Snippets) list.

| Parameter | Example Value | Description |
|--|--|--|
| SharedServicesKeyvaultName | `mysharedkeyvault-$(Release.EnvironmentName)` | This is the keyvault name to use in the Shared Resources ResourceGroup. |
| PfxFilename | `mypfx.pfx` | The pfx you want to upload. |
| KeyvaultCertificateName | `mypfx` | This is the Certificate name to use in the Keyvault. |
| PfxPassword | `S0m3Amaz1n6P@ssw0rd123!` | This is the password for the pfx file |


# Code
[Click here to download this script](../../../../src/Keyvault/Upload-SSL-pfx-in-Keyvault.ps1)

# Links
- [Azure CLI - Keyvault import certificate](https://docs.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate)