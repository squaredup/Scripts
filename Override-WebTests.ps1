<#
.SYNOPSIS
    Override Web test script with your own for a group of watchers. Based on a script from Lior Armiev

.DESCRIPTION
    Attempts to connect to a SCOM management server and create a new override for Enterprise Application web availability tests, modifying the default test script to one provided by the user.

    This script will either accept a group as an override scope (typically the one created by EAM that contains all Availability Monitors for a specific EA) or the GUID of an EA.

.PARAMETER MSServer
    The SCOM Management server to connect to when attempting to create the override. Defaults to localhost.
.PARAMETER ScriptLocation
    The path to a PowerShell script whose contents should be used for the override value.
.PARAMETER Group
    The group object that this override should be scoped to (returned from Get-Group). Typically the availability monitoring group for the EA ("xyz Availability Monitors").
.PARAMETER EnterpriseApplicationGuid
    The GUID of the Enterprise Application that this override should be scoped to. Easily obtained by drilling down in Squared Up to the EA in question and then copying from the URL.
.EXAMPLE
    C:\PS> .\Override-WebTests.ps1 -MSServer scom01.contoso.local -ScriptLocation .\NewWebTest.ps1 -EA "6ee9a961-f6ff-447a-ac75-27bb58fbedb5"
    Overrides all web tests for a specific EA, using the contents of NewWebTest.ps1, by connecting to SCOM01.contoso.local

.NOTES
    Copyright 2018 Squared Up Limited, All Rights Reserved.

.LINK
    https://armiev.com/2018/04/02/124/
.LINK
    https://www.squaredup.com
.LINK
    https://github.com/squaredup

#>
[cmdletbinding(DefaultParameterSetName="EA")]
Param(
    $MSServer = "localhost",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $ScriptLocation,

    [Parameter(Mandatory=$true, ParameterSetName="Group")]
    [ValidateNotNullOrEmpty()]
    [Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectGroup[]]$Group,

    [Parameter(Mandatory=$true, ParameterSetName="EA")]
    [ValidateNotNullOrEmpty()]
    [Guid]$EnterpriseApplicationGuid
)
#connection to SCOM
Import-Module OperationsManager
if ($null -eq (Get-SCOMManagementGroupConnection)){
    New-SCOMManagementGroupConnection -ComputerName $MSServer
}

if ($PSCmdlet.ParameterSetName -eq "EA") {
    $ea = Get-SCOMClassInstance -Id $EnterpriseApplicationGuid
    $group = $ea.GetRelatedMonitoringObjects((Get-SCOMClass -Id '75d99e84-63f4-f5d9-95af-54bbf5c61c40')).GetRelatedMonitoringObjects()
}

function Get-ManagementPackMonitorReference
{
    Param([Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor]$Monitor)

    $method = $monitor.Identifier.GetType().GetMethod("GetReference", [Microsoft.EnterpriseManagement.Configuration.ManagementPack])
    $getReference = $method.MakeGenericMethod([Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor])

    return $getReference.Invoke($Monitor.Identifier, $Monitor.GetManagementPack())
}

#load the script file
$script = Get-Content $ScriptLocation -Raw -ErrorAction Stop

# Get Web monitor
$Monitor = get-scommonitor -Name "SquaredUp.EAM.Library.Monitor.AvailabilityMonitoring.Web"

foreach ($scope in $group){

    #get the scom management pack that will hold the overrids
    $mp = $scope.GetLeastDerivedNonAbstractClass().Getmanagementpack()

    if ($Monitor) #you can add any condition you want
    {
        $OverrideID = "Override.$($monitor.name).$($scope.FullName)" #you must have a unique name
        $Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorConfigurationOverride($mp,$OverrideID)
        $Override.Monitor = Get-ManagementPackMonitorReference -Monitor $Monitor
        $Override.Parameter = "Script"
        $Override.Value = $script
        $Override.Context = $scope.GetLeastDerivedNonAbstractClass()
        $Override.ContextInstance = $scope.Id
        $Override.DisplayName = "$($scope.DisplayName) Web Availability Monitoring override"  #Name the override in the console
    }

    try {
        $mp.Verify()
        $mp.AcceptChanges()
    }
    catch{
        $mp.RejectChanges()
        throw
    }
}
