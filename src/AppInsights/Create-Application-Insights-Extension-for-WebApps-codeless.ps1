[CmdletBinding()]
param (
    [Parameter(Mandatory)][string] $AppInsightsName,
    [Parameter(Mandatory)][string] $AppServiceName,
    [Parameter(Mandatory)][string] $AppServiceResourceGroupName,
    [Parameter(Mandatory)][string] $AppInsightsResourceGroupName,
    [Parameter()][string] $AppServiceSlotName
)

#region ===BEGIN IMPORTS===
. "$PSScriptRoot\..\common\Write-HeaderFooter.ps1"
. "$PSScriptRoot\..\common\Invoke-Executable.ps1"
. "$PSScriptRoot\..\common\AppInsights-Helper-Functions.ps1"
#endregion ===END IMPORTS===

Write-Header

# Set the AppInsights connection information on the AppService
SetAppInsightsForAppService -AppInsightsName $AppInsightsName -AppInsightsResourceGroupName $AppInsightsResourceGroupName -AppServiceName $AppServiceName -AppServiceResourceGroupName $AppServiceResourceGroupName -AppServiceSlotName $AppServiceSlotName

$additionalParameters = @()
if ($AppServiceSlotName) {
    $additionalParameters += '--slot' , $AppServiceSlotName
}

# Enable Codeless AppInsights module with optional settings. Note: this might affect performance due to heavy monitoring
Invoke-Executable az webapp config appsettings set --resource-group $AppServiceResourceGroupName --name $AppServiceName @additionalParameters --settings "ApplicationInsightsAgent_EXTENSION_VERSION=~2" "InstrumentationEngine_EXTENSION_VERSION=~1" "XDT_MicrosoftApplicationInsights_BaseExtensions=~1" "XDT_MicrosoftApplicationInsights_Mode=recommended"

Write-Footer
