#!/bin/bash

# Get Username and write to install scripts
read -p "Please enter a username: " uname
sed -i~ -e "s/USERNAME/${uname}/g" 01-Serverbase.sh
sed -i~ -e "s/USERNAME/${uname}/g" appinstall.sh


# Get Domain and write to install scripts
read -p "Please enter a your Domain name (e.g. mydomain.tv): " uurl
sed -i~ -e "s/USERURL/${uurl}/g" appinstall.sh

# Get Email and write to install scripts
read -p "Please enter a email address for let's encrypt: " uemail
sed -i~ -e "s/USEREMAIL/${uemail}/g" appinstall.sh

# Get Basic Auth Username and write to install scripts
read -p "Please enter a username to access the websites, (like sonarr and radarr): " unginx
sed -i~ -e "s/USERBASICAUTH/${unginx}/g" appinstall.sh

chmod +x /home/plex/psrvision/01-Serverbase.sh
chmod +x /home/plex/psrvision/02-Appsetup.sh

exit
