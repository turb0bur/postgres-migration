#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed but is required to handle sensitive Terraform outputs."
    echo "Please install jq using your package manager."
    exit 1
fi

echo "Exporting Terraform outputs as environment variables..."

export TF_DB_HOST=$(cd ../terraform && terraform output -raw db_host)
export TF_DB_NAME=$(cd ../terraform && terraform output -json db_name | jq -r '.')
export TF_DB_USER=$(cd ../terraform && terraform output -json db_user | jq -r '.')
export TF_DB_PASSWORD=$(cd ../terraform && terraform output -json db_password | jq -r '.')
export TF_DB_PORT=$(cd ../terraform && terraform output -raw db_port)
export TF_BASTION_HOST_ID=$(cd ../terraform && terraform output -raw bastion_host_id)

echo "Environment variables exported successfully!"
echo "TF_DB_HOST=$TF_DB_HOST"
echo "TF_DB_NAME=$TF_DB_NAME"
echo "TF_DB_USER=$TF_DB_USER"
echo "TF_DB_PASSWORD=********"
echo "TF_DB_PORT=$TF_DB_PORT"
echo "TF_BASTION_HOST_ID=$TF_BASTION_HOST_ID"

echo ""
echo "These variables are only available in the current shell session."
echo "Source this script before running other scripts: source ./scripts/export-terraform-outputs.sh" 