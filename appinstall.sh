#!/bin/bash
uname=$USER
# Make required directories
echo "Creating Directories"
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
mkdir /home/$USER/sslcerts
mkdir /home/$USER/.config
mkdir /home/$USER/.config/rclone
echo "- Complete"

echo "Creating Scripts"
# Add rclone scripts
# Plex
/bin/cat <<EOM >/home/$USER/Scripts/plexmount.sh
#! /bin/bash
#Unmount
/bin/fusermount -uz /home/$UPATH/Plex/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 6 \
--read-only \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/$UPATH/Scripts/logs/plexmount.log \
Plex_Crypt: /home/$UPATH/Plex/Media &
exit
EOM
sed -i '2s/^/UPATH="$USER"\n/' /home/$USER/Scripts/plexmount.sh

# Sonarr
/bin/cat <<EOM >/home/$USER/Scripts/sonarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/&UPATH/Sonarr/Media
/bin/fusermount -uz /home/&UPATH/Sonarr/gdrive
/bin/fusermount -uz /home/&UPATH/Sonarr/local

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/&UPATH/Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home/&UPATH/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/&UPATH/Sonarr/local=RW:/home/&UPATH/Sonarr/gdrive=RO /home/&UPATH/Sonarr/Media/

exit
EOM
sed -i '2s/^/UPATH="$USER"\n/' /home/$USER/Scripts/sonarrmount.sh

# Radarr
/bin/cat <<EOM >/home/$USER/Scripts/radarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/&UPATH/Radarr/gdrive
/bin/fusermount -uz /home/&UPATH/Radarr/local
/bin/fusermount -uz /home/&UPATH/Radarr/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/&UPATH/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/&UPATH/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/&UPATH/Radarr/local=RW:/home/&UPATH/Radarr/gdrive=RO /home/&UPATH/Radarr/Media/

exit
EOM
sed -i '2s/^/UPATH="$USER"\n/' /home/$USER/Scripts/radarrmount.sh

# Make Scripts executable
chmod +x /home/$USER/Scripts/*.sh
echo "- Complete"
echo "Installing Apps"
# Install necessary Applications
sudo apt-get -y update > /dev/null
# Unzip
sudo apt-get -y install unzip > /dev/null
# Fuse
sudo apt-get -y install fuse > /dev/null
# Unionfs
sudo apt-get -y install unionfs-fuse > /dev/null
sudo sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
# Docker
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common > /dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get -y update > /dev/null
sudo apt-get -y install docker-ce > /dev/null
# Rclone
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/$USER/Downloads
unzip /home/$USER/Downloads/rclone*.zip -d /home/$USER/Downloads/
sudo cp /home/$USER/Downloads/rclone*/rclone /usr/bin
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
rm -rf /home/$USER/Downloads/rclone*
touch /home/$USER/.config/rclone/rclone.conf
echo "- Complete"

exit
