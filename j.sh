####################
#joshhhighet basevm#
#################################################################################
#mkdir /tmp/j && git clone https://github.com/joshhighet/j.git /tmp/j && cd /tmp/j && chmod +x j.sh && ./j.sh
#################################################################################
if ! [ "$(id -u)" = 0 ]; then
  printf "j.sh needs root!"
  exit 0
fi
#################################################################################
printf "\n"
sudo echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE !$H+H*' > /etc/motd
adduser josh --quiet --gecos ""
printf "\n"
usermod -aG sudo josh
runuser -l josh -c 'mkdir /home/josh/.ssh'
runuser -l josh -c 'touch /home/josh/.ssh/authorized_keys'
######################################
#########WAF-BYPASS-CONDITION#########
#(http.user_agent contains "curl/"####
#and http.request.method eq "GET"#####
#and http.host eq "joshhighet.com"####
#and http.request.uri.path eq "/ssh")#
######################################
runuser -l josh -c 'curl -s -L joshhighet.com/ssh > /home/josh/.ssh/authorized_keys'
printf "🔒 id_rsa\n"
runuser -l josh -c 'ssh-keygen -t rsa -b 4096 -C "autodep@joshhighet.com" -f /home/josh/.ssh/id_rsa -q'
curl  -s -C - https://pkg.cloudflare.com/pubkey.gpg | sudo apt-key add -
printf "\n"
sudo echo 'deb http://pkg.cloudflare.com/ xenial main' >> /etc/apt/sources.list.d/cloudflare-main.list
sudo apt-get -qq update -y > /dev/null
sudo apt-get -qq upgrade -y > /dev/null
sudo apt-get install -y \
jq \
ufw \
zsh \
nmap \
tree \
cowsay \
lolcat \
tcpdump \
python3 \
torsocks \
fail2ban \
unattended-upgrades \
-qq > /dev/null
sudo apt-get -qq autoclean -y > /dev/null
sudo apt-get -qq autoremove -y > /dev/null
cat /tmp/j/alias.zshrc >> /home/josh/.bashrc
chown -R josh:josh /home/josh
source /home/josh/.bashrc
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo hostnamectl set-hostname josh
#sudo hostnamectl set-hostname `date +%s | shasum -a 512 | base64 | head -c 8`
runuser -l josh -c 'echo "curl -s ipinfo.io | jq .ip,.city,.country,.org -r | cowsay | lolcat" >> /home/josh/.bashrc'
runuser -l josh -c 'touch /home/josh/.hushlogin'
wget --quiet -P /tmp https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb
sudo dpkg -i /tmp/cloudflared-stable-linux-amd64.deb > /dev/null
/usr/local/bin/cloudflared update
timedatectl set-timezone Pacific/Auckland
runuser -l josh -c 'touch /home/josh/.hushlogin'
runuser -l josh -c 'git clone https://github.com/joshhighet/j --quiet'
runuser -l josh -c 'git clone https://github.com/joshhighet/nebula --quiet'
runuser -l josh -c 'git clone https://github.com/joshhighet/simplesftp --quiet'
runuser -l josh -c 'touch /home/josh/.jsh'
#####
originaddr=`last | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort -u`
yes | sudo ufw reset > /dev/null
sudo ufw default deny incoming > /dev/null
sudo ufw default allow outgoing > /dev/null
sudo ufw allow from $originaddr to any port 22 proto tcp > /dev/null
yes | sudo ufw enable > /dev/null
#clear
#tree /home/josh
#ufw status verbose
#printf "`echo $HOSTNAME` restarting - reshell w/\nssh josh@` curl -s ipinfo.io/ip`\n"
runuser -l josh -c 'echo "configured with https://github.com/joshhighet/j/blob/master/j.sh" | tee /home/josh/.jsh | lolcat'
printf "\n"
sudo reboot
