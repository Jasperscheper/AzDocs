[CmdletBinding()]
param (
    [Alias("ResourceGroupName")]
    [Parameter(Mandatory)][string] $AppServiceResourceGroupName,
    [Parameter(Mandatory)][string] $AppServiceName,
    [Alias("RuleName")]
    [Parameter(Mandatory)][string] $AccessRestrictionRuleName,
    [Alias("IpRangeToWhitelist")]
    [Parameter(Mandatory, ParameterSetName = 'cidr')][ValidatePattern('^(?:(?:\d{1,3}.){3}\d{1,3})\/(?:\d{1,2})$', ErrorMessage = "The text '{0}' does not match with the CIDR notation, like '1.2.3.4/32'")][string] $CIDRToWhitelist,
    [Parameter(Mandatory, ParameterSetName = 'myIp')][switch] $WhiteListMyIp,
    [Parameter()][string] $AppServiceDeploymentSlotName,
    [Parameter()][bool] $ApplyToAllSlots = $false,
    [Parameter()][string] $AccessRestrictionAction = "Allow",
    [Parameter()][string] $Priority = 10
)

#region ===BEGIN IMPORTS===
Import-Module "$PSScriptRoot\..\AzDocs.Common" -Force
#endregion ===END IMPORTS===

Write-Header -ScopedPSCmdlet $PSCmdlet

if ($ApplyToAllSlots)
{
    $availableSlots = Invoke-Executable -AllowToFail az webapp deployment slot list --name $AppServiceName --resource-group $AppServiceResourceGroupName | ConvertFrom-Json
}

switch ($PSCmdlet.ParameterSetName)
{
    'cidr'
    {
        Add-AccessRestriction -AppType webapp -ResourceGroupName $AppServiceResourceGroupName -ResourceName $AppServiceName -AccessRestrictionRuleName $AccessRestrictionRuleName `
            -CIDRToWhiteList $CIDRToWhiteList -AccessRestrictionAction $AccessRestrictionAction -Priority $Priority -DeploymentSlotName $AppServiceDeploymentSlotName

        # Apply to all slots if desired
        foreach($availableSlot in $availableSlots)
        {
            Add-AccessRestriction -AppType webapp -ResourceGroupName $AppServiceResourceGroupName -ResourceName $AppServiceName -AccessRestrictionRuleName $AccessRestrictionRuleName `
            -CIDRToWhiteList $CIDRToWhiteList -AccessRestrictionAction $AccessRestrictionAction -Priority $Priority -DeploymentSlotName $availableSlot.name
        }
    }
    'myIp'
    {
        Add-AccessRestriction -AppType webapp -ResourceGroupName $AppServiceResourceGroupName -ResourceName $AppServiceName -AccessRestrictionRuleName $AccessRestrictionRuleName `
            -DeploymentSlotName $AppServiceDeploymentSlotName -AccessRestrictionAction $AccessRestrictionAction -Priority $Priority -WhiteListMyIp

        # Apply to all slots if desired
        foreach($availableSlot in $availableSlots)
        {
            Add-AccessRestriction -AppType webapp -ResourceGroupName $AppServiceResourceGroupName -ResourceName $AppServiceName -AccessRestrictionRuleName $AccessRestrictionRuleName `
            -DeploymentSlotName $availableSlot.name -AccessRestrictionAction $AccessRestrictionAction -Priority $Priority -WhiteListMyIp
        }
    }
}

Write-Footer -ScopedPSCmdlet $PSCmdlet