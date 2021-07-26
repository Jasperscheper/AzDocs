[CmdletBinding()]
param (
    [Parameter(Mandatory)][string] $SqlServerResourceGroupName,
    [Parameter(Mandatory)][string] $SqlServerName,
    [Parameter(Mandatory)][string] $SqlDatabaseName,
    [Parameter()][string] $SqlDatabaseSkuName,
    [Parameter()][ValidateSet('', 'Basic', 'Standard', 'Premium', 'GeneralPurpose', 'BusinessCritical', 'Hyperscale')][string] $SqlDatabaseEdition,
    [Parameter()][ValidateSet('', 'Gen4', 'Gen5')][string] $SqlDatabaseFamily,
    [Parameter()][ValidateSet('', 'Provisioned', 'Serverless')][string] $SqlDatabaseComputeModel,
    [Parameter()][int] $SqlDatabaseAutoPauseDelayInMinutes,
    [Parameter()][int] $SqlDatabaseMinCapacity,
    [Parameter()][int] $SqlDatabaseMaxCapacity,
    [Parameter()][ValidateSet('', 'Local', 'Zone', 'Geo')][string] $SqlDatabaseBackupStorageRedundancy,
    [Parameter()][string] $SqlDatabaseMaxStorageSize,
    [Parameter()][string] $SqlServerElasticPoolName,
    [Parameter(Mandatory)][System.Object[]] $ResourceTags, 

    # Diagnostic Settings
    [Parameter(Mandatory)][string] $LogAnalyticsWorkspaceResourceId
)

#region ===BEGIN IMPORTS===
Import-Module "$PSScriptRoot\..\AzDocs.Common" -Force
#endregion ===END IMPORTS===

Write-Header -ScopedPSCmdlet $PSCmdlet

$additionalParameters = @()
if ($SqlDatabaseSkuName)
{
    $additionalParameters += '--service-objective', $SqlDatabaseSkuName
}
if ($SqlDatabaseEdition)
{
    $additionalParameters += '--edition', $SqlDatabaseEdition
}
if ($SqlDatabaseFamily)
{
    $additionalParameters += '--family', $SqlDatabaseFamily
}
if ($SqlDatabaseComputeModel)
{
    $additionalParameters += '--compute-model', $SqlDatabaseComputeModel
}
if ($SqlDatabaseAutoPauseDelayInMinutes)
{
    $additionalParameters += '--auto-pause-delay', $SqlDatabaseAutoPauseDelayInMinutes
}
if ($SqlDatabaseMinCapacity)
{
    $additionalParameters += '--min-capacity', $SqlDatabaseMinCapacity
}
if ($SqlDatabaseMaxCapacity)
{
    $additionalParameters += '--capacity', $SqlDatabaseMaxCapacity
}
if ($SqlDatabaseBackupStorageRedundancy)
{
    $additionalParameters += '--backup-storage-redundancy', $SqlDatabaseBackupStorageRedundancy
}
if ($SqlDatabaseMaxStorageSize)
{
    $additionalParameters += '--max-size', $SqlDatabaseMaxStorageSize
}
if ($SqlServerElasticPoolName)
{
    $additionalParameters += '--elastic-pool', $SqlServerElasticPoolName
}

# Create SQL database
$sqlDatabaseId = (Invoke-Executable az sql db create --name $SqlDatabaseName --resource-group $SqlServerResourceGroupName --server $SqlServerName --tags ${ResourceTags} @additionalParameters | ConvertFrom-Json).id

# Add diagnostic settings to SQL database
$sqlDiagnosticSettingLogs = "[{ 'category': 'SQLInsights', 'enabled': true }, { 'category': 'AutomaticTuning', 'enabled': true }, { 'category': 'QueryStoreRuntimeStatistics', 'enabled': true }, { 'category': 'QueryStoreWaitStatistics', 'enabled': true }, { 'category': 'Errors', 'enabled': true }, { 'category': 'DatabaseWaitStatistics', 'enabled': true },  { 'category': 'Timeouts', 'enabled': true }, { 'category': 'Blocks', 'enabled': true }, { 'category': 'Deadlocks', 'enabled': true }]"
Set-DiagnosticSettings -ResourceId $sqlDatabaseId -ResourceName $SqlDatabaseName -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -Logs $sqlDiagnosticSettingLogs.Replace("'", '\"') -Metrics "[ { 'category': 'Basic', 'enabled': true }, { 'category': 'InstanceAndAppAdvanced', 'enabled': true }, { 'category': 'WorkloadManagement', 'enabled': true } ]".Replace("'", '\"')

Write-Footer -ScopedPSCmdlet $PSCmdlet