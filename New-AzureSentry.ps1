param(
	[Parameter(Mandatory=$true,Position=0)][string]$resourceGroupName,
	[Parameter(Mandatory=$true,Position=1)][string]$azureLocation,
	[Parameter(Mandatory=$true,Position=2)][string]$storageAccountName,
	[Parameter(Mandatory=$true,Position=3)][string]$adminPassword,
	[Parameter(Mandatory=$false,Position=4)][string]$storageContainerName = "copiedvhds",
	[Parameter(Mandatory=$false,Position=5)][string]$vhdBlobName = "mobileiron-sentry.vhd",
	[Parameter(Mandatory=$false,Position=6)][string]$vhdUri = "https://mobileironsentry.blob.core.windows.net/mobileironsentrycontainer/sentry-mobileiron-9.12.0-16.vhd",
	[Parameter(Mandatory=$false,Position=7)][string]$deploymentTemplateUri = "https://mobileironsentry.blob.core.windows.net/mobileironsentrycontainer/SentryAzureDeploy-9.12.0-16.json",
	[Parameter(Mandatory=$false,Position=8)][string]$deploymentParametersUri = "https://mobileironsentry.blob.core.windows.net/mobileironsentrycontainer/SentryAzureDeploy.parameters-9.12.0-16.json"
)
az group create -n $resourceGroupName -l $azureLocation
az storage account create --resource-group $resourceGroupName --location $azureLocation --sku Standard_LRS --kind Storage --name $storageAccountName
az storage container create -n $storageContainerName --account-name $storageAccountName
az storage blob copy start --account-name $storageAccountName --destination-blob $vhdBlobName --destination-container $storageContainerName -u $vhdUri
do {
    Start-Sleep -Seconds 10
    $blobCopyInfo = az storage blob show -c $storageContainerName -n $vhdBlobName --account-name $storageAccountName | ConvertFrom-Json
    $copyStatus = $blobCopyInfo.properties.copy.status
    $copyProgress = $blobCopyInfo.properties.copy.progress
    write-host "Copy progress: $copyStatus $copyProgress"
} while ($copyStatus -eq "pending")
if ($copyStatus -eq "success") {
    $osDiskVhdUri = "https://$storageAccountName.blob.core.windows.net/$storageContainerName/$vhdBlobName"
    az deployment group create --resource-group $resourceGroupName --template-uri $deploymentTemplateUri --parameters $deploymentParametersUri --parameter adminPasswordOrKey=$adminPassword osDiskVhdUri=$osDiskVhdUri
}