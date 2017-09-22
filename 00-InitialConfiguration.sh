#!/bin/bash

# Get Username and write to install scripts
read -p "Enter a username for ubuntu: " uname
sed -i~ -e "s/USERNAME/${uname}/g" *.sh
sed -i~ -e "s/USERNAME/${uname}/g" Scripts/*.sh

# Get Domain and write to install scripts
read -p "Enter your Domain name (e.g. mydomain.tv): " uurl
sed -i~ -e "s/USERURL/${uurl}/g" *.sh
sed -i~ -e "s/USERURL/${uurl}/g" Scripts/*

# Get Email and write to install scripts
read -p "Enter an email address for let's encrypt: " uemail
sed -i~ -e "s/USEREMAIL/${uemail}/g" *.sh

# Get Basic Auth Username and write to install scripts
read -p "Enter a username to access restricted websites, (like sonarr and radarr): " unginx
sed -i~ -e "s/USERBASICAUTH/${unginx}/g" *.sh

chmod +x /root/psrvision/*.sh
chmod +x /root/psrvision/Scripts/*.sh
sh 01-Serverbase.sh

exit
