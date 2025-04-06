terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90"
    }
  }

  backend "s3" {
    bucket               = "turb0bur-terraform-state"
    key                  = "postgres-migration/terraform.tfstate"
    region               = "eu-central-1"
    workspace_key_prefix = "env"
    use_lockfile         = true
  }
}
