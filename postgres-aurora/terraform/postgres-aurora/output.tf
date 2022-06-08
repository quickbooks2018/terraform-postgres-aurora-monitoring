output "postgres-aurora-serverless" {
  sensitive = true
  value     = module.postgres-aurora-cluster
}