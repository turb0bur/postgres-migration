#!/bin/bash

RDS_ENDPOINT=""
RDS_DB_NAME=""
RDS_USERNAME=""
RDS_PORT=""
BASTION_ID=""
RDS_PASSWORD=""
SSM_PID=""
LOCAL_PORT="54320"

function initialize_variables() {
    echo "Initializing variables from Terraform output..."
    
    if [[ -n "$TF_DB_HOST" && -n "$TF_DB_NAME" && -n "$TF_DB_USER" && -n "$TF_DB_PASSWORD" && -n "$TF_DB_PORT" && -n "$TF_BASTION_HOST_ID" ]]; then
        echo "Using environment variables for Terraform output"
        RDS_ENDPOINT=$TF_DB_HOST
        RDS_DB_NAME=$TF_DB_NAME
        RDS_USERNAME=$TF_DB_USER
        RDS_PASSWORD=$TF_DB_PASSWORD
        RDS_PORT=$TF_DB_PORT
        BASTION_ID=$TF_BASTION_HOST_ID
    else
        echo "Environment variables not found, fetching from Terraform directly"
        RDS_ENDPOINT=$(cd ../terraform && terraform output -raw db_host)
        RDS_DB_NAME=$(cd ../terraform && terraform output -json db_name | jq -r '.')
        RDS_USERNAME=$(cd ../terraform && terraform output -json db_user | jq -r '.')
        RDS_PASSWORD=$(cd ../terraform && terraform output -json db_password | jq -r '.')
        RDS_PORT=$(cd ../terraform && terraform output -raw db_port)
        BASTION_ID=$(cd ../terraform && terraform output -raw bastion_host_id)
    fi
    
    echo "Database connection details retrieved successfully."
}

function setup_ssm_port_forwarding() {
    echo "Setting up SSM port forwarding from localhost:$LOCAL_PORT to RDS..."
    
    echo "==== SSM Connection Parameters ===="
    echo "Bastion Host ID: $BASTION_ID"
    echo "RDS Endpoint: $RDS_ENDPOINT"
    echo "RDS Port: $RDS_PORT"
    echo "Local Port: $LOCAL_PORT"
    echo "=================================="
    
    aws ssm start-session \
        --target "$BASTION_ID" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "{\"host\":[\"$RDS_ENDPOINT\"],\"portNumber\":[\"$RDS_PORT\"], \"localPortNumber\":[\"$LOCAL_PORT\"]}" > /dev/null 2>&1 &
    
    SSM_PID=$!
    echo "SSM port forwarding started with PID: $SSM_PID"
    
    echo "Waiting for port forwarding to establish (10 seconds)..."
    sleep 5
    
    echo "Testing database connection..."
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d "$RDS_DB_NAME" -c "SELECT 1" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "Error: Cannot connect to the database through port forwarding."
        echo "Please check your AWS Session Manager connection and try again."
        exit 1
    else
        echo "Database connection established successfully!"
    fi
}

function cleanup_resources() {
    echo "Cleaning up resources..."
    
    if [ -n "$SSM_PID" ]; then
        kill $SSM_PID 2>/dev/null || true
        echo "SSM port forwarding terminated."
    fi
    
    rm -f temp_dump.sql 2>/dev/null || true
}

function migrate_from_docker_container() {
    local container_name="$1"
    local db_name="$2"
    local db_user="$3"
    
    echo "Checking if container $container_name exists and is running..."
    if ! docker ps | grep -q "$container_name"; then
        echo "Error: Container $container_name is not running or does not exist."
        echo "Available containers:"
        docker ps
        return 1
    fi
    
    echo "Creating dump from Docker container $container_name..."
    docker exec $container_name pg_dump -U $db_user -d $db_name > temp_dump.sql
    
    if [ $? -ne 0 ]; then
        echo "Error creating dump from Docker container."
        return 1
    fi
    
    echo "Restoring dump to RDS database: $db_name..."
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d postgres -c "CREATE DATABASE \"$db_name\" WITH OWNER = \"$RDS_USERNAME\";" 2>/dev/null
    
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d "$db_name" < temp_dump.sql
    
    if [ $? -ne 0 ]; then
        echo "Error restoring dump to RDS."
        return 1
    fi
    
    echo "Migration from Docker container completed successfully."
    echo "Created database: $db_name"
    return 0
}

