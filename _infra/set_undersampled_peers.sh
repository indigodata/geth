#!/bin/bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <node_region[, node_region_2]> <data_dir>"
    exit 1
fi

NODE_REGION=$1
DATA_DIR=$2

# Step 1: Download the file from S3
aws s3 cp s3://indigo-snowflake-staging/offchain/export/undersampled_peers/undersampled_peers.csv.gz ${DATA_DIR}/

# Step 2: Decompress the file
yes n | gzip -d ${DATA_DIR}/undersampled_peers.csv.gz

# Prepare the configuration file path
CONFIG_FILE="${DATA_DIR}/geth-config.toml"

# Overwrite the file with a basic structure
printf "[Node.P2P]\nBootstrapNodes = [\n]\nStaticNodes = []\nTrustedNodes = [\n]" > "$CONFIG_FILE"

# Count the number of eligible lines
ELIGIBLE_LINES=$(awk -v region="$NODE_REGION" -F, '$1 == region' ${DATA_DIR}/undersampled_peers.csv | wc -l)

# Temporary file to hold lines matching $NODE_REGION
MATCHING_LINES_FILE=$(mktemp)

# Filter lines by $NODE_REGION (which may contain multiple regions) and write them to a temporary file
awk -v region="$NODE_REGION" -F, 'BEGIN {
    split(region, regions, ",");
    for (i in regions) {
        # Remove potential leading and trailing spaces in each region name
        gsub(/^ *| *$/, "", regions[i]);
    }
}
{
    for (i in regions) {
        if ($1 == regions[i]) {
            print "  \"enode://" $2 "\"";
            next;
        }
    }
}' ${DATA_DIR}/undersampled_peers.csv > "$MATCHING_LINES_FILE"

# Count the number of eligible lines
ELIGIBLE_LINES=$(wc -l < "$MATCHING_LINES_FILE")

SAMPLED_RECORDS=$(shuf -n 50 "$MATCHING_LINES_FILE" | sort -u | paste -sd, -)

# Backup existing config file
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Replace or append BootstrapNodes in the config file
awk -v rs="$SAMPLED_RECORDS" '
    BEGIN {
        # Split the SAMPLED_RECORDS into an array elements, using comma as delimiter
        n = split(rs, elements, ",");
    }
    /BootstrapNodes = \[/ || /TrustedNodes = \[/ {
        print;
        # Loop through the elements array and print each element on a new line
        for (i = 1; i <= n; i++) {
            # Trim leading and trailing whitespace
            gsub(/^ *| *$/, "", elements[i]);
            print "  " elements[i] (i < n ? "," : "");
        }
        print "]";
        skip = 1;
        next;
    }
    /StaticNodes = \[/ { skip = 0 }
    skip { next }
    { print }
' "${CONFIG_FILE}.bak" > "$CONFIG_FILE"

# Clean up the downloaded and decompressed files
rm ${DATA_DIR}/undersampled_peers.csv

echo "Config file updated."
