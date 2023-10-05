#!/bin/bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <node_id> <base_dir>"
    exit 1
fi

node_id="$1"
base_dir="$2"

# Ensure the path is absolute
if [[ ! "$base_dir" = /* ]]; then
    echo "please provide absolute base_dir"
    exit 1
fi

# S3 base path
s3_base_path="s3://indigo-snowflake-staging/offchain/network_feed/$node_id"

# Navigate through each 1-level subdirectory of the provided base_dir
for dir in "$base_dir"/*; do
    if [ -d "$dir" ]; then
        # Extract the directory name for the S3 path
        directory=$(basename "$dir")

        # S3 upload path
        s3_path="$s3_base_path/$directory"
        
        # Current UTC hour
        current_hour=$(date -u +"%H")

        # Find CSVs, but exclude ones matching current UTC hour
        find "$dir" -maxdepth 1 -type f -name '*.csv' ! -name "*-${current_hour}.csv" | while read -r csv_file; do
            # Compress the CSV into GZIP
            gzip "$csv_file"

            # Upload to S3
            if aws s3 cp "${csv_file}.gz" "$s3_path/"; then
                # Print the uploaded file's path
                echo "Uploaded ${csv_file}.gz to $s3_path/"
                # Remove local gzip file after successful upload
                rm "${csv_file}.gz"
            else
                echo "Failed to upload ${csv_file}.gz to S3. Keeping the local files."
            fi
        done
    fi
done
