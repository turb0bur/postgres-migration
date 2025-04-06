# PostgreSQL Migration to AWS

This project provides scripts and Terraform configuration to:
1. Set up a local PostgreSQL database using Docker
2. Provision an AWS RDS PostgreSQL instance using Terraform
3. Migrate data from the local database to AWS RDS via a Bastion host

## Prerequisites

- Docker and Docker Compose
- Git
- Terraform
- AWS CLI configured with proper credentials
- PostgreSQL client tools (psql, pg_dump, pg_restore)
- AWS Session Manager plugin for AWS CLI
  - Install instructions: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

## Setup

1. Clone the repository:
   ```bash
   git clone --recursive https://github.com/turb0bur/postgres-migration.git
   cd postgres-migration
   ```

2. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

3. Modify the `.env` file to set your preferred database credentials and port:
   ```bash
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=postgres
   POSTGRES_PORT=5432
   ```

## Sample Databases

This project includes a submodule with various PostgreSQL sample databases from the [neondatabase-labs/postgres-sample-dbs](https://github.com/neondatabase-labs/postgres-sample-dbs) repository.

Available sample databases:
- Pagila (DVD rental store)
- Chinook (digital media store)
- Employees (company employees data)
- LEGO (sets, themes, parts)
- Netflix (shows and movies)
- Titanic (passenger data)
- World Happiness Index
- Periodic Table

## Step 1: Set Up Local PostgreSQL Database

1. Start the PostgreSQL Docker container:
   ```bash
   docker-compose up -d
   ```

2. Create and load a sample database (e.g., Lego):
   ```bash
   docker exec postgres-sample psql -U postgres -c "CREATE DATABASE lego"
   docker exec -i postgres-sample psql -U postgres -d lego < samples/lego.sql
   ```

3. Connect to the database:
   ```bash
   docker exec -it postgres-sample psql -U postgres -d lego
   ```

You can similarly load other sample databases from the `samples` directory by adjusting the commands above.

## Step 2: Provision AWS RDS PostgreSQL with Terraform

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Create a workspace based on region and environment:
   ```bash
   terraform workspace new euc1-dev  # For eu-central-1 development environment
   ```
   
   Naming convention: `{region-code}-{environment}`
   Examples:
   - `euc1-dev` (eu-central-1 development)
   - `use1-prod` (us-east-1 production)
   - `euw1-staging` (eu-west-1 staging)
   
   To list available workspaces:
   ```bash
   terraform workspace list
   ```
   
   To switch to an existing workspace:
   ```bash
   terraform workspace select euc1-dev
   ```

4. Use the workspace-specific variable files from the `terraform/workspaces` directory:
   
   The project uses region and environment-specific configuration files located in `terraform/workspaces/`.
   Each workspace has a corresponding `.tfvars` file (e.g., `euc1-dev.tfvars`).
   
   Example `euc1-dev.tfvars` contains:
   ```hcl
   region      = "eu-central-1"
   environment = "dev"
   
   vpc_settings = {
     name                 = "main-vpc"
     cidr                 = "10.20.0.0/16"
     enable_dns_support   = true
     enable_dns_hostnames = true
   }
   
   # RDS settings
   rds_instance_config = {
     name                = "postgres-db"
     engine              = "postgres"
     engine_version      = "17"
     instance_class      = "db.t3.small"
     allocated_storage   = 20
     # ... other RDS settings
   }
   
   # ... additional configuration
   ```

5. Plan your infrastructure deployment with the correct workspace variable file:
   ```bash
   terraform plan -var-file="workspaces/euc1-dev.tfvars"
   ```

6. Apply the Terraform configuration:
   ```bash
   terraform apply -var-file="workspaces/euc1-dev.tfvars"
   ```
   
   This will create:
   - VPC with public and private subnets
   - Security groups
   - RDS PostgreSQL instance
   - Bastion host (without SSH access) for accessing RDS
   - All necessary IAM roles and policies

7. Return to the root directory when done:
   ```bash
   cd ..
   ```

## Step 3: Migrate Data to AWS RDS using the Bastion Host

You can run the migration in two ways:

### Option 1: Using Terraform outputs directly

1. Run the migration script:
   ```bash
   ./scripts/migrate-to-aws.sh
   ```

### Option 2: Using environment variables

You can export Terraform outputs as environment variables before running the migration script:

1. Source the export script:
   ```bash
   source ./scripts/export-terraform-outputs.sh
   ```

2. Run the migration script:
   ```bash
   ./scripts/migrate-to-aws.sh
   ```

The script will:
- Dump the local PostgreSQL database
- Use SSM to establish port forwarding through the Bastion host
- Restore the dump to the AWS RDS instance 
- Clean up temporary files

## Accessing the Database via the Bastion Host

The Bastion host is configured to use AWS Systems Manager Session Manager for access, without enabling SSH:

1. Connect to the Bastion host:
   ```bash
   cd terraform
   aws ssm start-session --target $(terraform output -raw bastion_instance_id)
   cd ..
   ```

2. Once connected to the Bastion host, you can access the PostgreSQL database:
   ```bash
   PGPASSWORD=your_password psql -h rds_endpoint -U postgres -d postgres
   ```
   Replace `your_password` with the actual password and `rds_endpoint` with the RDS endpoint.

## Security

- The Bastion host has no SSH access; it can only be accessed via AWS Systems Manager Session Manager
- The RDS instance is in a private subnet and only accessible from the Bastion host
- All credentials are stored in AWS SSM Parameter Store with encryption

## Cleanup

To destroy the AWS resources when no longer needed:

```bash
cd terraform
terraform destroy
cd ..
```

To stop and remove the local Docker container:

```bash
docker-compose down -v
``` 