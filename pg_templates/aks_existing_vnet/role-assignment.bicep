param aksIdentityObjectId string
param aksKubeletIdentityObjectId string


var networkContributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var managedIdentityOperatorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')

resource aksIdentityNetworkContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('aksIdentityNetworkContributor', resourceGroup().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: networkContributorRole
    principalId: aksIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}


//This Role Assignment allows the Kubelet Identity to assign the other identities to the AKS nodes (needed by AAD Pod Identity)
resource kubeletIdentityManagedIdentityOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('kubeletIdentityManagedIdentityOperator', resourceGroup().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: managedIdentityOperatorRole
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

