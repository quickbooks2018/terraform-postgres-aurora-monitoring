# aws-rds-postgres-aurora-monitoring

https://cloudgeeks.ca

```docker-compose
docker-compose up -d
```
- aurora-db-connection

```aurora-db-connection
  psql --host=aurora-db-postgres.cluster-ctc8dxvrs5l4.us-east-1.rds.amazonaws.com --port=5432 --username=dbadmin  --password --dbname=postgres
```

### postgres_exporter

- https://github.com/prometheus-community/postgres_exporter

- https://github.com/prometheus-community/postgres_exporter/blob/master/queries.yaml

### README.md
- https://github.com/prometheus-community/postgres_exporter#readme
