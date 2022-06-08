terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #   version = "4.7.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = "~> 1.0"
}


#### Backend ###
## S3
################
#
#terraform {
#  backend "s3" {
#    bucket         = "cloudgeeks-terraform"
#    key            = "env/prod/vpc.tfstate"
#    region         = "us-east-1"
#  }
#}

locals {
  vpc_name                = "postgres-aurora-vpc"
  cluster_name            = "aurora-db-postgres"
  min_capacity            = 2
  max_capacity            = 5
  monitoring_interval     = 60
  engine_version          = "13.6"
  instance_class          = "db.t3.medium"
  master_username         = var.cluster_master_username
  master_password         = var.cluster_master_password
  vpc_id                  = module.vpc.vpc_id
  db_subnets              = [module.vpc.public_subnets][0]
  allowed_security_group  = [module.vpc.default_security_group_id]
  deletion_protection     = true
  publicly_accessible     = true
  backup_retention_period = 7
  tags    = {
    environment = "dev"
  }
}



######
# Vpc
######
module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name           = local.vpc_name

  cidr           = "10.60.0.0/16"
  azs            = ["us-east-1a", "us-east-1b", "us-east-1c", ]
  public_subnets = ["10.60.16.0/20", "10.60.32.0/20", "10.60.48.0/20"]


  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false

  create_database_subnet_group           = false
  create_database_subnet_route_table     = false
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    public-vpc = "true"
  }


}

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = local.engine_version
}


module "postgres-aurora-cluster" {
  source  = "registry.terraform.io/terraform-aws-modules/rds-aurora/aws"
  version = "7.1.0"

  name                       = local.cluster_name
  engine                     = data.aws_rds_engine_version.postgresql.engine
  engine_mode                = "provisioned"
  storage_encrypted          = true
  publicly_accessible        = local.publicly_accessible



  master_username       = local.master_username
  master_password       = local.master_password
  deletion_protection   = local.deletion_protection



  vpc_id                  = local.vpc_id
  subnets                 = local.db_subnets
  create_security_group   = false
  allowed_security_groups = local.allowed_security_group
  backup_retention_period = local.backup_retention_period

  monitoring_interval = local.monitoring_interval

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.postgresql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql.id

  autoscaling_enabled      = false
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 5

  instance_class = local.instance_class
  instances = {
    one = {
      publicly_accessible = local.publicly_accessible
    }
    two = {
      publicly_accessible = local.publicly_accessible
    }
  }

  tags = local.tags

}


resource "aws_db_parameter_group" "postgresql" {
  name        = "aurora-db-postgres13-parameter-group"
  family      = "aurora-postgresql13"
  description = "aurora-db-postgres13-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "postgresql" {
  name        = "aurora-postgres13-cluster-parameter-group"
  family      = "aurora-postgresql13"
  description = "aurora-postgres13-cluster-parameter-group"
}
