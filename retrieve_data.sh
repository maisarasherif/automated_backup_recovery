#!/bin/bash

########################################## ENVIRONMENT VARIABLES #########################################################

RESTORE_DEST="/home/azureuser/restore"                      # Destination directory for restored files


# Cloud Storage Details
AZURE_STORAGE_ACCOUNT="storage account name"
AZURE_CONTAINER_NAME="storage container name"
STORAGE_ACCESS_KEY="your access key"
########################################################################################################################

# Ensure necessary variables are set
if [[ -z "$AZURE_STORAGE_ACCOUNT" || -z "$AZURE_CONTAINER_NAME" || -z "$STORAGE_ACCESS_KEY" ]]; then
  echo "ERROR: One or more required environment variables are not set."
  exit 1
fi

# Ensure the restore destination directory exists
mkdir -p "$RESTORE_DEST"

# Check for optional date input
DATE_FILTER="$1"

if [[ -z "$DATE_FILTER" ]]; then
  # No date provided, retrieve the latest blob
  echo "No date provided. Retrieving the latest backup from Azure Blob Storage..."
  TARGET_BLOB=$(az storage blob list \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --account-key "$STORAGE_ACCESS_KEY" \
    --query "sort_by([].{name: name, lastModified: properties.lastModified}, &lastModified)[-1].name" \
    --output tsv)
else
  # Date provided, attempt to find the closest matching blob
  echo "Searching for a backup matching the date: $DATE_FILTER..."
  TARGET_BLOB=$(az storage blob list \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --account-key "$STORAGE_ACCESS_KEY" \
    --query "[?starts_with(properties.lastModified, '$DATE_FILTER')].name | [-1]" \
    --output tsv)
  
  if [[ -z "$TARGET_BLOB" ]]; then
    echo "ERROR: No backup found for the specified date: $DATE_FILTER."
    exit 1
  else
    echo "Found backup: $TARGET_BLOB"
  fi
fi

# Proceed to download the specified blob
RESTORE_FILE="$TARGET_BLOB"
az storage blob download \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --container-name "$AZURE_CONTAINER_NAME" \
  --name "$TARGET_BLOB" \
  --file "$RESTORE_DEST/$RESTORE_FILE" \
  --account-key "$STORAGE_ACCESS_KEY"

if [[ $? -ne 0 ]]; then
  echo "ERROR: Download failed."
  exit 1
else
  echo "Backup successfully downloaded to $RESTORE_DEST/$RESTORE_FILE."
fi

# Extract the backup
echo "Extracting backup..."
tar -xzf "$RESTORE_DEST/$RESTORE_FILE" -C "$RESTORE_DEST"
if [[ $? -eq 0 ]]; then
  echo "Backup has been successfully extracted to $RESTORE_DEST."
else
  echo "ERROR: Extraction failed."
  exit 1
fi
