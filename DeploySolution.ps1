Param(
    #
    # This will become the main region for the application
    #
	[Parameter(Mandatory=$true)]
	[string]
	$mainRegionName,

    #
    # This will become the failover region for the application
    #
    [Parameter(Mandatory=$true)]
    [string]
    $failoverRegionName,

    #
    # The storage for service dashboard and the service degradation
    # page will be hosted in its on region. For simplicity, this is 
    # deployed in one region only in the first version of this sample
    #
    [Parameter(Mandatory=$true)]
    [string]
    $serviceDashboardRegionName,

    #
    # All Service Names will be pre-fixed with this name prefix as part 
    # of the deployment
    #
    [Parameter(Mandatory=$true)]
    [string]
    $serviceNamePrefix
)


# 
# Print some information on what this script will do
#
Write-Host ""
Write-Host "This script will setup a fail-over scenario using Azure Traffic Manager and Azure SQL DB Active Geo Replication!"
Write-Host "(1) Create a storage account for a service dashboard in " $serviceDashboardRegionName
Write-Host "(2) Create a web site with a simple service degradation page in " $serviceDashboardRegionName
Write-Host "(3) Create a Azure SQL DB Premium Edition Database with Active Geo Replication in " $mainRegionName " and as failover in " $failoverRegionName "!"
Write-Host "(4) Deploy a web site in " $mainRegionName " to access the main database in that same region!"
Write-Host "(5) Deploy a web site in " $failoverRegionName " to access the fail-over database in that region!"
Write-Host "(6) Create a traffic manager service instance"
Write-Host "(7) Configure a failover-policy in traffic manager with web sites end points from " $mainRegionName " and " $failoverRegionName

# 
# Import the sample deployment helper library with functions
#
Import-Module -Name .\DeploySolutionStandardLib.psm1

#
# Set fundamental parameters (e.g. solution name, msbuild path etc.)
#
$vsSolutionName = "TrafficManagerWeb.sln"
$msBuildPath = "C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe"

$serviceNamePrefix = $serviceNamePrefix.ToLower()
$serviceMainRegionWebName = $serviceNamePrefix + "webmain"
$serviceFailoverRegionWebName = $serviceNamePrefix + "webfailover"
$serviceDegradationPageWebName = $serviceNamePrefix + "webmaintenance"
$serviceDashboardStorageName = $serviceNamePrefix + "dashboardstorage"
$serviceSqlServerName = $serviceNamePrefix + "sqlserver"
$serviceSqlDbName = "TrafficManagerWebDb"

#
# Validate the fundamental parameters
#
ValidateBasicsForDeployment -solutionName $vsSolutionName -msBuildPath $msBuildPath

# 
# Create the storage account for the dashboard
# 
StorageCreateAccountIfNotExitsAndGetKeys -storageAccountName $serviceDashboardStorageName -regionName $serviceDashboardRegionName

#
# Create the web site for the service degradation page
# 
New-AzureWebsite -Location $mainRegionName
