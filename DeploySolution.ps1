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
    $degradationRegionName,

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
Write-Host "      it therefore updates connection string details based on what you've passed in as -sqlConnectionString parameters!"
Write-Host "(1) Create a storage account for a service dashboard in " $degradationRegionName
Write-Host "(2) Create a web site with a simple service degradation page in " $degradationRegionName
Write-Host "(3) Deploy a web site in " $mainRegionName " to access the main database in that same region!"
Write-Host "(4) Deploy a web site in " $failoverRegionName " to access the fail-over database in that region!"
Write-Host "(5) Create a web hosting plan for the main websites to run in STANDARD scale mode!"
Write-Host "(6) Assign the web-sites to the STANDARD hosting plan"
Write-Host "(7) Create a traffic manager profile for service failover"
Write-Host "(8) Configure traffic manager endpoints with websites " $mainRegionName " and " $failoverRegionName


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
$mainWebsiteName = $serviceNamePrefix + "webmain"
$failoverWebsiteName = $serviceNamePrefix + "webfailover"
$degradationWebsiteName = $serviceNamePrefix + "webmaintenance"
$dashboardStorageName = $serviceNamePrefix + "dashboardstorage"

$mainHostingPlanName = $serviceNamePrefix + "hostingmain"
$failoverHostingPlanName = $serviceNamePrefix + "hostingfailover"
$degradationHostingPlanName = $serviceNamePrefix + "hostingdegradation"

$mainResGroupName = $serviceNamePrefix + "resgrpmain"
$failoverResGroupName = $serviceNamePrefix + "resgrpfailover"
$degradationResGroupName = $serviceNamePrefix + "resgrpdegradation"

$defaultMainResGroupName = 'Default-Web-' + $mainRegionName.Replace(' ', '')
$defaultFailoverResGroupName = 'Default-Web-' + $failoverRegionName.Replace(' ', '')
$defaultDegradationResGroupName = 'Default-Web-' + $degradationRegionName.Replace(' ', '')

$trafficManagerProfileName = $serviceNamePrefix + "trafficmgrprofile"
$trafficManagerDnsName = $serviceNamePrefix + "traffic"
$trafficManagerMonitoringPath = "/TrafficManager/Ping"


#
# Validate the fundamental parameters
#
Write-Host "(0) Validation"
ValidateBasicsForDeployment -solutionName $vsSolutionName -msBuildPath $msBuildPath


# 
# Create the storage account for the dashboard
# 
Write-Host "(1) Storage Accounts"
StorageCreateAccountIfNotExitsAndGetKeys -storageAccountName $dashboardStorageName -regionName $degradationRegionName


#
# Create the web site for the service degradation page
# 
Write-Host "(2) Deploy service Degradation Web Site"
WebsiteCreateAndPublishVsProject -websiteName $degradationWebsiteName `                                 -deploymentSlot Production `
                                 -regionName $degradationRegionName `
                                 -vsProjectPath $vsProjectDegradationSite `
                                 -vsProjectConfiguration "Debug"

#
# Create the main website in the main region
#
Write-Host "(3) Deploy Main Website in main region..."
WebsiteCreateAndPublishVsProject -websiteName $mainWebsiteName `                                 -deploymentSlot Production `
                                 -regionName $mainRegionName `
                                 -vsProjectPath $vsProjectMainSite `
                                 -vsProjectConfiguration "Debug"
    # TODO: update connection string data using Set-AzureWebsite


#
# Create the failover website in the failover region
#
Write-Host "(4) Deploy Failover Website in failover region..."
WebsiteCreateAndPublishVsProject -websiteName $failoverWebsiteName `                                 -deploymentSlot Production `
                                 -regionName $failoverRegionName `
                                 -vsProjectPath $vsProjectMainSite `
                                 -vsProjectConfiguration "Debug"
    # TODO: update connection string data using Set-AzureWebsite
                                 

