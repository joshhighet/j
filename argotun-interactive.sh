#!/usr/bin/env bash
#cloudflared dual-argo-tunnel setup [interactive] [debian]
#joshhighet
loglevel=warn
logfile=/var/log/cloudflared-https.log
sshlogfile=/var/log/cloudflared-ssh.log
sshurl=ssh://localhost:22
####################
#preliminary checks#
####################
if [ "$EUID" -ne 0 ]
  then echo "argo setup needs root!"
  exit
fi
#check response code from cloudflare
if [[ $(curl -s -I https://dash.cloudflare.com | head -n 1) = *401 ]]; then
  printf "unable to reach cloudflare to continue setup\n"
  exit
fi
#
[ -d "/etc/cloudflared" ] && echo "/etc/cloudflared already exists!" && exit
[ -d "/etc/cloudflared-ssh" ] && echo "/etc/cloudflared-ssh already exists" && exit
#
getent passwd cloudflared > /dev/null 2&>1
if [ $? -eq 0 ]; then
    printf "user cloudflared already exists\n"
    exit 0
fi
#add group "cloudflared-grp" for user "cloudflared"
addgroup cloudflared-grp \
--quiet
#add user "cloudflared" without home directory or interactive capabilities
#--disabled-login \
#--disabled-password \
adduser \
--quiet \
--gecos "" \
--ingroup cloudflared-grp \
cloudflared
#https tunnel
printf "primary FQDN [i.e web.joshhighet.com] : " && read hostname
printf "local binding URL [i.e http://localhost:80] : " && read url
url_validity=`curl -s -I --insecure $url`
#if [[ $(curl -s -I --insecure https://localhost:443 | grep 'HTTP/1.1') = *302* ]]; then
#if [[ $(netstat -apn | grep ':::443') = *LISTEN* ]]; then
if [ -z "$url_validity" ]
then
printf "\nunable to communicate with local webservice : "
echo $url | lolcat
exit 0
fi
printf "tag [i.e bikinibottom=https] - enter for no tags : " && read tag
#ssh tunnel
printf "secondary FQDN for SSH [i.e ssh.joshhighet.com] : " && read sshhostname
printf "tag [i.e bikinibottom=ssh] - enter for no tags : " && read tag
########################
#begin primary install #
########################
#printf "creating cloudflared home directory\n\n"
mkdir /etc/cloudflared
#printf "creating cloudflared-ssh home directory\n\n"
mkdir /etc/cloudflared-ssh
#printf "downloading cloudflared\n\n"
wget --quiet https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb \
-O /tmp/cloudflared.deb
#printf "downloading cloudflared-ssh\n\n"
wget --quiet https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz \
-O /etc/cloudflared-ssh/cloudflared.tgz
#printf "installing cloudflared\n\n"
sudo dpkg -i /tmp/cloudflared.deb > /dev/null
rm /tmp/cloudflared.deb
#printf "unpacking cloudflared-ssh tarball\n\n"
tar -xvf /etc/cloudflared-ssh/cloudflared.tgz -C /etc/cloudflared-ssh \
> /dev/null
rm /etc/cloudflared-ssh/cloudflared.tgz
#printf "creating cloudflared config file\n\n"
touch /etc/cloudflared/config.yml
#printf "creating cloudflared-ssh config file\n\n"
touch /etc/cloudflared-ssh/config.yml
#printf "creating cloudflared logfile\n\n"
touch $logfile
touch /etc/cloudflared/pid
#printf "creating cloudflared-ssh logfile\n\n"
touch $sshlogfile
touch /etc/cloudflared-ssh/pid
#printf "populating cloudflared config file\n\n"
echo "hostname: $hostname" > /etc/cloudflared/config.yml
echo "url: $url" >> /etc/cloudflared/config.yml
echo "loglevel: $loglevel" >> /etc/cloudflared/config.yml
echo "logfile: $logfile" >> /etc/cloudflared/config.yml
echo "tunnel_tag: $tag" >> /etc/cloudflared/config.yml
echo "pidfile: /etc/cloudflared/pid" >> /etc/cloudflared/config.yml
#printf "populating cloudflared-ssh config file\n\n"
echo "hostname: $sshhostname" > /etc/cloudflared-ssh/config.yml
echo "url: $sshurl" >> /etc/cloudflared-ssh/config.yml
echo "logfile: $sshlogfile" >> /etc/cloudflared-ssh/config.yml
echo "loglevel: $loglevel" >> /etc/cloudflared/config.yml
echo "tunnel_tag: $sshtag" >> /etc/cloudflared-ssh/config.yml
echo "pidfile: /etc/cloudflared-ssh/pid" >> /etc/cloudflared-ssh/config.yml
#printf "configuring cloudflared-ssh systemd files\n\n"
echo """[Unit]
Description=Argo Tunnel
After=network.target

[Service]
TimeoutStartSec=0
Type=notify
ExecStart=/etc/cloudflared-ssh/cloudflared --config /etc/cloudflared-ssh/config.yml --origincert /home/cloudflared/.cloudflared/cert.pem --no-autoupdate
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target""" > /etc/systemd/system/cloudflared-ssh.service
echo """[Unit]
Description=Update Argo Tunnel

[Timer]
OnUnitActiveSec=1d

[Install]
WantedBy=timers.target""" > /etc/systemd/system/cloudflared-ssh-update.timer
echo """[Unit]
Description=Update Argo Tunnel
After=network.target

[Service]
ExecStart=/bin/bash -c '/etc/cloudflared-ssh/cloudflared update; code=$?; if [ $code -eq 64 ]; then systemctl restart cloudflared-ssh; exit 0; fi; exit $code""" \
> /etc/systemd/system/cloudflared-ssh-update.service
echo """[Unit]
Description=Update Argo Tunnel
After=network.target

[Service]
ExecStart=/bin/bash -c '/etc/cloudflared-ssh/cloudflared update; code=$?; if [ $code -eq 64 ]; then systemctl restart cloudflared-ssh; exit 0; fi; exit $code'""" \
> /etc/systemd/system/cloudflared-ssh-update.service
#
chmod 644 /etc/systemd/system/cloudflared-ssh*
chown --recursive cloudflared:cloudflared-grp /etc/cloudflared
chown --recursive cloudflared:cloudflared-grp /etc/cloudflared-ssh
chown --recursive cloudflared:cloudflared-grp /var/log/cloudflared*
chown --recursive cloudflared:cloudflared-grp /etc/systemd/system/cloudflared*
chown --recursive cloudflared:cloudflared-grp /usr/local/bin/cloudflared
#printf "checking for cloudflared updates\n\n"
runuser -l cloudflared -c '/usr/local/bin/cloudflared update'
#printf "checking for cloudflared-ssh updates\n\n"
runuser -l cloudflared -c '/etc/cloudflared-ssh/cloudflared update'
#printf "authenticating argo tunnel\n\n"
runuser -l cloudflared -c '/usr/local/bin/cloudflared login'
systemctl enable cloudflared-ssh.service --quiet
systemctl enable cloudflared-ssh-update.timer --quiet
systemctl start cloudflared-ssh.service --quiet
systemctl start cloudflared-ssh-update.timer --quiet
systemctl start cloudflared-ssh-update.service --quiet
#printf "enabling cloudflared as boot-start service\n\n"
runuser -l cloudflared -c '/usr/local/bin/cloudflared service install'
