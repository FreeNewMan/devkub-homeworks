{
  components: {
  "db": {
    "image": {
      "repository": "postgres",
      "tag": "13-alpine"
    },
    "port": 5432,
    "credentials": {
      "POSTGRES_DB": "news",
      "POSTGRES_USER": "postgres",
      "POSTGRES_PASSWORD": "postgres"
    }
  },
  "back": {
    "image": {
      "repository": "lutovp/test-backend",
      "tag": "0.0.1"
    }
  },
  "front": {
    "image": {
      "repository": "lutovp/test-frontend",
      "tag": "0.0.7"
    }
  }
  },
}
