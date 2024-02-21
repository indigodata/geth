REMOTE_HOST=ovh-london-1

ssh $REMOTE_HOST 'bash -s' <<EOF > "${REMOTE_HOST}_setup_log.txt" 2>&1
    sudo mkdir /node-a
    # sudo mkdir /node-b # This is created by the ovh setup script to mount on the second nvme disk
    sudo chown -R ubuntu:ubuntu /node-a
    sudo chown -R ubuntu:ubuntu /node-b

    # Setup node directories
    mkdir -p /node-a/ethereum/network_feed
    mkdir -p /node-b/ethereum/network_feed
    openssl rand -hex 32 | tr -d "\n" > /node-a/ethereum/jwt.hex
    openssl rand -hex 32 | tr -d "\n" > /node-b/ethereum/jwt.hex
    
    # Directions from https://docs.docker.com/engine/install/ubuntu/

      # Add Docker's official GPG key:
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

      # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

      # Install Docker Compose
        sudo apt install -y docker-compose

      # Add user to docker group
        sudo usermod -aG docker ubuntu

    # Configure Datadog
    HOSTNAME=ovh-london-1
    DD_API_KEY=<DD_API_KEY>
    DD_HOSTNAME=${HOSTNAME} DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${DD_API_KEY} DD_SITE="us5.datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

    sudo sh -c 'echo \
    "process_config:
      process_collection:
        enabled: true
      container_collection:
        enabled: true
    " >> /etc/datadog-agent/datadog.yaml'

    sudo usermod -aG docker dd-agent
    sudo systemctl restart datadog-agent

EOF

wait

# Send files to remote host
scp ./_infra/docker-compose.yml $REMOTE_HOST:/node-a/
scp ./_infra/docker-compose-b.yml $REMOTE_HOST:/node-b/docker-compose.yml
scp ./_infra/Dockerfile $REMOTE_HOST:/node-a/
scp ./_infra/Dockerfile $REMOTE_HOST:/node-b/
scp ./_infra/csv_s3_upload.sh $REMOTE_HOST:/home/ubuntu/
scp ./_infra/cycle_peers.sh $REMOTE_HOST:/home/ubuntu/

# Start node-a with snapsync
ssh $REMOTE_HOST
cd /node-a
docker-compose up -d teku geth-snapsync

# Setup AWS CLI
sudo apt install -y awscli
aws configure set aws_access_key_id [aws_access_key_id]
aws configure set aws_secret_access_key [aws_secret_access_key]
aws configure set default.region us-east-2

# Setup cron
mkdir -p /home/ubuntu/logs/
HOSTNAME=ovh-london-1

  # Upload CSVs to S3 every hour
  (crontab -l 2>/dev/null; echo  "1 * * * * sh /home/ubuntu/csv_s3_upload.sh ${HOSTNAME}a /node-a/ethereum/network_feed/ >> /home/ubuntu/logs/node_a_s3_upload.log 2>&1") | crontab -
  (crontab -l 2>/dev/null; echo  "1 * * * * sh /home/ubuntu/csv_s3_upload.sh ${HOSTNAME}b /node-b/ethereum/network_feed/ >> /home/ubuntu/logs/node_b_s3_upload.log 2>&1") | crontab -

  # Cycle peers every 12 hours
  (crontab -l 2>/dev/null; echo  "0 <0,12 local> * * * sh /home/ubuntu/cycle_peers.sh /node-a >> /home/ubuntu/logs/cycle_peers.log 2>&1") | crontab - # Odd days
  (crontab -l 2>/dev/null; echo  "0 <6,18 local> * * * sh /home/ubuntu/cycle_peers.sh /node-b >> /home/ubuntu/logs/cycle_peers.log 2>&1") | crontab - # Even days

#### WAIT FOR SNAPSYNC TO FINISH ####

# When snapsync is done, copy node-a's data to node-b
cd /node-a
docker-compose down
nohup sudo cp -r /node-a/ethereum/geth /node-b/ethereum/ &

# Build network feed image #
docker build --build-arg GO_IMAGE=golang:1.22 --build-arg GETH_REPO=https://${GITHUB_TOKEN}@github.com/indigodata/geth.git --build-arg GETH_BRANCH=indigo -t geth-network-feed:latest .

#### WAIT FOR COPY TO FINISH ####

# Restart nodes
cd /node-a
docker-compose up -d teku geth-network-feed
cd /node-b
docker-compose up -d teku geth-network-feed
