#region Helper functions

<#
.SYNOPSIS
    Add Access restriction to app service and/or function app
.DESCRIPTION
    Add Access restriction to app service and/or function app
#>
function Add-AccessRestriction
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] [ValidateSet('functionapp', 'webapp')]$AppType,
        [Parameter(Mandatory)][string] $ResourceGroupName,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter()][string] $AccessRestrictionRuleDescription,
        [Parameter()][string] $DeploymentSlotName,
        [Parameter()][string] $AccessRestrictionAction = "Allow",
        [Parameter()][string] $Priority = 10,
        [Parameter()][string] $AccessRestrictionRuleName,
        [Parameter(Mandatory)][bool] $AutoGeneratedAccessRestrictionRuleName,
        [Parameter()][ValidatePattern('^$|^(?:(?:\d{1,3}.){3}\d{1,3})(?:\/(?:\d{1,2}))?$', ErrorMessage = "The text '{0}' does not match with the CIDR notation, like '1.2.3.4/32'")][string] $CIDR,
        [Parameter()][string] $SubnetResourceId,
        [Parameter()][bool] $ApplyToMainEntrypoint = $true,
        [Parameter()][bool] $ApplyToScmEntrypoint = $true
    )

    Write-Header -ScopedPSCmdlet $PSCmdlet

    # If CIDRToWhitelist is empty AND SubnetResourceId is empty, something went wrong.
    Confirm-CIDRorSubnetResourceIdOrAccessRuleNameNotEmpty -CIDR $CIDR -SubnetResourceId $SubnetResourceId -AccessRestrictionRuleName $AccessRestrictionRuleName
    
    # fill parameters
    $optionalParameters = @()
    if ($CIDR)
    {
        $optionalParameters += "--ip-address", "$CIDR"
    }
    elseif ($SubnetResourceId)
    {
        $optionalParameters += "--subnet", "$SubnetResourceId"
    }
   
    if ($DeploymentSlotName)
    {
        $optionalParameters += "--slot", "$DeploymentSlotName"
    }
    
    if ($AccessRestrictionRuleDescription)
    {
        $optionalParameters += "--description", "$AccessRestrictionRuleDescription"
    }

    # Check and remove access restriction if it already exists
    Remove-AccessRestrictionIfExists -AppType $AppType -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ApplyToMainEntryPoint $ApplyToMainEntryPoint -ApplyToScmEntryPoint $ApplyToScmEntryPoint -CIDR:$CIDR -SubnetResourceId:$subnetResourceId -DeploymentSlotName:$DeploymentSlotName -AccessRestrictionRuleName:$AccessRestrictionRuleName -AutoGeneratedAccessRestrictionRuleName:$AutoGeneratedAccessRestrictionRuleName -AccessRestrictionAction:$AccessRestrictionAction
    
    # SCM entrypoint
    if ($ApplyToScmEntrypoint)
    {
        Invoke-Executable az $AppType config access-restriction add --resource-group $ResourceGroupName --name $ResourceName --action $AccessRestrictionAction --priority $Priority --rule-name $AccessRestrictionRuleName --scm-site $true @optionalParameters
    }

    # Main entrypoint
    if ($ApplyToMainEntrypoint)
    {
        Invoke-Executable az $AppType config access-restriction add --resource-group $ResourceGroupName --name $ResourceName --action $AccessRestrictionAction --priority $Priority --rule-name $AccessRestrictionRuleName --scm-site $false @optionalParameters
    }

    Write-Footer -ScopedPSCmdlet $PSCmdlet
}

<#
.SYNOPSIS
    Remove access restriction from app service and/or function app if it exists
.DESCRIPTION
    Remove access restriction from app service and/or function app if it exists
