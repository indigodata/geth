#!/bin/bash

# ec2
sudo yum install cronie
sudo service crond start
sudo chkconfig crond on

mkdir -p /home/ec2-user/logs/
# aws viginia
(crontab -l 2>/dev/null; echo  "1 * * * * export PATH=$PATH:/usr/local/bin && cd /home/ec2-user/geth && sh /home/ec2-user/geth/_infra/csv_s3_upload.sh aws-virginia-1 /home/ec2-user/ethereum/network_feed/ >> /home/ec2-user/logs/csv_s3_upload_job.log 2>&1") | crontab -

# aws korea 
(crontab -l 2>/dev/null; echo  "1 * * * * export PATH=$PATH:/usr/local/bin && cd /home/ec2-user/geth && sh /home/ec2-user/geth/_infra/csv_s3_upload.sh aws-korea-1 /home/ec2-user/ethereum/network_feed/ >> /home/ec2-user/logs/csv_s3_upload_job.log 2>&1") | crontab -

# hetzner
(crontab -l 2>/dev/null; echo  "1 * * * * export PATH=$PATH:/usr/local/bin && cd /home/indigo/geth && sh /home/indigo/geth/_infra/csv_s3_upload.sh hetzner-finland-2 /ssd/indigo/ethereum/geth_data/network_feed/ >> /home/indigo/logs/csv_s3_upload_job.log 2>&1") | crontab -
