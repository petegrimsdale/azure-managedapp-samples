//parameters for creating a storage account
param storageAccountNamePrefix string

param storageAccountType string

param storageAccountLocation string = resourceGroup().location

var storageAccountName = '${storageAccountNamePrefix}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: storageAccountLocation
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

output storageAccountEndpoint string = storageAccount.properties.primaryEndpoints.blob