#>
function Remove-AccessRestrictionIfExists
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] [ValidateSet('functionapp', 'webapp')]$AppType,
        [Parameter(Mandatory)][string] $ResourceGroupName,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter()][string] $AccessRestrictionRuleName,
        [Parameter(Mandatory)][bool] $AutoGeneratedAccessRestrictionRuleName,
        [Parameter()][string] $CIDR,
        [Parameter()][string] $SubnetResourceId,
        [Parameter()][string] $DeploymentSlotName,
        [Parameter()][bool] $ApplyToMainEntrypoint = $true,
        [Parameter()][bool] $ApplyToScmEntrypoint = $true,
        [Parameter()][string] $AccessRestrictionAction
    )

    Write-Header -ScopedPSCmdlet $PSCmdlet

    Confirm-CIDRorSubnetResourceIdOrAccessRuleNameNotEmpty -CIDR $CIDR -SubnetResourceId $SubnetResourceId -AccessRestrictionRuleName $AccessRestrictionRuleName

    $optionalParameters = @()
    # Accessrule whenever its not autogenerated
    if (!$AutoGeneratedAccessRestrictionRuleName)
    {
        $optionalParameters += "--rule-name", "$AccessRestrictionRuleName"
    }

    # CIDR / Subnet
    if ($CIDR)
    {
        $optionalParameters += "--ip-address", "$CIDR"
    }
    elseif ($SubnetResourceId)
    {
        $optionalParameters += "--subnet", "$SubnetResourceId"
    }

    # Deploymentslot
    if ($DeploymentSlotName)
    {
        $optionalParameters += "--slot", "$DeploymentSlotName"
    }

    $resultConfirmationSCM = Confirm-AccessRestriction -AppType $AppType -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -SecurityRestrictionObjectName "scmIpSecurityRestrictions" -AccessRestrictionRuleName:$AccessRestrictionRuleName -CIDR:$CIDR -SubnetResourceId:$SubnetResourceId -DeploymentSlotName:$DeploymentSlotName -AutoGeneratedAccessRestrictionRuleName:$AutoGeneratedAccessRestrictionRuleName
    foreach ($result in $resultConfirmationSCM)
    {
        if ($ApplyToScmEntrypoint -and $result.Exists)
        {
            if (!$AccessRestrictionAction)
            {
                $AccessRestrictionAction = $result.Action
            }
            Invoke-Executable az $AppType config access-restriction remove --resource-group $ResourceGroupName --name $ResourceName --action $AccessRestrictionAction --scm-site $true @optionalParameters
        }
    }

    # Main entrypoint
    $resultConfirmationMainEntrypoint = Confirm-AccessRestriction -AppType $AppType -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -SecurityRestrictionObjectName "ipSecurityRestrictions" -AccessRestrictionRuleName:$AccessRestrictionRuleName -CIDR:$CIDR -SubnetResourceId:$SubnetResourceId -DeploymentSlotName:$DeploymentSlotName -AutoGeneratedAccessRestrictionRuleName:$AutoGeneratedAccessRestrictionRuleName
    foreach ($result in $resultConfirmationMainEntryPoint)
    {
        if ($ApplyToMainEntrypoint -and $result.Exists)
        {
            if (!$AccessRestrictionAction)
            {
                $AccessRestrictionAction = $result.Action
            }
    
            Invoke-Executable az $AppType config access-restriction remove --resource-group $ResourceGroupName --name $ResourceName --action $AccessRestrictionAction --scm-site $false @optionalParameters
        }
    }
}

<#
.SYNOPSIS
    Check if Access restrictions exist on app service and/or function app
.DESCRIPTION
    Check if Access restrictions exist on app service and/or function app
