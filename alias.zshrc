#path traversals
alias ..='cd ..'
alias cd..="cd .."
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
#generic shortcuts
alias ll="ls -laFTrth"
alias pubkey="cat ~/.ssh/id_rsa.pub"
#application specific
alias splunk='/Applications/Splunk/bin/splunk'
alias cloudflaredssh='cloudflared access ssh-config --hostname'
alias tor='/Applications/Tor Browser.app/Contents/MacOS/firefox'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias checkra1n='/Applications/checkra1n.app/Contents/MacOS/checkra1n'
alias google='{read -r arr; open "https://google.com/search?q=${arr}";} <<<'
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
#networking
alias myip-json="curl -s ipinfo.io | jq"
alias ports="sudo lsof -iTCP -sTCP:LISTEN -n -P"
alias ip='{read -r arr; curl "ip-api.com/${arr}";} <<<'
alias intip="ifconfig | grep 'inet ' | grep -v 127.0.0.1 | cut -d\  -f2"
alias ipgrepv6="grep -o '^\([0-9a-fA-F]\{0,4\}:\)\{1,7\}[0-9a-fA-F]\{0,4\}$'"
alias ipgrepv4="grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'"
alias myip='curl -s ipinfo.io | jq .ip,.city,.country,.org -r | cowsay | lolcat --animate --speed=150'
alias ipgrep="grep -o -e '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' -e '^\([0-9a-fA-F]\{0,4\}:\)\{1,7\}[0-9a-fA-F]\{0,4\}$'"
#whois -h whois.radb.net -- '-i origin 12345' | grep -Eo "([0-9.]+){4}/[0-9]+" | sort -n | uniq -c | cut -d ' ' -f5
#PS1='[`date  +"%d-%b-%y %T"`] > '  test "$(ps -ocommand= -p $PPID | awk '{print $1}')" == 'script' || (script -f $HOME/logs/$(date +"%d-%b-%y_%H-%M-%S")_shell.log)
