@description('Assign a prefix for the VM name')
param vmNamePrefix string

@description('Select the Azure region for the resources')
param location string = resourceGroup().location

@description('Selec the vm size')
param vmSize string

@description('Specify the OS username')
param userName string = 'azureadmin'

@description('If Windows, specify the password for the OS username')
@secure()
param pwd string

@description('Specify the DNS name for the managed web app')
param dnsName string

@description('Assign a name for the public IP address')
param publicIPAddressName string

var vnetID = vmVnet.id
var subnetRef = '${vnetID}/subnets/subnet1'
var osTypeWindows = {
  imageOffer: 'WindowsServer'
  imageSku: '2016-Datacenter'
  imagePublisher: 'MicrosoftWindowsServer'
}

resource vmVnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'vmVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: NSG.id
          }
        }
      }
    ]
  }
}

resource NSG 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'NSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          access: 'Allow'
          description: 'Inbound RDP rule'
          direction: 'Inbound'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: 3389
          sourcePortRange: '*'
          priority: 500
          sourceAddressPrefix: '*'
        }
      }
      {
        name: 'HTTP'
        properties: {
          access: 'Allow'
          description: 'Inbound HTTP rule'
          direction: 'Inbound'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: 80
          sourcePortRange: '*'
          priority: 550
          sourceAddressPrefix: '*'
        }
      }
    ]
  }
}

resource publicIPAddressName_IP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: '${publicIPAddressName}IP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(dnsName)
    }
  }
}

resource vmNamePrefix_nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmNamePrefix}nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_IP.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource vmNamePrefix_app 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: '${vmNamePrefix}-app'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmNamePrefix}-app'
      adminUsername: userName
      adminPassword: pwd
    }
    storageProfile: {
      imageReference: {
        publisher: osTypeWindows.imagePublisher
        offer: osTypeWindows.imageOffer
        version: 'latest'
        sku: osTypeWindows.imageSku
      }
      osDisk: {
        name: '${vmNamePrefix}-osDisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadWrite'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNamePrefix_nic.id
        }
      ]
    }
  }
}

output vmEndpoint string = publicIPAddressName_IP.properties.dnsSettings.fqdn
