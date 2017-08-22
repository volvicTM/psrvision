#!/bin/bash

# Get Username and write to install scripts
if read -p "Please enter a username: " uname; then
  sed -i~ -e "s/USERNAME/${uname}/g" initialsetup.sh
  sed -i~ -e "s/USERNAME/${uname}/g" appsetup.sh
else
  # Error
fi

exit
