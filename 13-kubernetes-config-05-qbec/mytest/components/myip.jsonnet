[
{
  "kind": "Service",
  "apiVersion": "v1",
  "metadata": {
    "name": "external-svc"
  },
  "spec": {
    "ports": [
      {
        "name": "web",
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80
      }
    ]
  }
},

{
  "kind": "Endpoints",
  "apiVersion": "v1",
  "metadata": {
    "name": "external-svc"
  },
  "subsets": [
    {
      "addresses": [
        {
          "ip": "34.160.111.145" # ifconfig.me
        }
      ],
      "ports": [
        {
          "port": 80,
          "name": "web"
        }
      ]
    }
  ]
}

]