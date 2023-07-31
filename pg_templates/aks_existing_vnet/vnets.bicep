targetScope = 'resourceGroup'
param vnets array

resource vnets_name 'Microsoft.Network/virtualNetworks@2021-02-01' = [for i in range(0, length(vnets)): {
  name: vnets[i].name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnets[i].addressPrefix
      ]
    }
    subnets: [for j in range(0, length(vnets[i].subnets)): {
      name: vnets[i].subnets[j].name
      properties: {
        addressPrefix: vnets[i].subnets[j].addressPrefix
        delegations: vnets[i].subnets[j].delegations
        networkSecurityGroup: vnets[i].subnets[j].nsg
      }
    }]
  }
}]
