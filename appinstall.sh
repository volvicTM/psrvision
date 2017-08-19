#!/bin/bash
uname=$USER
# Make required directories
mkdir /home/$USER/Downloads
mkdir /home/$USER/Scripts
mkdir /home/$USER/Scripts/logs
mkdir /home/$USER/Plex
mkdir /home/$USER/Plex/Media
mkdir /home/$USER/Sonarr
mkdir /home/$USER/Sonarr/local
mkdir /home/$USER/Sonarr/gdrive
mkdir /home/$USER/Sonarr/Media
mkdir /home/$USER/Radarr
mkdir /home/$USER/Radarr/local
mkdir /home/$USER/Radarr/gdrive
mkdir /home/$USER/Radarr/Media
mkdir /home/$USER/Nzbget
mkdir /home/$USER/Nzbget/Downloads
mkdir /home/$USER/Nzbhydra

# Add rclone scripts
# Plex
/bin/cat <<EOM >/home/$USER/Scripts/plexmount.sh
#! /bin/bash
#Unmount
/bin/fusermount -uz /home//Plex/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 6 \
--read-only \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home//Scripts/logs/plexmount.log \
Plex_Crypt: /home//Plex/Media &
exit
EOM

# Sonarr
/bin/cat <<EOM >/home/$USER/Scripts/sonarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home//Sonarr/Media
/bin/fusermount -uz /home//Sonarr/gdrive
/bin/fusermount -uz /home//Sonarr/local

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home//Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home//Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home//Sonarr/local=RW:/home//Sonarr/gdrive=RO /home//Sonarr/Media/

exit
EOM

# Radarr
/bin/cat <<EOM >/home/$USER/Scripts/radarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home//Radarr/gdrive
/bin/fusermount -uz /home//Radarr/local
/bin/fusermount -uz /home//Radarr/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home//Scripts/logs/radarrmount.log \
Radarr_Crypt: /home//Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home//Radarr/local=RW:/home//Radarr/gdrive=RO /home//Radarr/Media/

exit
EOM

# Install necessary Applications
sudo apt-get update
# Unzip
sudo apt-get -y install unzip
# Fuse
sudo apt-get -y install fuse
# Unionfs
sudo apt-get -y install unionfs-fuse
# Docker
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get -y install docker-ce
# Rclone
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/$USER/Downloads
unzip /home/$USER/Downloads/rclone*.zip -d /home/$USER/Downloads/
sudo cp /home/$USER/Downloads/rclone*/rclone /usr/bin
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
rm -rf /home/$USER/Downloads/rclone*
echo "finished installing"
echo "Setting up Docker Containers"


exit
