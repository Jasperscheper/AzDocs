[CmdletBinding()]
param (
    [Parameter(Mandatory)][string] $LogAnalyticsWorkspaceResourceGroupName,
    [Parameter(Mandatory)][string] $LogAnalyticsWorkspaceName,
    [Parameter()][string] $OutputPipelineVariableName = "LogAnalyticsWorkspaceResourceId"
)

#region ===BEGIN IMPORTS===
Import-Module "$PSScriptRoot\..\AzDocs.Common" -Force
#endregion ===END IMPORTS===

Write-Header -ScopedPSCmdlet $PSCmdlet

$logAnalyticsWorkspaceResourceId = (Invoke-Executable az monitor log-analytics workspace show --resource-group $LogAnalyticsWorkspaceResourceGroupName --workspace-name $LogAnalyticsWorkspaceName | ConvertFrom-Json).id
Write-Host "LogAnalyticsWorkspaceResourceId: $LogAnalyticsWorkspaceResourceId"
Write-Host "##vso[task.setvariable variable=$($OutputPipelineVariableName)]$LogAnalyticsWorkspaceResourceId"

Write-Footer -ScopedPSCmdlet $PSCmdlet