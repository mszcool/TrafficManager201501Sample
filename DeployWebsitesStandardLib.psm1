#
# Creates a website using the Azure Service Management API and publishes a Visual Studio Web Project to the web site
#
function WebsiteCreateAndPublishVsProject($websiteName, $deploymentSlot, $regionName, $vsProjectPath, $vsProjectConfiguration) 
{
    Write-Host "Creating website $websiteName if it does not exist..."
    Switch-AzureMode -Name AzureServiceManagement

    $existingWebsite = Get-AzureWebsite -Name $websiteName `
                                        -Slot $deploymentSlot `
                                        -ErrorAction SilentlyContinue
    if ( $serviceDegradationWebSite -eq $null ) {
        Write-Host "- Web Site $websiteName does not exist, creating it..."
        New-AzureWebsite -Name $websiteName `                         -Location $regionName `
                         -Slot $deploymentSlot `
                         -ErrorAction Stop
    }

    Write-Host "- Publishing the project $vsProjectPath Visual Studio project..."
    Publish-AzureWebsiteProject -ProjectFile $vsProjectPath `
                                -Configuration $vsProjectConfiguration `
                                -Slot $deploymentSlot `                                -Name $websiteName `
                                -ErrorAction Stop

    Write-Host "- Succeeded!"
}


#
# Creates a web hosting plan with the defined SKU and number of workers if it does not exist, already
#
function WebsiteCreateHostingPlanIfNotExists($hostingPlanName, $resourceGroupName, $regionName, $sku, $workersizes, $numWorkers) 
{
    Write-Host "Create Web Hosting plan if it does not exist..."
    Switch-AzureMode -Name AzureResourceManager
    $existingPlan = Get-AzureResource -Name $hostingPlanName `
                                      -ResourceGroupName $resourceGroupName `
                                      -ResourceType Microsoft.Web/serverFarms `
                                      -ApiVersion 2014-04-01 `                                      -ErrorAction SilentlyContinue    if ( $existingPlan -eq $null ) {        Write-Host "- Plan does not exist, creating it..."        $planProps = @{"name"=$hostingPlanName;"sku"="Standard";"workerSize"="1";"numberOfWorkers"=1}        New-AzureResource -ApiVersion 2014-04-01 `                          -Name $hostingPlanName `                          -ResourceGroupName $resourceGroupName `                          -ResourceType Microsoft.Web/serverFarms `                          -Location $regionName `                          -ErrorAction Stop    }    Write-Host "- Succeeded!"
}


#
# Assigns an existing website from one hosting plan to another
#
function WebsiteAssignToHostingPlan($websiteName, $hostingPlanName, $resourceGroupName, $originalResourceGroupName)
{
    Write-Host "Assigning website $websiteName to hosting plan $hostingPlanName..."    Switch-AzureMode -Name AzureResourceManager    $hostingPlanParam = @{ 'serverFarm' = $hostingPlanName }    Write-Host "- Getting azure resource for website..."    $mainSiteResource = Get-AzureResource -Name $websiteName `                                          -ResourceGroupName $originalResourceGroupName `                                          -ResourceType Microsoft.Web/sites `                                           -ApiVersion 2014-04-01 `                                          -ErrorAction Stop    
    Write-Host "- Setting properties on azure resource for website..."
    $mainSiteResource = Set-AzureResource -Name $websiteName `
                                          -ResourceGroupName $resourceGroupName `                                          -ResourceType Microsoft.Web/sites `
                                          -ApiVersion 2014-04-01 `
                                          -PropertyObject $hostingPlanParam `
                                          -ErrorAction Stop

    Write-Host "- Succeeded!"
}