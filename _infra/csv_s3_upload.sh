#!/bin/bash

# Current UTC hour
current_hour=$(date -u +"%H")

# Base directory
base_dir=~/data

# S3 path
s3_path="s3://indigo/offchain"

# Navigate through each 1-level subdirectory of ~/data/
for dir in "$base_dir"/*; do
    if [ -d "$dir" ]; then
        # Move to directory
        cd "$dir"

        # Find CSVs, but exclude ones matching current UTC hour
        find . -maxdepth 1 -type f -name '*.csv' ! -name "*-${current_hour}.csv" | while read csv_file; do
            # Compress the CSV into ZIP
            zip "${csv_file}.zip" "$csv_file"

            # Upload to S3
            if aws s3 cp "${csv_file}.zip" "$s3_path/"; then
                # Remove local zip and original CSV file after successful upload
                rm "${csv_file}.zip" "$csv_file"
            else
                echo "Failed to upload ${csv_file}.zip to S3. Keeping the local files."
            fi
        done

        # Return to base directory
        cd "$base_dir"
    fi
done