function migrate_from_s3() {
    local s3_bucket="$1"
    local s3_key="$2"
    local db_name="$3"
    
    if [ -z "$db_name" ]; then
        echo "Error: Database name is required."
        return 1
    fi
    
    echo "Downloading dump from S3 bucket: $s3_bucket, key: $s3_key..."
    aws s3 cp "s3://$s3_bucket/$s3_key" temp_dump.sql
    
    if [ $? -ne 0 ]; then
        echo "Error downloading dump from S3."
        return 1
    fi
    
    echo "Restoring dump to RDS database: $db_name..."
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d postgres -c "CREATE DATABASE \"$db_name\" WITH OWNER = \"$RDS_USERNAME\";" 2>/dev/null
    
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d "$db_name" < temp_dump.sql
    
    if [ $? -ne 0 ]; then
        echo "Error restoring dump to RDS."
        return 1
    fi
    
    echo "Migration from S3 completed successfully."
    echo "Created database: $db_name"
    return 0
}

function migrate_from_local_file() {
    local file_path="$1"
    local db_name="$2"
    
    if [ -z "$db_name" ]; then
        echo "Error: Database name is required."
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found at $file_path"
        return 1
    fi
    
    echo "Restoring from local file: $file_path to database: $db_name..."
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d postgres -c "CREATE DATABASE \"$db_name\" WITH OWNER = \"$RDS_USERNAME\";" 2>/dev/null
    
    PGPASSWORD="$RDS_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$RDS_USERNAME" -d "$db_name" < "$file_path"
    
    if [ $? -ne 0 ]; then
        echo "Error restoring from local file."
        return 1
    fi
    
    echo "Migration from local file completed successfully."
    echo "Created database: $db_name"
    return 0
}

function display_menu() {
    echo "Choose migration source:"
    echo "1) Migrate from local PostgreSQL Docker container"
    echo "2) Migrate from S3 bucket"
    echo "3) Migrate from local dump file"
    echo "0) Exit"
    
    read -p "Enter your choice: " choice
    
    MIGRATED_DB_NAME=""
    
    case $choice in
        1)
            read -p "Enter container name [postgres]: " container_name
            container_name=${container_name:-postgres}
            
            read -p "Enter database name [postgres]: " db_name
            db_name=${db_name:-postgres}
            
            read -p "Enter database user [postgres]: " db_user
            db_user=${db_user:-postgres}
            
            migrate_from_docker_container "$container_name" "$db_name" "$db_user"
            migration_result=$?
            MIGRATED_DB_NAME="$db_name"
            ;;
        2)
            read -p "Enter S3 bucket name: " s3_bucket
            read -p "Enter S3 key (path to dump file): " s3_key
            read -p "Enter destination database name: " db_name
            
            migrate_from_s3 "$s3_bucket" "$s3_key" "$db_name"
            migration_result=$?
            MIGRATED_DB_NAME="$db_name"
            ;;
        3)
            read -p "Enter path to local dump file: " file_path
            read -p "Enter destination database name: " db_name
            
            migrate_from_local_file "$file_path" "$db_name"
            migration_result=$?
            MIGRATED_DB_NAME="$db_name"
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            display_menu
            ;;
    esac
    
    return $migration_result
}

function display_completion_message() {
    local db_name="$1"
    
    if [ -z "$db_name" ]; then
        db_name="$RDS_DB_NAME"
    fi
    
    echo "========================================================"
    echo "Migration completed!"
    echo ""
    echo "Your database is now available at:"
    echo "Endpoint: $RDS_ENDPOINT"
    echo "Port: $RDS_PORT"
    echo "Database: $db_name"
    echo "Username: $RDS_USERNAME"
    echo "========================================================"
}

function check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed but is required for this script."
        echo "Please install jq using your package manager."
        exit 1
    fi
}

function main() {
    trap cleanup_resources EXIT

    check_dependencies
    initialize_variables
    setup_ssm_port_forwarding

    display_menu
    migration_result=$?

    if [ $migration_result -eq 0 ]; then
        display_completion_message "$MIGRATED_DB_NAME"
    else
        echo "Migration failed. Please check the errors above and try again."
    fi
}

main "$@" 