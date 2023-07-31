param clusterName string
param location string
param nodeResourceGroup string
param aksIdentityResourceId string
param dnsPrefix string = toLower(clusterName)
param logAnalyticsWorkspaceId string
param aksSubnetId string
@description('Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param podCidr string = '10.244.0.0/16'
@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param serviceCidr string = '10.240.0.0/16'
@description('Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param dnsServiceIP string = '10.240.0.10'
@description('Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string = '172.17.0.1/16'
param aksnetworktype string


resource aks 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentityResourceId}': {}
    }
  }
  properties: {
    nodeResourceGroup: nodeResourceGroup
    dnsPrefix: dnsPrefix
    oidcIssuerProfile:{
      enabled:true
    }

    agentPoolProfiles: [
      {
        name: 'system'
        count: 1
        enableAutoScaling: false
        vmSize: 'Standard_D4s_v4'
        osType: 'Linux'
        osDiskType: 'Managed'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '1'
          '2'
        ]
        vnetSubnetID: aksSubnetId
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'application'
        count: 2
        maxPods: 15
        enableAutoScaling: false
        vmSize: 'Standard_D4s_v4'
        osType: 'Linux'
        osDiskType: 'Managed'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '1'
          '2'
        ]
        vnetSubnetID: aksSubnetId
        nodeTaints: []
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: aksnetworktype
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
      loadBalancerSku: 'standard'
    }
    securityProfile:{
      workloadIdentity:{
        enabled:true
      }
    }
  }
}

output aksClusterName string = aks.name
output aksNodeResourceGroup string = aks.properties.nodeResourceGroup
output aksKubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
