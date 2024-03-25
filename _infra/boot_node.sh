#!/bin/bash

# Check for required arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <node_region>"
    exit 1
fi

NODE_REGION=$1

# Step 1: Download the file from S3
aws s3 cp s3://indigo-snowflake-staging/offchain/export/boot_node/boot_node.csv.gz ./_infra/

# Step 2: Decompress the file
yes n | gzip -d ./_infra/boot_node.csv.gz

# Prepare the configuration file path
CONFIG_FILE="./_infra/geth-config.toml"

# Overwrite the file with a basic structure
printf "[Node.P2P]\nBootstrapNodes = [\n]\nStaticNodes = []\nTrustedNodes = []" > "$CONFIG_FILE"

# Count the number of eligible lines
ELIGIBLE_LINES=$(awk -v region="$NODE_REGION" -F, '$1 == region' ./_infra/boot_node.csv | wc -l)

# Generate random line numbers and write to a temp file
RANDOM_LINES_FILE=$(mktemp)
awk -v max="$ELIGIBLE_LINES" 'BEGIN { 
    srand(); 
    for (i = 0; i < 50; i++) { 
        n = int(rand() * max) + 1; 
        print n 
    }
}' | sort -nu > "$RANDOM_LINES_FILE"

# Extract the selected lines based on random line numbers
SAMPLED_RECORDS=$(awk -v region="$NODE_REGION" -F, 'NR == FNR { lines[$1]; next } $1 == region && FNR in lines { print "  \"enode://" $2 "\"" }' "$RANDOM_LINES_FILE" ./_infra/boot_node.csv | paste -sd, -)

# Cleanup the temporary random lines file
rm "$RANDOM_LINES_FILE"

# Backup existing config file
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Replace or append BootstrapNodes in the config file
awk -v rs="$SAMPLED_RECORDS" '
    BEGIN { skip = 0 }
    /BootstrapNodes = \[/ {
        print;
        print rs;
        print "]";
        skip = 1;
        next;
    }
    /StaticNodes = \[/ { skip = 0 }
    skip { next }
    { print }
' "${CONFIG_FILE}.bak" > "$CONFIG_FILE"

# Clean up the downloaded and decompressed files
rm ./_infra/boot_node.csv

echo "Config file updated."
