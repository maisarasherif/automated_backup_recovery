#!/bin/bash

########################################## ENVIRONMENT VARIABLES #########################################################

# Cloud Storage Details
AZURE_STORAGE_ACCOUNT="your_storage_account"
AZURE_CONTAINER_NAME="your_container_name"
STORAGE_ACCESS_KEY="your_storage_key"

########################################################################################################################

# Check if the date is provided as an argument
if [[ -z "$1" ]]; then
  echo "ERROR: Please provide a date in YYYY-MM-DD format."
  exit 1
fi

# Validate the date format
DATE_FILTER="$1"
if ! [[ "$DATE_FILTER" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid date format. Please use YYYY-MM-DD."
  exit 1
fi

echo "Deleting blobs older than $DATE_FILTER from container: $AZURE_CONTAINER_NAME..."

# List all blobs and filter by last modified date
BLOBS_TO_DELETE=$(az storage blob list \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --container-name "$AZURE_CONTAINER_NAME" \
  --account-key "$STORAGE_ACCESS_KEY" \
  --query "[?lastModified<='$DATE_FILTER'].name" -o tsv)

if [[ -z "$BLOBS_TO_DELETE" ]]; then
  echo "No blobs older than $DATE_FILTER found."
  exit 0
fi

# Delete each blob
for BLOB in $BLOBS_TO_DELETE; do
  echo "Deleting blob: $BLOB"
  az storage blob delete \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --name "$BLOB" \
    --account-key "$STORAGE_ACCESS_KEY"
  
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to delete blob: $BLOB"
  else
    echo "Deleted: $BLOB"
  fi
done

echo "Blobs older than $DATE_FILTER have been deleted."
