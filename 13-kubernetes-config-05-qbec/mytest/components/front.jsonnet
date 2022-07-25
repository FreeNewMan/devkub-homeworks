local p = import '../params.libsonnet';
local params = p.components.front;

[
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "labels": {
      "app": "frontend"
    },
    "name": params.deploymentName
  },
  "spec": {
    "replicas": params.replicaCount,
    "selector": {
      "matchLabels": {
        "app": "frontend"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "frontend"
        }
      },
      "spec": {
        "containers": [
          {
            "image":  params.image.repository+':'+params.image.tag,
            "imagePullPolicy": "IfNotPresent",
            "name": "frontend",
            "ports": [
              {
                "containerPort": params.port
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
    "name": params.serviceName
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
      "app": "frontend"
    },
    "type": "NodePort"
  }
}

]

