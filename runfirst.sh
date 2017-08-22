#!/bin/bash

# Get Username and write to install scripts
if read -p "Please enter a username: " uname; then
  sed -i~ -e "s/USERNAME/${uname}/g" initialsetup.sh
  sed -i~ -e "s/USERNAME/${uname}/g" appsetup.sh
else
  # Error
fi

# Get Domain and write to install scripts
if read -p "Please enter a your Domain name (e.g. mydomain.tv): " uurl; then
  sed -i~ -e "s/USERURL/${uurl}/g" appsetup.sh
else
  # Error
fi

# Get Email and write to install scripts
if read -p "Please enter a email address for let's encrypt: " uemail; then
  sed -i~ -e "s/USEREMAIL/${uemail}/g" appsetup.sh
else
  # Error
fi

# Get Basic Auth Username and write to install scripts
if read -p "Please enter a username to access the websites, (like sonarr and radarr): " unginx; then
  sed -i~ -e "s/USERBASICAUTH/${unginx}/g" appsetup.sh
else
  # Error
fi
exit
