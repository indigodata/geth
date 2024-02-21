#!/bin/bash

# OVH node a
hosts=(
    ovh-quebec-1
    ovh-oregon-1
    ovh-france-1
    ovh-virginia-1
    ovh-london-1
    ovh-australia-1
    ovh-singapore-1
    ovh-mumbai-1
)

GITHUB_TOKEN=""

for host in "${hosts[@]}"; do
    echo "Processing $host"

    # Run commands on remote host
    ssh "$host" << EOF > "${host}_log.txt" 2>&1 &

cd /node-a
docker build --no-cache --build-arg GO_IMAGE=golang:1.22 --build-arg GETH_REPO=https://$GITHUB_TOKEN@github.com/indigodata/geth.git --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest - < Dockerfile
docker-compose down --timeout=300
docker-compose up -d teku geth-network-feed

EOF
done

wait
echo "OVH node-a updates complete"

# OVH node-b
two_node_hosts=(
    ovh-quebec-1
    ovh-oregon-1
    ovh-france-1
    ovh-virginia-1
    ovh-london-1
)

for host in "${two_node_hosts[@]}"; do
    echo "Processing $host"

    # Run commands on remote host
    ssh "$host" << 'EOF' > "${host}_log.txt" 2>&1 &
cd /node-b
docker-compose down --timeout=300
docker-compose up -d teku geth-network-feed
EOF
done

wait
echo "OVH node-b updates complete"


# AWS nodes
aws_hosts=(
    aws-virginia-1
    aws-korea-1
)

for host in "${aws_hosts[@]}"; do
    echo "Processing $host"

    # Run commands on remote host
    ssh "$host" << EOF > "${host}_log.txt" 2>&1 &
        docker build --no-cache --build-arg GO_IMAGE=golang:1.22 \
            --build-arg GETH_REPO=https://$GITHUB_TOKEN@github.com/indigodata/geth.git \
            --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest - < Dockerfile
        docker-compose down --timeout=300
        docker-compose up -d teku geth-network-feed
EOF
done
wait

echo "AWS node updates complete"


# Hetzner nodes
ssh hetzner-finland-1-indigo << EOF > "hetzner-finland-1_log.txt" 2>&1 &
    cd /ssd/polygon/geth_indigo
    docker build --no-cache --build-arg GO_IMAGE=golang:1.22 \
        --build-arg GETH_REPO=https://$GITHUB_TOKEN@github.com/indigodata/geth.git \
        --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest - < Dockerfile
    docker-compose down --timeout=300
    docker-compose up -d teku geth-network-feed
EOF

ssh hetzner-finland-2-ledgersense << EOF > "hetzner-finland-2_log.txt" 2>&1 &
    cd /ssd/indigo/ethereum/
    docker build --no-cache --build-arg GO_IMAGE=golang:1.22 \
        --build-arg GETH_REPO=https://$GITHUB_TOKEN@github.com/indigodata/geth.git \
        --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest - < Dockerfile
    docker-compose down --timeout=300
    docker-compose up -d teku geth-network-feed
EOF
wait

echo "Hetzner node updates complete"