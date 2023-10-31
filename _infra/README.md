# Geth, Teku Docker Compose

This code is intended to simplify deploying geth and teku to a new node. This code is not meant to be run from the repository. When setting up a new node, follow instructions to copy the files to the server and start up manually.

### Docker
    
1. Add `Dockerfile` and `docker-compose.yml` to the host volume root
2. Supply `GETH_REPO` and `GETH_BRANCH` into the compose args
3. Update host volume path
4. Update ports, should be fine to increment the output of losf by 1.
Do both the `ports` and the `build` args

```bash
sudo lsof -i -P -n | grep LISTEN
```

### System

1. From host volume root, set up directories for geth data,network feed, and cron logs

```bash
$ mkdir ethereum/
$ mkdir ethereum/network_feed 

$ mkdir logs

# EC2 Only
sudo yum install cronie
sudo service crond start
sudo chkconfig crond on
```

2. Install AWS CLI
3. Add AWS credentials file 
4. Add cron script 

```bash
vim <host_volume>/csv_s3_upload.sh
```

5. Setup cron job

```bash
(crontab -l 2>/dev/null; echo  "1 * * * * export PATH=$PATH:/usr/local/bin && cd <HOST_VOLUME> && sh HOST_VOLUME/csv_s3_upload.sh <NODE_ID> <HOST_VOLUME>/ethereum/network_feed/ >> <HOST_VOLUME>/logs/csv_s3_upload_job.log 2>&1") | crontab -
```

6. Build and start the containers 

```bash
$ docker-compose build geth
$ docker-compose up -d geth
$ sudo chown <SYS_USER> <HOST_VOLUME>/ethereum/jwt.hex  # give teku permissions to use jwt
$ docker-compose up -d teku
```
