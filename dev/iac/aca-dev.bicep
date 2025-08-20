// dev/iac/aca-dev.bicep
@description('Prefix pour les noms de ressources (ex: musafirgo)')
param prefix string = 'musafirgo'

@description('Région Azure')
param location string = 'westeurope'

@description('Nom logique de l’app (microservice)')
param appName string = 'itinerary'

@description('Image complète à déployer (ex: musafirgoacr.azurecr.io/musafirgo-itinerary-service:<tag>)')
param containerImage string

@description('CPU pour le conteneur (0.25/0.5/1/2)')
param cpu number = 0.5

@description('RAM pour le conteneur (0.5Gi/1Gi/2Gi/4Gi)')
param memory string = '1Gi'

var base = toLower('${prefix}-${appName}')

// 1) Log Analytics (logs ACA)
resource log 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${base}-log'
  location: location
  properties: {
    retentionInDays: 30
    sku: { name: 'PerGB2018' }
  }
}

// 2) Environnement géré pour Container Apps
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

// 3) Azure Container Registry (pas de compte admin)
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${prefix}acr'
  location: location
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

// 4) Identité managée (User Assigned) pour ACA (pull d’image ACR)
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${base}-uami'
  location: location
}

// 5) Rôle AcrPull: l’ID managée peut tirer l’image depuis l’ACR
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, 'acrpull', uami.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 6) Container App (ingress public 8081)
resource app 'Microsoft.App/containerApps@2024-02-02-preview' = {
  name: '${base}-app'
  location: location
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
        targetPort: 8081
        transport: 'auto'
        traffic: [ { latestRevision: true, weight: 100 } ]
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: uami.id // pas de secret: ID managée
        }
      ]
      secrets: []
    }
    template: {
      containers: [
        {
          name: appName
          image: containerImage
          env: [
            { name: 'JAVA_OPTS', value: '-XX:+UseG1GC -XX:MaxRAMPercentage=75' }
          ]
          probes: [
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
          resources: { cpu: cpu, memory: memory }
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 3 }
    }
  }
}

// Sorties utiles
output containerAppFqdn string = app.properties.configuration.ingress.fqdn
output acrLoginServer   string = acr.properties.loginServer
output managedEnvName   string = cae.name
output uamiClientId     string = uami.properties.clientId