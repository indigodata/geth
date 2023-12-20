#!/bin/bash

# Check if node_dir argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [node directory]"
    exit 1
fi

# Assign the first argument to NODE_DIR
NODE_DIR=$1

# Execute the commands
cd $NODE_DIR
docker-compose restart teku geth-network-feed
