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
    $serviceNamePrefix,

    #
    # Main region SQL Connection string
    #
    [Parameter(Mandatory=$true)]
    [string]
    $sqlConnectionStringMainRegion,

    #
    # Failover region SQL Connection string
    #
    [Parameter(Mandatory=$true)]
    [string]
    $sqlConnectionStringFailoverRegion
)


# 
# Print some information on what this script will do
#
Write-Host ""
Write-Host "This script will setup a fail-over scenario using Azure Traffic Manager!"
Write-Host "Note: this first version assumes you have created an Azure SQL DB Premium with active geo replication, upfront, manually!"
Write-Host "      it therefore updates connection string details based on what you've passed in as parameters!"
Write-Host "(1) Create a storage account for a service dashboard in " $serviceDashboardRegionName
Write-Host "(2) Create a web site with a simple service degradation page in " $serviceDashboardRegionName
Write-Host "(3) Deploy a web site in " $mainRegionName " to access the main database in that same region!"
Write-Host "(4) Deploy a web site in " $failoverRegionName " to access the fail-over database in that region!"
Write-Host "(5) Create a web hosting plan for the main websites to run in STANDARD scale mode!"
Write-Host "(6) Assign the web-sites to the STANDARD hosting plan"
Write-Host "(7) Create a traffic manager service instance"
Write-Host "(8) Configure a failover-policy in traffic manager with web sites end points from " $mainRegionName " and " $failoverRegionName


# 
# Import the sample deployment helper library with functions
#
Import-Module -Name .\DeploySolutionStandardLib.psm1
Import-Module -Name .\DeployWebsitesStandardLib.psm1


#
# Set fundamental parameters (e.g. solution name, msbuild path etc.)
#
$vsSolutionName = "TrafficManagerWeb.sln"
$vsProjectDegradationSite = ".\TrafficManagerDegradationWeb\TrafficManagerDegradationWeb.csproj"
$vsProjectMainSite = ".\TrafficManagerWeb\TrafficManagerWeb.csproj"
$msBuildPath = "C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe"

$serviceNamePrefix = $serviceNamePrefix.ToLower()
$serviceMainRegionWebName = $serviceNamePrefix + "webmain"
$serviceFailoverRegionWebName = $serviceNamePrefix + "webfailover"
$serviceDegradationPageWebName = $serviceNamePrefix + "webmaintenance"
$serviceDashboardStorageName = $serviceNamePrefix + "dashboardstorage"
$serviceHostingPlan = $serviceNamePrefix + "hostingplan"
$serviceResGroupMain = $serviceNamePrefix + "resourcegroupmain"
$serviceResGroupFailover = $serviceNamePrefix + "resourcegroupfailover"
$defaultResourceGroupMain = 'Default-Web-' + $mainRegionName.Replace(' ', '')
$defaultResourceGroupFailover = 'Default-Web-' + $failoverRegionName.Replace(' ', '')


#
# Validate the fundamental parameters
#
Write-Host "(0) Validation"
ValidateBasicsForDeployment -solutionName $vsSolutionName -msBuildPath $msBuildPath


# 
# Create the storage account for the dashboard
# 
Write-Host "(1) Storage Accounts"
StorageCreateAccountIfNotExitsAndGetKeys -storageAccountName $serviceDashboardStorageName -regionName $serviceDashboardRegionName


#
# Create the web site for the service degradation page
# 
Write-Host "(2) Service Degradation Web Site"
WebsiteCreateAndPublishVsProject -websiteName $serviceDegradationPageWebName `                                 -deploymentSlot Production `
                                 -regionName $serviceDashboardRegionName `
                                 -vsProjectPath $vsProjectDegradationSite `
                                 -vsProjectConfiguration "Debug"

#
# Create the main website in the main region
#
Write-Host "(3) Deploy Main Website in main region..."
WebsiteCreateAndPublishVsProject -websiteName $serviceMainRegionWebName `                                 -deploymentSlot Production `
                                 -regionName $mainRegionName `
                                 -vsProjectPath $vsProjectMainSite `
                                 -vsProjectConfiguration "Debug"


#
# Create the failover website in the failover region
#
Write-Host "(4) Deploy Failover Website in failover region..."
WebsiteCreateAndPublishVsProject -websiteName $serviceFailoverRegionWebName `                                 -deploymentSlot Production `
                                 -regionName $failoverRegionName `
                                 -vsProjectPath $vsProjectMainSite `
                                 -vsProjectConfiguration "Debug"
                                 

#
# Create a standard web hosting plan for the main web sites
# 
Write-Host "(5) Create STANDARD web hosting plan for the main sites..."
ResourceGroupCreateIfNotExists -resourceGroupName $serviceResGroupMain -regionName $mainRegionName
WebsiteCreateHostingPlanIfNotExists -hostingPlanName $serviceHostingPlan `                                    -resourceGroupName $serviceResGroupMain `                                    -regionName $mainRegionName `                                    -sku Standard `                                    -workersizes 0 `                                    -numWorkers 1## Now that we have the web hosting plan we can create the main website and the fail over website#Write-Host "(6) Assigning Web Sites to STANDARD hosting plan"WebsiteAssignToHostingPlan -websiteName $serviceMainRegionWebName `                           -hostingPlanName $serviceHostingPlan `                           -resourceGroupName $defaultResourceGroupMainWebsiteAssignToHostingPlan -websiteName $serviceFailoverRegionWebName `                           -hostingPlanName $serviceHostingPlan `                           -resourceGroupName $defaultResourceGroupMain## Finally we need to configure Traffic Manager with it's failover policy#