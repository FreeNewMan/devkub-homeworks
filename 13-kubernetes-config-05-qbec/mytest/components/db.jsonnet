local p = import '../params.libsonnet';
local params = p.components.db;

[
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": params.configMap.name,
    "labels": {
      "app": "postgres"
    }
  },
  "data": {
    "POSTGRES_DB": params.credentials.POSTGRES_DB,
    "POSTGRES_USER": params.credentials.POSTGRES_USER,
    "POSTGRES_PASSWORD": params.credentials.POSTGRES_PASSWORD
  }
},

{
  "apiVersion": "apps/v1",
  "kind": "StatefulSet",
  "metadata": {
    "name": params.statefulSetName,
    "labels": {
      "app": "postgres"
    }
  },
  "spec": {
    "serviceName": "postgres",
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "postgres"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "postgres"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "postgres",
            "image": params.image.repository+':'+params.image.tag,
            "envFrom": [
              {
                "configMapRef": {
                  "name": params.configMap.name
                }
              }
            ],
            "ports": [
              {
                "containerPort": params.port,
                "name": "postgresdb"
              }
            ]
          }
        ]
      }
    }
  }
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": params.serviceName,
    "labels": {
      "app": "postgres"
    }
  },
  "spec": {
    "ports": [
      {
        "port": params.port,
        "name": "postgres"
      }
    ],
    "type": "ClusterIP",
    "selector": {
      "app": "postgres"
    }
  }
}
]