#>
function Confirm-AccessRestriction
{  
    param (
        [Parameter(Mandatory)][string] [ValidateSet('functionapp', 'webapp')] $AppType,
        [Parameter(Mandatory)][string] $ResourceGroupName,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter()][string] $AccessRestrictionRuleName,
        [Parameter(Mandatory)][bool] $AutoGeneratedAccessRestrictionRuleName,
        [Parameter()][string] $CIDR,
        [Parameter()][string] $SubnetResourceId,
        [Parameter(Mandatory)][ValidateSet("ipSecurityRestrictions", "scmIpSecurityRestrictions")][string] $SecurityRestrictionObjectName,
        [Parameter()][string] $DeploymentSlotName,
        [Parameter()][bool] $ApplyToScmEntryPoint = $true,
        [Parameter()][bool] $ApplyToMainEntryPoint = $true
    )

    Write-Header -ScopedPSCmdlet $PSCmdlet

    function ValidateResult
    {
        Confirm-CIDRorSubnetResourceIdOrAccessRuleNameNotEmpty -CIDR $CIDR -SubnetResourceId $SubnetResourceId -AccessRestrictionRuleName $AccessRestrictionRuleName

        $optionalParameters = @()
        if ($DeploymentSlotName)
        {
            $optionalParameters += "--slot", "$DeploymentSlotName"
        }

        $result = @()
        $accessRestrictions = Invoke-Executable az $AppType config access-restriction show --resource-group $ResourceGroupName --name $ResourceName @optionalParameters | ConvertFrom-Json
        if ($AutoGeneratedAccessRestrictionRuleName)
        {
            if ($CIDR)
            {
                Write-Host "Checking for CIDR $CIDR"
                $matchingCIDR = $accessRestrictions.$SecurityRestrictionObjectName | Where-Object { $_.ip_address -eq $CIDR }
                if ($matchingCIDR.Length -gt 0)
                {
                    Write-Host "Access restriction for type $SecurityRestrictionObjectName exists for $CIDR with action "$matchingCIDR.action", continueing."
                
                    $resultObject = [PSCustomObject]@{
                        Exists = $true
                        Action = $matchingCIDR.action
                    }
                    $result += $resultObject
                    return $result
                }
                else
                {
                    Write-Host "Access restriction for type $SecurityRestrictionObjectName does not exist for $CIDR."
                    $resultObject = [PSCustomObject]@{
                        Exists = $false
                        Action = $null
                    }
                    $result += $resultObject
                    return $result
                }
            }
            elseif ($SubnetResourceId)
            {
                Write-Host "Checking for subnet with $SubnetResourceId"
                $matchingSubnets = $accessRestrictions.$SecurityRestrictionObjectName | Where-Object { $_.vnet_subnet_resource_id -eq $SubnetResourceId }
                if ($matchingSubnets.Length -gt 0)
                {
                    foreach ($matchingSubnet in $matchingSubnets)
                    {
                        Write-Host "Access restriction for type $SecurityRestrictionObjectName exists for $SubnetResourceId with action "$matchingSubnet.action", continueing"
                        $resultObject = [PSCustomObject]@{
                            Exists = $true
                            Action = $matchingSubnet.action
                        }
                        $result += $resultObject
                    }
                    return $result
                }
                else
                {
                    Write-Host "Access restriction for type $SecurityRestrictionObjectName does not exist for $SubnetResourceId."
                    $resultObject = [PSCustomObject]@{
                        Exists = $false
                        Action = $null
                    }
                    $result += $resultObject
                    return $result
                }
            }
        }

        # AccessRestrictionRuleName is known
        if ($CIDR)
        {
            $matchingCIDR = $accessRestrictions.$SecurityRestrictionObjectName | Where-Object { $_.Name -eq $AccessRestrictionRuleName -and $_.ip_address -eq $CIDR }
            if ($matchingCIDR.Length -gt 0)
            {
                Write-Host "Access restriction for type $SecurityRestrictionObjectName exists for $AccessRestrictionRuleName and $CIDR with action "$matchingCIDR.action", continueing"
                $resultObject = [PSCustomObject]@{
                    Exists = $true
                    Action = $matchingCIDR.action
                }
                $result += $resultObject
                return $result
            }
            else
            {
                Write-Host "Access restriction for type $SecurityRestrictionObjectName does not exist for $AccessRestrictionRuleName and $CIDR."
                $resultObject = [PSCustomObject]@{
                    Exists = $false
                    Action = $null
                }
                $result += $resultObject
                return $result
            }
        }
        elseif ($SubnetResourceId)
        {
            $matchingSubnets = $accessRestrictions.$SecurityRestrictionObjectName | Where-Object { $_.Name -eq $AccessRestrictionRuleName -and $_.vnet_subnet_resource_id -eq $SubnetResourceId }
            if ($matchingSubnet.Length -gt 0)
            {
                foreach ($matchingSubnet in $matchingSubnets)
                {
                    Write-Host "Access restriction for type $SecurityRestrictionObjectName exists for $AccessRestrictionRuleName and $SubnetResourceId with action "$matchingSubnet.action", continueing"
                    $resultObject = [PSCustomObject]@{
                        Exists = $true
                        Action = $matchingSubnet.action
                    }
                    $result += $resultObject
                }
                return $result
            }
            else
            {
                Write-Host "Access restriction for type $SecurityRestrictionObjectName does not exist for $AccessRestrictionRuleName and $SubnetResourceId."
                $resultObject = [PSCustomObject]@{
                    Exists = $false
                    Action = $null
                }
                $result += $resultObject
                return $result
            }
        }
        else
        {
            $matchingNames = $accessRestrictions.$SecurityRestrictionObjectName | Where-Object { $_.Name -eq $AccessRestrictionRuleName }
            if ($matchingNames.Length -gt 0)
            {
                foreach ($matchingName in $matchingNames)
                {
                    Write-Host "Access restriction for type $SecurityRestrictionObjectName exists for $AccessRestrictionRuleName witch action "$matchingName.action", continueing"
                
                    $resultObject = [PSCustomObject]@{
                        Exists = $true
                        Action = $matchingName.action
                    }
                    $result += $resultObject
                }
                return $result
            }
            else
            {
                Write-Host "Access restriction for type $SecurityRestrictionObjectName does not exist for $AccessRestrictionRuleName."
                $resultObject = [PSCustomObject]@{
                    Exists = $false
                    Action = $null
                }
                $result += $resultObject
                return $result
            }
        }
    }

    $returnValue = ValidateResult
    Write-Output $returnValue
    Write-Footer -ScopedPSCmdlet $PSCmdlet
}

