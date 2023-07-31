@description('projectName used to make this deployment unique')
param projectName string = 'demo'
param location string = resourceGroup().location
param networkSecurityGroupName string = '${projectName}-nsg'
param networkSecurityGroupRules array = [
  {
    name: 'AllowSSH'
    properties: {
      priority: 100
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
]

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

output networkSecurityGroupId string = networkSecurityGroupName_resource.id
