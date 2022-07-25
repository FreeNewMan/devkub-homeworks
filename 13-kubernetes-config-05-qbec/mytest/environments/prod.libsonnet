
local base = import './base.libsonnet';

 base {
   components +: {
     db +: {
      "replicaCount": 1,
      "statefulSetName": "postgres-statefulset1",
      "serviceName": "dbprod1",
      "configMap": {
        "name": "postgres-configuration1"
      }
     },
     back +: {
       "replicaCount": 3,
       "deploymentName": "backend1",
       "serviceName": "backend-svc1",
       "port": 9000,
       "targetPort": 9000,
       "nodePort": 30091
     },
     front +: {
       "replicaCount": 3,
       "deploymentName": "frontend1",
       "serviceName": "frontend-svc1",
       "port": 8000,
       "targetPort": 80,
       "nodePort": 30081
     },          
  }
 }

