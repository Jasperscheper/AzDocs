[[_TOC_]]

# Description
This snippet will create a SQL Admin AD user. This is needed to enable Managed Identities (SQL Auth is not allowed).

# Parameters
| Parameter | Example Value | Description |
|--|--|--|
| AdUserName | `sql_myproject` | The username to use for this user. Use only lowercase characters and dots (.). Recommendation: prefix the username with `sql_` |
| AdPassword | `ThisIsMyC00LP@ssw0rd123!` | The password for the ad user |


# Code
[Click here to download this script](../../../../src/SQL-Server/Create-SQL-Admin.ps1)

# Links

[Azure CLI - az ad user create](https://docs.microsoft.com/en-us/cli/azure/ad/user?view=azure-cli-latest#az_ad_user_create)