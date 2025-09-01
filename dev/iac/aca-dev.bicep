// dev/iac/aca-dev.bicep

@description('Prefix for resource names (e.g. musafirgo)')
@minLength(5)
param prefix string = 'musafirgo'

@description('Azure region')
param location string = 'westeurope'

@description('Logical app name (microservice)')
param appName string = 'itinerary'

@description('Full image reference (e.g. musafirgoacr.azurecr.io/musafirgo-itinerary-service:tag). Leave empty to bootstrap with a public image.')
param containerImage string

@description('CPU vCores as string. Examples: 0.5, 1, 2')
param cpu string = '0.5'

@description('Container memory (e.g. 0.5Gi, 1Gi, 2Gi, 4Gi)')
param memory string = '1Gi'

@description('APIM SKU (Consumption, Developer, Basic, Standard, Premium)')
param apimSku string = 'Consumption'

@description('APIM Publisher Name')
param apimPublisherName string = 'MusafirGO Team'

@description('APIM Publisher Email')
param apimPublisherEmail string = 'dev@musafirgo.com'

// ---------------- Vars ----------------
var base = toLower('${prefix}-${appName}')
var isBootstrap = (containerImage == '')
var imageToUse = isBootstrap ? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' : containerImage
var targetPort = isBootstrap ? 80 : 8081

// APIM Configuration
var apimName = '${prefix}-apim'
var apiName = '${appName}-api'
var apiVersion = 'v1'
var apiRevision = '1'

// 1) Log Analytics (ACA logs)
resource log 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${base}-log'
  location: location
  properties: {
    retentionInDays: 30
    sku: { name: 'PerGB2018' }
  }
}

// 2) Managed Environment for Container Apps
resource cae 'Microsoft.App/managedEnvironments@2024-02-02-preview' = {
  name: '${base}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: log.properties.customerId
        sharedKey: log.listKeys().primarySharedKey
      }
    }
  }
}

// 3) Azure Container Registry (admin disabled)
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${prefix}acr'
  location: location
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
  }
}

// 3.5) Azure API Management (APIM)
resource apim 'Microsoft.ApiManagement/service@2024-02-15-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimSku
    capacity: 0
  }
  properties: {
    publisherName: apimPublisherName
    publisherEmail: apimPublisherEmail
    notificationSenderEmail: 'apimgmt-noreply@azure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${apimName}.azure-api.net'
        defaultSslBinding: true
        negotiateClientCertificate: false
      }
    ]
    virtualNetworkType: 'None'
    apiVersionConstraint: {
      minApiVersion: '2021-08-01'
    }
  }
}

// 3.6) API Definition in APIM (Basic for Sprint 1)
resource api 'Microsoft.ApiManagement/service/apis@2024-02-15-preview' = {
  parent: apim
  name: apiName
  properties: {
    displayName: '${appName} API'
    description: 'API for ${appName} microservice (Sprint 1 - Mock)'
    serviceUrl: 'https://${app.name}.${cae.name}.azurecontainerapps.io'
    path: 'api/${appName}'
    protocols: ['https']
    apiVersion: apiVersion
    apiRevision: apiRevision
    isCurrent: true
    apiType: 'http'
  }
}

// 3.7) API Policy (Mock for Sprint 1)
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-02-15-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: '''
      <policies>
        <inbound>
          <base />
          <!-- Mock policy for Sprint 1 - returns 200 OK -->
          <mock-response status-code="200" content-type="application/json" />
        </inbound>
        <backend>
          <base />
        </backend>
        <outbound>
          <base />
        </outbound>
        <on-error>
          <base />
        </on-error>
      </policies>
    '''
    format: 'xml'
  }
}

// 4) User Assigned Managed Identity (for ACA to pull from ACR)
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${base}-uami'
  location: location
}

// 5) Assign AcrPull role to the UAMI on the ACR
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, 'acrpull', uami.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 6) Container App (public ingress; wait explicitly for AcrPull)
resource app 'Microsoft.App/containerApps@2024-02-02-preview' = {
  name: '${base}-app'
  location: location

  dependsOn: [
    acrPull
  ]

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: cae.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        traffic: [
          { latestRevision: true, weight: 100 }
        ]
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: uami.id
        }
      ]
      secrets: []
    }
    template: {
      containers: [
        {
          name: appName
          image: imageToUse
          env: [
            { name: 'JAVA_OPTS', value: '-XX:+UseG1GC -XX:MaxRAMPercentage=75' }
          ]
          probes: isBootstrap ? [] : [
            {
              type: 'liveness'
              httpGet: { path: '/actuator/health/liveness', port: 8081 }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
            {
              type: 'readiness'
              httpGet: { path: '/actuator/health/readiness', port: 8081 }
              initialDelaySeconds: 5
              periodSeconds: 10
            }
          ]
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 3 }
    }
  }
}

// ---------------- Outputs ----------------
output containerAppFqdn string = app.properties.configuration.ingress.fqdn
output acrLoginServer   string = acr.properties.loginServer
output managedEnvName   string = cae.name
output uamiClientId     string = uami.properties.clientId
output apimGatewayUrl   string = 'https://${apimName}.azure-api.net'
output apiUrl           string = 'https://${apimName}.azure-api.net/api/${appName}'