#!/bin/bash

cd /node-a
docker build --no-cache --build-arg GO_IMAGE=golang:1.19 --build-arg GETH_REPO=https://${GITHUB_TOKEN}@github.com/indigodata/geth.git --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest .
docker-compose down
docker-compose up -d teku geth-network-feed

cd /node-b
docker-compose down
docker-compose up -d teku geth-network-feed