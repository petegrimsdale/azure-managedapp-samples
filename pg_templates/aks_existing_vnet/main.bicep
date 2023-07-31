targetScope = 'resourceGroup'

param location string = resourceGroup().location

// Marketplace
param marketplaceAttributionIdPlaceholder string = newGuid()

// Virtual network

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string = 'new'
@description('Existing VNet Name')
param virtualNetworkName string = 'rtc-vnet'

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string = resourceGroup().name

@description('Application subnet Name')
param vmSubnetName string = 'vm-subnet'

@description('AKS subnet Name')
param aksSubnetName string = 'aks-subnet'

@description('Address Prefix of the Vnet')
param virtualNetworkAddressPrefix array = [
  '10.3.0.0/22'
]

@description('Subnet Address Prefix')
param aksSubnetAddressPrefix string = '10.3.0.0/24'

@description('Subnet Address Prefix')
param vmSubnetAddressPrefix string = '10.3.3.0/27'

param aksNodeResourceGroup string = '${resourceGroup().name}-aks'

// AKS

param aksnetworktype string = 'azure'
param projectName string = 'demo'

var aksClusterName = '${projectName}-aks'


var vnets = ( virtualNetworkNewOrExisting == 'new' ) ?  [
  {
    name: '${projectName}-vnet'
    addressPrefix: virtualNetworkAddressPrefix[0]
    subnets: [
      {
        name: vmSubnetName
        addressPrefix: vmSubnetAddressPrefix
        delegations: []
        nsg: {
          id: nsg.outputs.networkSecurityGroupId
        }
      }
      {
        name: aksSubnetName
        addressPrefix: aksSubnetAddressPrefix
        delegations: []
        nsg: json('null')
      }
    ]
  }
] : [
  {
    name: virtualNetworkName
    addressPrefix: virtualNetworkAddressPrefix[0]
    subnets: [
      {
        name: vmSubnetName
        addressPrefix: vmSubnetAddressPrefix
      }
      {
        name: aksSubnetName
        addressPrefix: aksSubnetAddressPrefix
      }
    ]
  }
]

var nsgRules = (virtualNetworkNewOrExisting == 'new') ? [
  {
    name: 'SSH'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: 22
    }
  }
]:[]

resource marketplaceAttribution 'Microsoft.Resources/deployments@2021-04-01' = {
  name: marketplaceAttributionIdPlaceholder
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module vnet 'vnets.bicep' = if (virtualNetworkNewOrExisting == 'new') {
  name: '${projectName}Vnet'
  params: {
    vnets: vnets
  }
}


resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${projectName}LogAnalytics'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 60
  }
}

module nsg 'nsg.bicep' = if (virtualNetworkNewOrExisting == 'new') {
  name: '${projectName}NetworkSecurityGroup'
  params: {
    networkSecurityGroupRules: nsgRules
    projectName: projectName
    location: location
  }
}

module identity 'identity.bicep' = {
  name: '${projectName}Identity'
  params: {
    appName: projectName
    location: location
  }
}

module aks 'aks.bicep' = {
  name: '${projectName}Aks'
  params: {
    location: location
    clusterName: aksClusterName
    aksIdentityResourceId: identity.outputs.aksIdentityResourceId
    nodeResourceGroup: aksNodeResourceGroup
    aksSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnets[0].name, aksSubnetName)
    logAnalyticsWorkspaceId: loganalytics.id
    aksnetworktype: aksnetworktype
  }
  dependsOn: [
    vnet
  ]
}

module roleassignment 'role-assignment.bicep' = {
  name: '${projectName}RoleAssignment'
  params: {
    aksIdentityObjectId: identity.outputs.aksIdentityObjectId
    aksKubeletIdentityObjectId: aks.outputs.aksKubeletIdentityObjectId
  }
}

module roleassignmentAks 'role-assignment-aks.bicep' = {
  name: '${projectName}RoleAssignmentAks'
  scope: resourceGroup(aksNodeResourceGroup)
  params: {
    aksKubeletIdentityObjectId: aks.outputs.aksKubeletIdentityObjectId
  }
}
