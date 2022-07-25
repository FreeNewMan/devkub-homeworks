local p = import '../params.libsonnet';
local params = p.components.back;
local prmdb = p.components.db;

[
    {
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "labels": {
      "app": "backend"
    },
    "name": params.deploymentName
  },
  "spec": {
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "backend"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "backend"
        }
      },
      "spec": {
        "containers": [
          {
            "image":  params.image.repository+':'+params.image.tag,
            "imagePullPolicy": "IfNotPresent",
            "name": "backend",
            "ports": [
              {
                "containerPort": params.port
              }
            ],
            "env": [
              {
                "name": "DATABASE_URL",
                "value":  "postgres://"+prmdb.credentials.POSTGRES_USER+":"+prmdb.credentials.POSTGRES_PASSWORD+"@"+prmdb.serviceName+":"+prmdb.port+"/"+prmdb.credentials.POSTGRES_DB 
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
  },
  "spec": {
    "ports": [
      {
        "name": "web",
        "port": params.port,
        "targetPort": params.targetPort,
        "nodePort": params.nodePort
      }
    ],
    "selector": {
      "app": "backend"
    },
    "type": "NodePort"
  }
}


]

