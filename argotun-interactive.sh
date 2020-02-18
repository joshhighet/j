#!/usr/bin/env zsh
#joshhighet
#cloudflared dual-argo-tunnel setup [interactive] [debian]
loglevel=warn
####################
#preliminary checks#
####################
printf "checking privs\n\n"
if [ "$EUID" -ne 0 ]
  then echo "script needs root privs"
  exit
fi
#https tunnel
echo "primary FQDN [i.e bikinibottom.joshhighet.com]" && read hostname
echo "local binding URL [i.e https://localhost:8000]" && read url
echo "tag [i.e bikinibottom=https] - enter for no tags" && read tag
logfile="/var/log/cloudflared-https.log"
#ssh tunnel
echo "secondary FQDN for SSH [i.e ssh-bikinibottom.joshhighet.com]" && read sshhostname
echo "tag [i.e bikinibottom=ssh] - enter for no tags" && read tag
sshurl="ssh://localhost:22"
sshlogfile="/var/log/cloudflared-ssh.log"
########################
#begin primary install #
########################
printf "creating cloudflared home directory\n\n"
[ -d "/etc/cloudflared" ] && echo "/etc/cloudflared already exists" && exit
mkdir /etc/cloudflared

printf "downloading cloudflared\n\n"
wget --quiet https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb \
-O /etc/cloudflared/cloudflared.deb

printf "installing cloudflared\n\n"
sudo dpkg -i /etc/cloudflared/[TBD]

printf "creating cloudflared config file\n\n"
touch /etc/cloudflared/config.yml

printf "creating cloudflared logfile\n\n"
touch $logfile

printf "populating cloudflared config file\n\n"
echo "hostname: $hostname" > /etc/cloudflared/config.yml
echo "url: $url" >> /etc/cloudflared/config.yml
echo "loglevel: $loglevel" >> /etc/cloudflared/config.yml
echo "logfile: $logfile" >> /etc/cloudflared/config.yml
echo "tunnel_tag: $tag" >> /etc/cloudflared/config.yml
echo "pidfile: /etc/cloudflared/pid" >> /etc/cloudflared/config.yml

printf "checking for cloudflared updates\n\n"
/usr/local/bin/cloudflared update

printf "authenticating argo tunnel\n\n"
/usr/local/bin/cloudflared login

printf "enabling cloudflared as boot-start service\n\n"
/usr/local/bin/cloudflared service install
######################################
#begin secondary cloudflared install #
######################################
printf "creating cloudflared-ssh home directory\n\n"
[ -d "/etc/cloudflared-ssh" ] && echo "/etc/cloudflared-ssh already exists" && exit
mkdir /etc/cloudflared-ssh

printf "downloading cloudflared-ssh\n\n"
wget --quiet https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz \
-O /etc/cloudflared-ssh/cloudflared.tgz

printf "unpacking cloudflared-ssh tarball\n\n"
tar -xvf /etc/cloudflared-ssh/cloudflared.tgz -C /etc/cloudflared-ssh

printf "creating cloudflared-ssh config file\n\n"
touch /etc/cloudflared-ssh/config.yml

printf "creating cloudflared-ssh logfile\n\n"
touch $sshlogfile

printf "populating cloudflared-ssh config file\n\n"
echo "hostname: $sshhostname" > /etc/cloudflared-ssh/config.yml
echo "url: $sshurl" >> /etc/cloudflared-ssh/config.yml
echo "logfile: $logfile" >> /etc/cloudflared-ssh/config.yml
echo "loglevel: $loglevel" >> /etc/cloudflared/config.yml
echo "tunnel_tag: $sshtag" >> /etc/cloudflared-ssh/config.yml
echo "pidfile: /etc/cloudflared-ssh/pid" >> /etc/cloudflared-ssh/config.yml

printf "checking for cloudflared-ssh updates\n\n"
/etc/cloudflared-ssh/cloudflared update

printf "configuring cloudflared-ssh systemd files\n\n"

echo "[Unit]
Description=Argo Tunnel
After=network.target

[Service]
TimeoutStartSec=0
Type=notify
ExecStart=/etc/cloudflared-ssh/cloudflared --config /etc/cloudflared-ssh/config.yml --origincert /home/josh/.cloudflared/cert.pem --no-autoupdate
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/cloudflared-ssh.service

echo "[Unit]
Description=Update Argo Tunnel

[Timer]
OnUnitActiveSec=1d

[Install]
WantedBy=timers.target" > /etc/systemd/system/cloudflared-ssh-update.timer

echo "[Unit]
Description=Update Argo Tunnel
After=network.target

[Service]
ExecStart=/bin/bash -c '/etc/cloudflared-ssh/cloudflared update; code=$?; if [ $code -eq 64 ]; then systemctl restart cloudflared-ssh; exit 0; fi; exit $code" \
> /etc/systemd/system/cloudflared-ssh-update.service

chmod 644 /etc/systemd/system/cloudflared-ssh.service
chmod 644 /etc/systemd/system/cloudflared-ssh-update.timer
chmod 644 /etc/systemd/system/cloudflared-ssh-update.service
systemctl enable cloudflared-ssh.service
systemctl enable cloudflared-ssh-update.timer
systemctl enable cloudflared-ssh-update.service
systemctl start cloudflared-ssh.service
systemctl start cloudflared-ssh-update.timer
systemctl start cloudflared-ssh-update.service
systemctl status cloudflared
systemctl status cloudflared-ssh
