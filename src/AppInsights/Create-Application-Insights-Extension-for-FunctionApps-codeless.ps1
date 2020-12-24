[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $AppInsightsName,

    [Parameter(Mandatory)]
    [string] $AppInsightsResourceGroupName,

    [Parameter(Mandatory)]
    [string] $FunctionAppName,

    [Parameter(Mandatory)]
    [string] $FunctionAppResourceGroupName,

    [Parameter()]
    [string] $AppServiceSlotName
)

#region ===BEGIN IMPORTS===
. "$PSScriptRoot\..\common\Write-HeaderFooter.ps1"
. "$PSScriptRoot\..\common\Invoke-Executable.ps1"
#endregion ===END IMPORTS===

Write-Header

$additionalParameters = @()
if ($AppServiceSlotName) {
    $additionalParameters += '--slot' , $AppServiceSlotName
}

# get the application insights key
$appInsightsSettings = Invoke-Executable az resource show --resource-group  $AppInsightsResourceGroupName --name $AppInsightsName --resource-type "Microsoft.Insights/components" | ConvertFrom-Json

$connectionString = $appInsightsSettings.properties.ConnectionString
$appInsightsKey = $appInsightsSettings.properties.InstrumentationKey
# set the key on the web app  (codeless application insights)
Invoke-Executable az functionapp config appsettings set --name $FunctionAppName --resource-group $FunctionAppResourceGroupName @additionalParameters --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey"
Invoke-Executable az functionapp config appsettings set --name $FunctionAppName --resource-group $FunctionAppResourceGroupName @additionalParameters --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString"
Invoke-Executable az functionapp config appsettings set --name $FunctionAppName --resource-group $FunctionAppResourceGroupName @additionalParameters --settings "ApplicationInsightsAgent_EXTENSION_VERSION=~2"

Write-Footer