#endregion

#region Whitelist helper functions MySql/PostgreSql/SqlServer 

<#
.SYNOPSIS
    Remove firewall rules from mysql/postgres/sql server if it exists
.DESCRIPTION
    Remove firewall rules from mysql/postgres/sql server if it exists
#>
function Remove-FirewallRulesIfExists
{    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] [ValidateSet('mysql', 'postgres', 'sql')]$ServiceType,
        [Parameter(Mandatory)][string] $ResourceGroupName,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter()][string] $AccessRuleName, 
        [Parameter()][ValidatePattern('^$|^(?:(?:\d{1,3}.){3}\d{1,3})(?:\/(?:\d{1,2}))?$', ErrorMessage = "The text '{0}' does not match with the CIDR notation, like '1.2.3.4/32'")][string] $CIDR
    )

    Write-Header -ScopedPSCmdlet $PSCmdlet

    $parameters = @()
    if ($ServiceType -eq 'sql')
    {
        $parameters += '--server', "$ResourceName"
    }
    else
    {
        $parameters += '--server-name', "$ResourceName"
    }

    $matchedFirewallRules = [Collections.Generic.List[string]]::new()
    $firewallRules = Invoke-Executable az $ServiceType server firewall-rule list --resource-group $ResourceGroupName @parameters | ConvertFrom-Json
    if ($AccessRuleName)
    {
        $matchingFirewallRules = $firewallRules | Where-Object { $_.name -eq $AccessRuleName }
        if ($matchingFirewallRules)
        {
            $matchedFirewallRules.Add($AccessRuleName)
        }
    }
    else
    {
        $startIpAddress = Get-StartIpInIpv4Network -SubnetCidr $CIDR
        $endIpAddress = Get-EndIpInIpv4Network -SubnetCidr $CIDR
        $matchingFirewallRules = $firewallRules | Where-Object { $_.startIpAddress -eq $startIpAddress -and $_.endIpAddress -eq $endIpAddress }
        if ($matchingFirewallRules)
        {
            foreach ($matchingFirewallRule in $matchingFirewallRules)
            {
                $matchedFirewallRules.Add($matchingFirewallRule.name)
            }
        }
    }

    if (!($ServiceType -eq 'sql'))
    {
        $parameters += '--yes'
    }

    # Remove firewall rules
    foreach ($ruleName in $matchedFirewallRules) 
    {
        Write-Host "Removing whitelist for $ruleName."
        Invoke-Executable az $ServiceType server firewall-rule delete --resource-group $ResourceGroupName --name $ruleName @parameters
    }

    Write-Footer -ScopedPSCmdlet $PSCmdlet
}

