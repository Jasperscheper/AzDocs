[CmdletBinding(DefaultParameterSetName = 'default')]
param (
    [Parameter(Mandatory)][string] $AppServicePlanName,
    [Parameter(Mandatory)][string] $AppServicePlanResourceGroupName,    
    [Parameter(Mandatory)][string] $AppServiceResourceGroupName,
    [Parameter(Mandatory)][string] $AppServiceName,
    [Parameter(Mandatory)][string] $AppServiceDiagnosticsName,
    [Alias("LogAnalyticsWorkspaceName")]
    [Parameter(Mandatory)][string] $LogAnalyticsWorkspaceResourceId,
    [Parameter(Mandatory, ParameterSetName = 'default')][Parameter(Mandatory, ParameterSetName = 'DeploymentSlot')][string] $AppServiceRunTime,
    [Parameter()][string] $AppServiceNumberOfInstances = 2,
    [Parameter(Mandatory)][System.Object[]] $ResourceTags,
    
    # Deployment Slots
    [Parameter(ParameterSetName = 'DeploymentSlot')][switch] $EnableAppServiceDeploymentSlot,
    [Parameter(ParameterSetName = 'DeploymentSlot')][string] $AppServiceDeploymentSlotName = 'staging',
    [Parameter(ParameterSetName = 'DeploymentSlot')][bool] $DisablePublicAccessForAppServiceDeploymentSlot = $true,

    # Use container image name with optional tag for example thelastpickle/cassandra-reaper:latest
    [Parameter(Mandatory, ParameterSetName = 'Container')][string] $ContainerImageName,

    # VNET Whitelisting Parameters
    [Parameter()][string] $GatewayVnetResourceGroupName,
    [Parameter()][string] $GatewayVnetName,
    [Parameter()][string] $GatewaySubnetName,
    [Parameter()][string] $GatewayWhitelistRulePriority = 20,

    # Private Endpoint
    [Alias("VnetResourceGroupName")]
    [Parameter()][string] $AppServicePrivateEndpointVnetResourceGroupName,
    [Alias("VnetName")]
    [Parameter()][string] $AppServicePrivateEndpointVnetName,
    [Alias("ApplicationPrivateEndpointSubnetName")]
    [Parameter()][string] $AppServicePrivateEndpointSubnetName,
    [Parameter()][string] $DNSZoneResourceGroupName,
    [Alias("PrivateDnsZoneName")]
    [Parameter()][string] $AppServicePrivateDnsZoneName = "privatelink.azurewebsites.net",

    # Optional remaining arguments. This is a fix for being able to pass down parameters in an easy way using @PSBoundParameters in Create-Web-App-with-App-Service-Plan-Linux.ps1
    [Parameter(ValueFromRemainingArguments)][string[]] $Remaining
)

#region ===BEGIN IMPORTS===
Import-Module "$PSScriptRoot\..\AzDocs.Common" -Force
#endregion ===END IMPORTS===

Write-Header -ScopedPSCmdlet $PSCmdlet

# Fetch AppService Plan ID
$appServicePlanId = (Invoke-Executable az appservice plan show --resource-group $AppServicePlanResourceGroupName --name $AppServicePlanName | ConvertFrom-Json).id

#adding additional parameters
$optionalParameters = @()

if ($ContainerImageName)
{
    $optionalParameters += '--deployment-container-image-name', "$ContainerImageName"
}

if ($AppServiceRunTime)
{
    $optionalParameters += '--runtime', "$AppServiceRunTime"
}

# Create AppService
Invoke-Executable az webapp create --name $AppServiceName --plan $appServicePlanId --resource-group $AppServiceResourceGroupName --tags ${ResourceTags} @optionalParameters

# Fetch the ID from the AppService
$webAppId = (Invoke-Executable az webapp show --name $AppServiceName --resource-group $AppServiceResourceGroupName | ConvertFrom-Json).id

# Disable HTTPS
Invoke-Executable az webapp update --ids $webAppId --https-only true

# Disable FTPS
Invoke-Executable az webapp config set --ids $webAppId --ftps-state Disabled

# Set number of instances
Invoke-Executable az webapp config set --ids $webAppId --number-of-workers $AppServiceNumberOfInstances

# Set logging to FileSystem
Invoke-Executable az webapp log config --ids $webAppId --detailed-error-messages true --docker-container-logging filesystem --failed-request-tracing true --level warning --web-server-logging filesystem

#  Create diagnostics settings
Invoke-Executable az monitor diagnostic-settings create --resource $webAppId --name $AppServiceDiagnosticsName --workspace $LogAnalyticsWorkspaceResourceId --logs "[{ 'category': 'AppServiceHTTPLogs', 'enabled': true }, { 'category': 'AppServiceConsoleLogs', 'enabled': true }, { 'category': 'AppServiceAppLogs', 'enabled': true }, { 'category': 'AppServiceFileAuditLogs', 'enabled': true }, { 'category': 'AppServiceIPSecAuditLogs', 'enabled': true }, { 'category': 'AppServicePlatformLogs', 'enabled': true }, { 'category': 'AppServiceAuditLogs', 'enabled': true } ]".Replace("'", '\"') --metrics "[ { 'category': 'AllMetrics', 'enabled': true } ]".Replace("'", '\"')

# Create & Assign WebApp identity to AppService
Invoke-Executable az webapp identity assign --ids $webAppId

