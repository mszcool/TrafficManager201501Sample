#
# Validates whether msbuild is installed and the Azure CmdLets are available as well
# as whether the script is executed in the soluiton directory or not.
#
function ValidateBasicsForDeployment($solutionName, $msBuildPath) 
{
    Write-Host "Performing basic validations for script execution..."

    $workingDir = (Get-Location).Path
    Write-Host "- $workingDir"

    #
    # Test if the current working directory is the solution directory
    #
    $solutionPathAndName = [System.String]::Concat($workingDir, "\", $solutionName)
    if((Test-Path -Path $solutionPathAndName) -ne $true)
    {
        throw "Solution $solutionName not found, make sure you're working in the directory of the sample solution!!"
    }

    #
    # Test if msbuild is present
    #
    if(!(Test-Path -Path $msBuildPath))
    {
        throw "Cannot find msbuild at path '" + $msBuildPath + "'! Please correct the msBuildPath variable in the script to match your msbuild-path!"
    }


    #
    # Testing if the Azure Powershell CmdLets are installed (either resource manager or service management)
    #
    $azureModule = Get-Module -ListAvailable Azure*
    if($azureModule -eq $null) {
        throw 'Need to install and setup the Azure Powershell CmdLets before executing this script!'
    }


    #
    # Check the default subscription
    #
    $subscr = Get-AzureSubscription -Current
    if($subscr -eq $null) {
        throw "Please call Select-AzureSubscription to select a current Azure Subscription"
    }

    Write-Host "Succeeded!"
}

#
# Create a storage account if it does not exist and get the keys for further access
#
function StorageCreateAccountIfNotExitsAndGetKeys($storageAccountName, $regionName) {
    Write-Host "Creating an Azure Storage Account..." -ForegroundColor Yellow
    Switch-AzureMode -Name AzureServiceManagement
    $storageAccount = Get-AzureStorageAccount -StorageAccountName $storageAccountName -ErrorAction SilentlyContinue
    if($storageAccount -eq $null) 
    {
        Write-Host "- Storage account does not exist, yet - creating new one..."
        New-AzureStorageAccount -StorageAccountName $storageAccountName `
                                -Label $storageAccountName `
                                -Location $regionName 
        $storageAccount = Get-AzureStorageAccount -StorageAccountName $storageAccountName
        if($storageAccount -eq $null) 
        {
            throw "Unable to create storage account with name '" + $storageAccountName + "'!"
        }
    } 
    else 
    {
        Write-Host "- Storage Account exists, already. Skipping creation!"
    }
    
    Write-Host "- Storage account existed or created, getting access keys!"
    $storageKeys = Get-AzureStorageKey -StorageAccountName $storageAccountName
    if($storageKeys -eq $null) 
    {
        throw "Unable to retrieve storage access keys for storage account '" + $storageAccountName + "'!"
    }
    
    Write-Host "- Succeeded!"
    return $storageKeys
}

#
# Helper to create a storage container if it does not exist, yet
#
function StorageCreateContainerIfNotExists($containerName, $storageAccountContext) {
    Write-Host "Creating storage container $containerName..."
    Switch-AzureMode -Name AzureServiceManagement
    $newContainer = Get-AzureStorageContainer -Name $containerName -Context $storageAccountContext -ErrorAction SilentlyContinue
    if($newContainer -eq $null) 
    {
        Write-Host "- Storage Container $containerName does not exist, creating..."
        New-AzureStorageContainer -Name $containerName -Context $storageAccountContext
        $newContainer = Get-AzureStorageContainer -Name $containerName -Context $storageAccountContext
        if($newContainer -eq $null)
        {
            throw "Failed creating tesseract storage container '" + $newContainer + "'"
        }
    }
    Write-Host "- Succeeded"
    return $newContainer
}

#
# Uploads files into blob storage using
#
function StorageUploadDirectoryToBlobStorage($baseName, $directoryName, $storageContext, $containerName, $recursive = $false) 
{
    Write-Host "Uploading $directoryName to blog storage..."
    Switch-AzureMode -Name AzureServiceManagement

    $filesInDir = Get-ChildItem "$directoryName" -File
    ForEach($file in $filesInDir)
    {
        $fullFileName = $file.FullName
        $resultingBlobName = [System.String]::Concat($baseName, $file.Name)
        
        Set-AzureStorageBlobContent -File "$fullFileName" `
                                    -Container $containerName `
                                    -Blob "$resultingBlobName" `
                                    -Context $storageContext `
                                    -BlobType Block `
                                    -Force
    }

    if ( $recursive -eq $true ) {
        $subDirs = Get-ChildItem "$directoryName" -Directory
        ForEach($dir in $subDirs) 
        {
            $dirFullName = $dir.FullName
            $newBaseName = [System.String]::Concat($baseName, $dir.Name, "/")
            UploadDirectory -baseName $newBaseName `
                            -directoryName "$dirFullName" `
                            -storageContext $storageContext `
                            -containerName $containerName
        }
    }
    Write-Host "- Succeeded"
}

#
# Create a resource group if it does not exist, yet
#
function ResourceGroupCreateIfNotExists($resourceGroupName, $regionName) {
    Write-Host "Creating Resurce Group in AzureResourceManager!!"
    Switch-AzureMode -Name AzureResourceManager
    Write-Host "- Creating Resource Group '" $resourceGroupName "'..."
    $resGroup = Get-AzureResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if($resGroup -eq $null) 
    {
        Write-Host "- Resource group does not exist, yet... creating..."
        New-AzureResourceGroup -Name $resourceGroupName -Location $regionName -ErrorAction Stop
    }
    else 
    {
        Write-Host "- Resource group exists, already... skipping..."
    }
    Write-Host "- Succeeded!"
}
