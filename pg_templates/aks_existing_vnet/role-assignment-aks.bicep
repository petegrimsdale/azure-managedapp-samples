param aksKubeletIdentityObjectId string

var virtualMachineContributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')


// This role assignment allows the Kubelet identity to attach identities to the VMSS instances (needed by AAD Pod Identity)
resource kubeletIdentityVirtualMachineContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('kubeletIdentityVirtualMachineContributor', resourceGroup().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: virtualMachineContributorRole
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
