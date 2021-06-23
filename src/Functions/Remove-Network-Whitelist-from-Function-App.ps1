[CmdletBinding()]
param (
    [Alias("ResourceGroupName")]
    [Parameter(Mandatory)][string] $FunctionAppResourceGroupName,
    [Parameter(Mandatory)][string] $FunctionAppName,
    [Alias("RuleName")]
    [Parameter()][string] $AccessRestrictionRuleName,
    [Parameter()][ValidatePattern('^$|^(?:(?:\d{1,3}.){3}\d{1,3})(?:\/(?:\d{1,2}))?$', ErrorMessage = "The text '{0}' does not match with the CIDR notation, like '1.2.3.4/32'")][string] $CIDRToRemoveFromWhitelist,
    [Parameter()][string] $FunctionAppDeploymentSlotName,
    [Parameter()][bool] $ApplyToAllSlots = $false,
    [Parameter()][bool] $ApplyToMainEntrypoint = $true,
    [Parameter()][bool] $ApplyToScmEntrypoint = $true,
    [Parameter()][string] $SubnetToRemoveSubnetName,
    [Parameter()][string] $SubnetToRemoveVnetName,
    [Parameter()][string] $SubnetToRemoveVnetResourceGroupName
)

#region ===BEGIN IMPORTS===
Import-Module "$PSScriptRoot\..\AzDocs.Common" -Force
#endregion ===END IMPORTS===

Write-Header -ScopedPSCmdlet $PSCmdlet

# Confirm if the correct parameters are passed
Confirm-ParametersForWhitelist -CIDR:$CIDRToRemoveFromWhitelist -SubnetName:$SubnetToRemoveSubnetName -VnetName:$SubnetToRemoveVnetName -VnetResourceGroupName:$SubnetToRemoveVnetResourceGroupName

# Autogenerate CIDR if no CIDR or Subnet is passed
$autoGeneratedAccessRestrictionRuleName = $false

if (!$AccessRestrictionRuleName)
{
    $CIDRToRemoveFromWhitelist = Get-CIDRForWhitelist -CIDR:$CIDRToRemoveFromWhitelist -CIDRSuffix '/32' -SubnetName:$SubnetToRemoveSubnetName -VnetName:$SubnetToRemoveVnetName -VnetResourceGroupName:$SubnetToRemoveVnetResourceGroupName
    $CIDRToRemoveFromWhitelist = Confirm-CIDRForWhitelist -ServiceType 'functionapp' -CIDR:$CIDRToRemoveFromWhitelist
    $autoGeneratedAccessRestrictionRuleName = $true
}

# Fetch Subnet ID when subnet option is given.
if ($SubnetToRemoveSubnetName -and $SubnetToRemoveVnetName -and $SubnetToRemoveVnetResourceGroupName)
{
    $subnetResourceId = (Invoke-Executable az network vnet subnet show --resource-group $SubnetToRemoveVnetResourceGroupName --name $SubnetToRemoveSubnetName --vnet-name $SubnetToRemoveVnetName | ConvertFrom-Json).id
}

if ($ApplyToAllSlots)
{
    $availableSlots = Invoke-Executable -AllowToFail az functionapp deployment slot list --name $FunctionAppName --resource-group $FunctionAppResourceGroupName | ConvertFrom-Json
    if ($FunctionAppDeploymentSlotName)
    {
        $availableSlots = $availableSlots | Where-Object { $_.name -ne $FunctionAppDeploymentSlotName }
    }
}

Remove-AccessRestrictionIfExists -AppType functionapp -ResourceGroupName $FunctionAppResourceGroupName -ResourceName $FunctionAppName -AutoGeneratedAccessRestrictionRuleName:$autoGeneratedAccessRestrictionRuleName -AccessRestrictionRuleName:$AccessRestrictionRuleName -CIDR:$CIDRToRemoveFromWhitelist -SubnetResourceId:$subnetResourceId -DeploymentSlotName $FunctionAppDeploymentSlotName -ApplyToMainEntrypoint $ApplyToMainEntrypoint -ApplyToScmEntrypoint $ApplyToScmEntrypoint

# Apply to all slots if desired
foreach ($availableSlot in $availableSlots)
{
    Remove-AccessRestrictionIfExists -AppType functionapp -ResourceGroupName $FunctionAppResourceGroupName -ResourceName $FunctionAppName -AutoGeneratedAccessRestrictionRuleName:$autoGeneratedAccessRestrictionRuleName -AccessRestrictionRuleName:$AccessRestrictionRuleName -CIDR:$CIDRToRemoveFromWhitelist -SubnetResourceId:$subnetResourceId -DeploymentSlotName $availableSlot.name -ApplyToMainEntrypoint $ApplyToMainEntrypoint -ApplyToScmEntrypoint $ApplyToScmEntrypoint
}

Write-Footer -ScopedPSCmdlet $PSCmdlet