<#
.SYNOPSIS
    Remove vnet rules from mysql/postgres/sql server if it exists
.DESCRIPTION
    Remove vnet rules from mysql/postgres/sql server if it exists
#>
function Remove-VnetRulesIfExists
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] [ValidateSet('mysql', 'postgres', 'sql')]$ServiceType,
        [Parameter(Mandatory)][string] $ResourceGroupName,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter()][string] $SubnetResourceId,
        [Parameter()][string] $AccessRuleName 
    )

    Write-Header -ScopedPSCmdlet $PSCmdlet

    $parameters = @()
    if ($ServiceType -eq 'sql')
    {
        $parameters += '--server', "$ResourceName"
    }
    else
    {
        $parameters += '--server-name', "$ResourceName"
    }

    $matchedVnetRules = [Collections.Generic.List[string]]::new()
    $vnetRules = Invoke-Executable az $ServiceType server vnet-rule list --resource-group $ResourceGroupName @parameters | ConvertFrom-Json
    if ($AccessRuleName)
    {
        $matchingVnetRules = $vnetRules | Where-Object { $_.name -eq $AccessRuleName }
        if ($matchingVnetRules)
        {
            $matchedVnetRules.Add($AccessRuleName)
        }
    }
    else
    {
        $matchingVnetRules = $vnetRules | Where-Object { $_.virtualNetworkSubnetId -eq $SubnetResourceId }
        if ($matchingVnetRules)
        {
            foreach ($matchingVnetRule in $matchingVnetRules)
            {
                $matchedVnetRules.Add($matchingVnetRule.name)
            }
        }
    }

    # Remove vnet rules
    foreach ($ruleName in $matchedVnetRules) 
    {
        Write-Host "Removing whitelist for $ruleName."
        Invoke-Executable az $ServiceType server vnet-rule delete --resource-group $ResourceGroupName @parameters --name $ruleName
    }

    Write-Footer -ScopedPSCmdlet $PSCmdlet
}
#endregion

#region Validation helper functions

<#
.SYNOPSIS
    Validate if or CIDR or SubnetResourceId or AccessRestrictionRulename is filled in
.DESCRIPTION
    Validate if or CIDR or SubnetResourceId or AccessRestrictionRulename is filled in
#>
function Confirm-CIDRorSubnetResourceIdOrAccessRuleNameNotEmpty
{
    param (
        [Parameter()][string] $CIDR,
        [Parameter()][string] $SubnetResourceId,
        [Parameter()][string] $AccessRestrictionRuleName
    )

    if (!$CIDR -and !$SubnetResourceId -and !$AccessRestrictionRuleName)
    {
        throw "CIDR not found & Subnet resource not found & AccessRestrictionRuleName not found. Something went wrong."
    }
}

<#
.SYNOPSIS
    Validate if the appropriate parameters are added to be able to whitelist or remove the whitelist from the service
.DESCRIPTION
    Validate if the appropriate parameters are added to be able to whitelist or remove the whitelist from the service
#>
function Confirm-ParametersForWhitelist
{
    [CmdletBinding()]
    param (
        [Parameter()][string] $CIDR,
        [Parameter()][string] $AccessRestrictionRuleName,
        [Parameter()][string] $SubnetName,
        [Parameter()][string] $VnetName,
        [Parameter()][string] $VnetResourceGroupName
    )

    if ($CIDR -and $SubnetName -and $VnetName -and $VnetResourceGroupName)
    {
        throw "You can not enter a CIDRToWhitelist (CIDR whitelisting) in combination with SubnetName, VnetName, VnetResourceGroupName (Subnet whitelisting). Choose one of the two options."
    }

    # Make sure it's either filled or all empty
    if (!(($SubnetName -and $VnetName -and $VnetResourceGroupname) -or (!$SubnetName -and !$VnetName -and !$VnetResourceGroupname)))
    {
        throw "Either fill SubnetName, VnetName & VnetResourceGroupName or leave them all blank."
    } 
}

