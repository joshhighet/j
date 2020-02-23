#!/usr/bin/env bash
#intended for use with github.com/joshhighet/j/argotunnel.sh
#joshhighet
canaryextip=127.0.0.1
#
printf "primary FQDN [i.e canary.joshhighet.com] : " && read canarydomain
sudo apt-get install -y \
python-pip \
python-dev \
libyaml-dev \
docker-compose
git clone https://github.com/thinkst/canarytokens-docker
cd canarytokens-docker
canarydir=`pwd`
mv switchboard.env.dist switchboard.env
mv frontend.env.dist frontend.env
sed -i 's/CANARY_PUBLIC_IP=/CANARY_PUBLIC_IP='$canaryextip'/g' switchboard.env
sed -i 's/#CANARY_PUBLIC_DOMAIN=/CANARY_PUBLIC_DOMAIN='$canarydomain'/g' switchboard.env
sed -i 's/CANARY_ALERT_EMAIL_FROM_ADDRESS=/#CANARY_ALERT_EMAIL_FROM_ADDRESS=/g' switchboard.env
sed -i 's/CANARY_ALERT_EMAIL_FROM_DISPLAY=/#CANARY_ALERT_EMAIL_FROM_DISPLAY=/g' switchboard.env
sed -i 's/CANARY_ALERT_EMAIL_SUBJECT=/#CANARY_ALERT_EMAIL_SUBJECT=/g' switchboard.env
sed -i 's/CANARY_DOMAINS=localhost/CANARY_DOMAINS='$canarydomain'/g' frontend.env
sed -i 's/CANARY_NXDOMAINS=yourdomain.com/#CANARY_NXDOMAINS=nullptr.'$canarydomain'/g' frontend.env
sed -i 's/ubuntu:16.04/ubuntu:18.04/g' canarytokens/Dockerfile
#not utilising DNS canaries - shift ports so mainstream resolution is not tampered with
sed -i 's/53:53/5300:5300/g' docker-compose.yml
#hugepages
sudo bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
sed -r 's/GRUB_CMDLINE_LINUX_DEFAULT="[a-zA-Z0-9_= ]*/& transparent_hugepage=never/' /etc/default/grub \
| sudo tee /etc/default/grub
#overcommit_mem
sudo echo "vm.overcommit_memory = 1" | tee /etc/sysctl.conf
sudo sysctl vm.overcommit_memory=1
sudo update-grub
echo """[Unit]
Description=Docker Compose Application Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$canarydir
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target""" \
> /etc/systemd/system/canarytokens.service 1>/dev/null
systemctl start canarytokens --quiet
systemctl enable canarytokens --quiet