#
# Create a standard web hosting plan for the main web sites
# 
Write-Host "(5) Create STANDARD web hosting plans for the websites..."
Write-Host "Main Website hosting plan..."
ResourceGroupCreateIfNotExists -resourceGroupName $mainResGroupName `
                               -regionName $mainRegionName
WebsiteCreateHostingPlanIfNotExists -hostingPlanName $mainHostingPlanName `                                    -resourceGroupName $mainResGroupName `                                    -regionName $mainRegionName `                                    -sku Standard `                                    -workersizes 0 `                                    -numWorkers 1Write-Host "Failover Website hosting plan..."
ResourceGroupCreateIfNotExists -resourceGroupName $failoverResGroupName `
                               -regionName $failoverRegionName
WebsiteCreateHostingPlanIfNotExists -hostingPlanName $failoverHostingPlanName `                                    -resourceGroupName $failoverResGroupName `                                    -regionName $failoverRegionName `                                    -sku Standard `                                    -workersizes 0 `                                    -numWorkers 1Write-Host "Service Degradation Website hosting plan..."
ResourceGroupCreateIfNotExists -resourceGroupName $degradationResGroupName `
                               -regionName $degradationRegionName
WebsiteCreateHostingPlanIfNotExists -hostingPlanName $degradationHostingPlanName `                                    -resourceGroupName $degradationResGroupName `                                    -regionName $degradationRegionName `                                    -sku Standard `                                    -workersizes 0 `                                    -numWorkers 1## Now that we have the web hosting plan we can create the main website and the fail over website#Write-Host "(6) Assigning Web Sites to STANDARD hosting plan"WebsiteAssignToHostingPlan -websiteName $mainWebsiteName `                           -hostingPlanName $mainHostingPlanName `                           -resourceGroupName $defaultMainResGroupName `                           -originalResourceGroupName $defaultMainResGroupNameWebsiteAssignToHostingPlan -websiteName $failoverWebsiteName `                           -hostingPlanName $failoverHostingPlanName `                           -resourceGroupName $defaultFailoverResGroupName `                           -originalResourceGroupName $defaultFailoverResGroupNameWebsiteAssignToHostingPlan -websiteName $degradationWebsiteName `                           -hostingPlanName $degradationHostingPlanName `                           -resourceGroupName $degradationResGroupName `                           -originalResourceGroupName $defaultDegradationResGroupName## Then we need to configure Traffic Manager with it's failover policy#Write-Host "(7) Creating Traffic Manager Profile if not exists, yet..."$existingTrafficManagerProfile = Get-AzureTrafficManagerProfile -Name $trafficManagerProfileName -ErrorAction SilentlyContinueif ( $existingTrafficManagerProfile -eq $null ){    Write-Host "- Traffic manager profile does not exist, creating it..."    $existingTrafficManagerProfile = New-AzureTrafficManagerProfile -Name $trafficManagerProfileName `                                                                    -DomainName $trafficManagerDnsName `                                                                    -LoadBalancingMethod Failover `                                                                    -MonitorPort 80 `                                                                    -MonitorProtocol Http `                                                                    -MonitorRelativePath $trafficManagerMonitoringPath `                                                                    -Ttl 300 `                                                                    -ErrorAction Stop}else {    Write-Host "- Traffic manager profile with name $trafficManagerProfileName does exist, already. Skipping creation!"}Write-Host "- Succeeded!!"## Finally we can add the website endpoints in the priority they should be picked by Traffic Manager # (first is main, second is failover, third is service degradation home page)#Write-Host "(8) Adding endpoints to traffic manager..."Write-Host "- Adding endpoint for main web site..."Add-AzureTrafficManagerEndpoint -DomainName $mainWebsiteName + ".azurewebsites.net" `                                -Location $mainRegionName `                                -Type AzureWebsite `                                -Status Enabled `                                -ErrorAction Continue `                                -TrafficManagerProfile $existingTrafficManagerProfileWrite-Host "- Adding endpoint for failover web site..."Add-AzureTrafficManagerEndpoint -DomainName $failoverWebsiteName + ".azurewebsites.net" `                                -Location $failoverRegionName `                                -Type AzureWebsite `                                -Status Enabled `                                -ErrorAction Continue `                                -TrafficManagerProfile $existingTrafficManagerProfileWrite-Host "- Adding endpoint for main web site..."Add-AzureTrafficManagerEndpoint -DomainName $degradationWebsiteName + ".azurewebsites.net" `                                -Location $degradationRegionName `                                -Type AzureWebsite `                                -Status Enabled `                                -ErrorAction Continue `                                -TrafficManagerProfile $existingTrafficManagerProfileWrite-Host "- Done!!"