if ($EnableAppServiceDeploymentSlot)
{
    Invoke-Executable az webapp deployment slot create --resource-group $AppServiceResourceGroupName --name $AppServiceName --slot $AppServiceDeploymentSlotName
    $webAppStagingId = (Invoke-Executable az webapp show --name $AppServiceName --resource-group $AppServiceResourceGroupName --slot $AppServiceDeploymentSlotName | ConvertFrom-Json).id
    Invoke-Executable az webapp config set --ids $webAppStagingId --ftps-state Disabled --slot $AppServiceDeploymentSlotName
    Invoke-Executable az webapp config set --ids $webAppStagingId --number-of-workers $AppServiceNumberOfInstances --slot $AppServiceDeploymentSlotName
    Invoke-Executable az webapp log config --ids $webAppStagingId --detailed-error-messages true --docker-container-logging filesystem --failed-request-tracing true --level warning --web-server-logging filesystem --slot $AppServiceDeploymentSlotName
    Invoke-Executable az webapp identity assign --ids $webAppStagingId --slot $AppServiceDeploymentSlotName
    
    if ($DisablePublicAccessForAppServiceDeploymentSlot)
    {
        $accessRestrictionRuleName = 'DisablePublicAccess'
        $restrictions = Invoke-Executable az webapp config access-restriction show --resource-group $AppServiceResourceGroupName --name $AppServiceName --slot $AppServiceDeploymentSlotName | ConvertFrom-Json
        
        if (!($restrictions.scmIpSecurityRestrictions | Where-Object { $_.Name -eq $accessRestrictionRuleName }))
        {
            Invoke-Executable az webapp config access-restriction add --resource-group $AppServiceResourceGroupName --name $AppServiceName --action Deny --priority 100000 --description $AppServiceName --rule-name $accessRestrictionRuleName --ip-address '0.0.0.0/0' --scm-site $true --slot $AppServiceDeploymentSlotName
        }

        if (!($restrictions.ipSecurityRestrictions | Where-Object { $_.Name -eq $accessRestrictionRuleName }))
        {
            Invoke-Executable az webapp config access-restriction add --resource-group $AppServiceResourceGroupName --name $AppServiceName --action Deny --priority 100000 --description $AppServiceName --rule-name $accessRestrictionRuleName --ip-address '0.0.0.0/0' --scm-site $false --slot $AppServiceDeploymentSlotName
        }
    }
}

# VNET Whitelisting
if($GatewayVnetResourceGroupName -and $GatewayVnetName -and $GatewaySubnetName)
{
    # Fetch the Subnet ID where the Application Resides in
    $gatewaySubnetId = (Invoke-Executable az network vnet subnet show --resource-group $GatewayVnetResourceGroupName --name $GatewaySubnetName --vnet-name $GatewayVnetName | ConvertFrom-Json).id

    # Make sure the service endpoint is enabled for the subnet (for internal routing)
    Set-SubnetServiceEndpoint -SubnetResourceId $gatewaySubnetId -ServiceEndpointServiceIdentifier "Microsoft.Web"

    # Allow the Gateway Subnet to this AppService through a vnet-rule
    $firewallRuleName = ToMd5Hash -InputString "$($GatewayVnetName)_$($GatewaySubnetName)_allow"
    if (!((az webapp config access-restriction show --resource-group $AppServiceResourceGroupName --name $AppServiceName | ConvertFrom-Json).ipSecurityRestrictions | Where-Object { $_.name -eq $firewallRuleName }))
    {
        Invoke-Executable az webapp config access-restriction add --resource-group $AppServiceResourceGroupName --name $AppServiceName --rule-name $firewallRuleName --action Allow --subnet $gatewaySubnetId --priority $GatewayWhitelistRulePriority
    }
}

# Add private endpoint & Setup Private DNS
if($AppServicePrivateEndpointVnetResourceGroupName -and $AppServicePrivateEndpointVnetName -and $AppServicePrivateEndpointSubnetName -and $DNSZoneResourceGroupName -and $AppServicePrivateDnsZoneName)
{
    # Fetch needed information
    $vnetId = (Invoke-Executable az network vnet show --resource-group $AppServicePrivateEndpointVnetResourceGroupName --name $AppServicePrivateEndpointVnetName | ConvertFrom-Json).id
    $applicationPrivateEndpointSubnetId = (Invoke-Executable az network vnet subnet show --resource-group $AppServicePrivateEndpointVnetResourceGroupName --name $AppServicePrivateEndpointSubnetName --vnet-name $AppServicePrivateEndpointVnetName | ConvertFrom-Json).id
    $appServicePrivateEndpointName = "$($AppServiceName)-pvtapp"

    # Add private endpoint & Setup Private DNS
    Add-PrivateEndpoint -PrivateEndpointVnetId $vnetId -PrivateEndpointSubnetId $applicationPrivateEndpointSubnetId -PrivateEndpointName $appServicePrivateEndpointName -PrivateEndpointResourceGroupName $AppServiceResourceGroupName -TargetResourceId $webAppId -PrivateEndpointGroupId sites -DNSZoneResourceGroupName $DNSZoneResourceGroupName -PrivateDnsZoneName $AppServicePrivateDnsZoneName -PrivateDnsLinkName "$($AppServicePrivateEndpointVnetName)-appservice"
}

Write-Footer -ScopedPSCmdlet $PSCmdlet