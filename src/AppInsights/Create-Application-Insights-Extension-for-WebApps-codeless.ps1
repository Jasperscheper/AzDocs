[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $appInsightsName,

    [Parameter(Mandatory)]
    [string] $appServiceName,

    [Parameter(Mandatory)]
    [string] $appServiceResourceGroupName,

    [Parameter(Mandatory)]
    [string] $appInsightsResourceGroupName,

    [Parameter()]
    [string] $AppServiceSlotName
)

#region ===BEGIN IMPORTS===
. "$PSScriptRoot\..\common\Write-HeaderFooter.ps1"
. "$PSScriptRoot\..\common\Invoke-Executable.ps1"
#endregion ===END IMPORTS===

Write-Header

# get the application insights key
$appInsightsSettings = Invoke-Executable az resource show --resource-group  $AppInsightsResourceGroupName --name $AppInsightsName --resource-type "Microsoft.Insights/components" | ConvertFrom-Json

$connectionString = $appInsightsSettings.properties.ConnectionString
$appInsightsKey = $appInsightsSettings.properties.InstrumentationKey

$additionalParameters = @()
if ($AppServiceSlotName) {
    $additionalParameters += '--slot' , $AppServiceSlotName
}


#TODO check if instrumentation key is the same as diagnostic settings (if exists)

# set the key on the web app  (codeless application insights)
Invoke-Executable az webapp config appsettings set --resource-group $appServiceResourceGroupName --name $appServiceName @additionalParameters --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey"
Invoke-Executable az webapp config appsettings set --resource-group $appServiceResourceGroupName --name $appServiceName @additionalParameters --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString"

# To turn on the Application Insights Agent extension (codeless application insights)
Invoke-Executable az webapp config appsettings set --resource-group $appServiceResourceGroupName --name $appServiceName @additionalParameters --settings "ApplicationInsightsAgent_EXTENSION_VERSION=~2"

# "recommended", but if we wanted to explicitly configure
Invoke-Executable az webapp config appsettings set --resource-group $appServiceResourceGroupName --name $appServiceName @additionalParameters --settings "XDT_MicrosoftApplicationInsights_Mode=recommended"

# turn on commands that your application runs to be visible in Application Insights
Invoke-Executable az webapp config appsettings set --resource-group $appServiceResourceGroupName --name $appServiceName @additionalParameters --settings "InstrumentationEngine_EXTENSION_VERSION=~1" "XDT_MicrosoftApplicationInsights_BaseExtensions=~1"

Write-Footer