#!/bin/bash

# Get Username and write to install scripts
read -p "Enter a username for ubuntu: " uname
sed -i~ -e "s/USERNAME/${uname}/g" 01-Serverbase.sh
sed -i~ -e "s/USERNAME/${uname}/g" 02-Appsetup.sh
sed -i~ -e "s/USERNAME/${uname}/g" Scripts/StartServices.sh

# Get Domain and write to install scripts
read -p "Enter your Domain name (e.g. mydomain.tv): " uurl
sed -i~ -e "s/USERURL/${uurl}/g" 02-Appsetup.sh
sed -i~ -e "s/USERURL/${uurl}/g" Scripts/default

# Get Email and write to install scripts
read -p "Enter an email address for let's encrypt: " uemail
sed -i~ -e "s/USEREMAIL/${uemail}/g" 02-Appsetup.sh

# Get Basic Auth Username and write to install scripts
read -p "Enter a username to access restricted websites, (like sonarr and radarr): " unginx
sed -i~ -e "s/USERBASICAUTH/${unginx}/g" 02-Appsetup.sh

chmod +x /root/psrvision/01-Serverbase.sh
chmod +x /root/psrvision/02-Appsetup.sh
chmod +x /root/psrvision/Scripts/StartServices.sh
sh 01-Serverbase.sh

exit
