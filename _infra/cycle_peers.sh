#!/bin/bash

# Check if node_dir argument is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <node directory> <data directory> <node region>"
    exit 1
fi

# Assign the first argument to NODE_DIR
NODE_DIR=$1
DATA_DIR=$2
NODE_REGION=$3

# Execute the commands
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
bash ${SCRIPT_DIR}/set_boot_nodes.sh $NODE_REGION $DATA_DIR

cd $NODE_DIR
docker-compose restart teku geth-network-feed