<#
.SYNOPSIS
    Generate the CIDR if no CIDR/SubnetName/VnetName/VnetResourceGroupName is passed
.DESCRIPTION
    Generate the CIDR if no CIDR/SubnetName/VnetName/VnetResourceGroupName is passed
#>
function Get-CIDRForWhitelist
{
    [CmdletBinding()]
    param (
        [Parameter()][string] $CIDR,
        [Parameter()][string] $CIDRSuffix,
        [Parameter()][string] $SubnetName,
        [Parameter()][string] $VnetName,
        [Parameter()][string] $VnetResourceGroupName
    )

    # Autogenerate CIDR if no CIDR or Subnet is passed
    if (!$CIDR -and (!$SubnetName -or !$VnetName -or !$VnetResourceGroupName))
    {
        $response = Invoke-WebRequest 'https://ipinfo.io/ip'
        return $response.Content.Trim() + $CIDRSuffix
    }
    return $CIDR
}

<#
.SYNOPSIS
    Confirm if the CIDR needs a suffix yes or no
.DESCRIPTION
    Confirm if the CIDR needs a suffix yes or no
#>
function Confirm-CIDRForWhitelist
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] [ValidateSet('storage', 'sql', 'redis', 'mysql', 'keyvault', 'webapp', 'functionapp')]$ServiceType,
        [Parameter()][string] $CIDR
    )

    Write-Host "Started confirming CIDR"
    if (!$CIDR)
    {
        Write-Host "No CIDR to check. Continueing."
        return
    }

    $serviceTypesWithRequiredSuffix = @('sql', 'redis', 'mysql', 'keyvault', 'webapp', 'functionapp')
    if ($serviceTypesWithRequiredSuffix -contains $ServiceType)
    {
        $CIDRToSplit = $CIDR.Split('/')[1]
        if (!$CIDRToSplit)
        {
            throw "Found no CIDR suffix for $CIDR. Please add the CIDR suffix, e.g. /32"
        }
        else
        {
            return $CIDR
        }
    }

    $serviceTypesWithNoSuffix = @('storage')
    if ($ServiceType -contains $serviceTypesWithNoSuffix)
    {
        $CIDRToSplit = $CIDR.Split('/')[1]
        if ($CIDRToSplit)
        {
            Write-Host "Removing CIDR suffix $CIDRToSplit for $ServiceType CIDR: $CIDR"
            return $CIDR.Replace("/$CIDRToSplit", '')
        }
        else
        {
            return $CIDR
        }
    }
}

<#
.SYNOPSIS
    Generate the AccessRestrictionRuleName if no AccessRestrictionRuleName is passed
.DESCRIPTION
    Generate the AccessRestrictionRuleName if no AccessRestrictionRuleName is passed
#>
function Get-AccessRestrictionRuleName
{
    [CmdletBinding()]
    param (
        [Parameter()][string] $AccessRestrictionRuleName,
        [Parameter()][string] $CIDR,
        [Parameter()][string] $SubnetName,
        [Parameter()][string] $VnetName,
        [Parameter()][string] $VnetResourceGroupName,
        [Parameter()][string] $CharacterToReplaceWith
    )

    if ($CharacterToReplaceWith -eq '')
    {
        $CharacterToReplaceWith = '-'
    }

    # Autogenerate name if no name is given
    if (!$AccessRestrictionRuleName -and $CIDR)
    {
        $AccessRestrictionRuleName = ($CIDR -replace "\.", $CharacterToReplaceWith) -replace "/", $CharacterToReplaceWith
    }
    elseif (!$AccessRestrictionRuleName -and $SubnetName -and $VnetName -and $VnetResourceGroupName)
    {
        $AccessRestrictionRuleName = ToMd5Hash -InputString "$($VnetResourceGroupName)_$($VnetName)_$($SubnetName)_allow"
    }

    Write-Host "AccessRestrictionRulename is: $AccessRestrictionRuleName"
    return $AccessRestrictionRuleName
}

#endregion