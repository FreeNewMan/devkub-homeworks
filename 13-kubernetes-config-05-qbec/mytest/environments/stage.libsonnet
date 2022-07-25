
local base = import './base.libsonnet';

 base {
   components +: {
     db +: {
      "replicaCount": 1,
      "statefulSetName": "postgres-statefulset",
      "serviceName": "dbprod",
      "configMap": {
        "name": "postgres-configuration"
      }
     },
     back +: {
       "replicaCount": 1,
       "deploymentName": "backend",
       "serviceName": "backend-svc",
       "port": 9000,
       "targetPort": 9000,
       "nodePort": 30090
     },
     front +: {
       "replicaCount": 1,
       "deploymentName": "frontend",
       "serviceName": "frontend-svc",
       "port": 8000,
       "targetPort": 80,
       "nodePort": 30080
     },          
  }
 }

