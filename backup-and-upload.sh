#!/bin/bash


########################################## ENVIRONMENT VARIABLES #########################################################

BACKUP_DEST="/home/azureuser/backups"                     # DESTINATION DIRECTORY OF THE ARCHIVE
BACKUP_FILE="backup-$(date +%Y-%m-%d-%H-%M).tar.gz"       # ARCHIVE NAME
BACKUP_SRC=" "                                            # PATH OF THE DIRECTORY TO BE ARCHIVED (SOURCE)

# Cloud Storage Details
AZURE_STORAGE_ACCOUNT=" "
AZURE_CONTAINER_NAME=" "
STORAGE_ACCESS_KEY=" "
########################################################################################################################

# Ensure necessary variables are set
if [[ -z "$BACKUP_SRC" || -z "$AZURE_STORAGE_ACCOUNT" || -z "$AZURE_CONTAINER_NAME" || -z "$STORAGE_ACCESS_KEY" ]]; then
  echo "ERROR: One or more required environment variables are not set."
  exit 1
fi

# Ensure the backup directory exists. if not, create one.
mkdir -p $BACKUP_DEST

# Compress the directory
echo "Compressing directory $BACKUP_SRC..."
tar -czf $BACKUP_DEST/$BACKUP_FILE $BACKUP_SRC
if [[ $? -ne 0 ]]; then
  echo "ERROR: Failed to compress directory."
  exit 1
fi


# Upload the compressed file to Azure Blob Storage
echo "Uploading backup to Azure Blob Storage..."
az storage blob upload \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --container-name $AZURE_CONTAINER_NAME \
  --name $BACKUP_FILE  \
  --file $BACKUP_DEST/$BACKUP_FILE \
  --account-key $STORAGE_ACCESS_KEY


if [[ $? -eq 0 ]]; then
  echo "Backup has been successfully compressed and uploaded to Azure Blob Storage!"
else
  echo "ERROR: Upload to Azure Blob Storage failed."
  exit 1
fi
