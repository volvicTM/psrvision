#!/bin/bash

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
mkdir /home/$USER/Sabnzbd
mkdir /home/$USER/Sabnzbd/Downloads
mkdir /home/$USER/Sabnzbd
mkdir /home/$USER/.config
mkdir /home/$USER/.config/rclone
mkdir /home/&USER/nginx
echo "- Complete"

echo "Creating Scripts"
# Add rclone scripts
# Plex
/bin/cat <<EOM >/home/$USER/Scripts/plexmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/plex/Plex/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 6 \
--read-only \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/plexmount.log \
Plex_Crypt: /home/plex/Plex/Media &

exit
EOM

# Sonarr
/bin/cat <<EOM >/home/$USER/Scripts/sonarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/plex/Sonarr/Media
/bin/fusermount -uz /home/plex/Sonarr/gdrive
/bin/fusermount -uz /home/plex/Sonarr/local

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home/plex/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/plex/Sonarr/local=RW:/home/plex/Sonarr/gdrive=RO /home/plex/Sonarr/Media/

exit
EOM

# Radarr
/bin/cat <<EOM >/home/$USER/Scripts/radarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/plex/Radarr/gdrive
/bin/fusermount -uz /home/plex/Radarr/local
/bin/fusermount -uz /home/plex/Radarr/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/plex/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/plex/Radarr/local=RW:/home/plex/Radarr/gdrive=RO /home/plex/Radarr/Media/

exit
EOM

# Make Scripts executable
chmod +x /home/plex/Scripts/*.sh
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
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/plex/Downloads
unzip /home/plex/Downloads/rclone*.zip -d /home/plex/Downloads/
sudo cp /home/plex/Downloads/rclone*/rclone /usr/bin
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
rm -rf /home/plex/Downloads/rclone*
#touch /home/plex/.config/rclone/rclone.conf
echo "- Complete"

echo "Setting up Docker Containers"
# Add and run Dockers
sudo systemctl enable docker

# Get Plex Claim Code
echo -n "Please go to plex.tv/claim and copy and paste the code here: "
read pclaim

# Obtain Email Address for Lets Encrypt
#echo -n "Enter an email address for Let's Encrypt renewals: "
#read leemail

# Obtain Domain
#echo -n "Please enter your domain address, e.g. thisdomain.com: "
#read durl

# Nginx-Let's Encrypt Proxy
docker create \
--privileged \
--name=letsencrypt \
-v /home/plex/nginx:/config \
-e PGID=1000 -e PUID=1000  \
-e EMAIL=volvictm@protonmail.com \
-e URL=thisnotbereal.info \
-p 443:443 \
-e TZ=Europe/London \
linuxserver/letsencrypt

# Plex 
docker run \
-d \
--name plex \
--network=host \
-e TZ="Europe/London" \
-e PLEX_CLAIM="$pclaim" \
-e PLEX_UID="1000" \
-e PLEX_GID="1000" \
-v /home/plex/Plex:/config \
-v /home/plex/Plex:/transcode \
-v /home/plex/Plex:/data \
plexinc/pms-docker

# Sonarr
docker create \
--name sonarr \
-p 8989:8989 \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/plex/Sonarr:/config \
-v /home/plex/Sonarr:/tv \
-v /home/plex/Sabnzbd:/downloads \
-v /usr/bin/rclone:/rclone \
linuxserver/sonarr

# Radarr
docker create \
--name radarr \
-v /home/plex/Radarr:/config \
-v /home/plex/Sabnzbd:/downloads \
-v /home/plex/Radarr:/movies \
-v /usr/bin/rclone:/rclone \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=1000 -e PUID=1000  \
-p 7878:7878 \
linuxserver/radarr

# Sabnzbd
docker create \
--name sabnzbd \
-v /home/plex/Sabnzbd:/config \
-v /home/plex/Sabnzbd:/downloads \
-v /home/plex/Sabnzbd/Downloads:/incomplete-downloads \
-v /etc/localtime:/etc/localtime:ro \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
-p 8080:8080 \
linuxserver/sabnzbd

# NzbHydra
docker create \
--name hydra \
-v /home/plex/Nzbhydra:/config \
-v /home/plex/Sabnzbd:/downloads \
-v /etc/localtime:/etc/localtime:ro \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
-p 5075:5075 \
linuxserver/hydra
echo "- Complete"
echo "Installation Complete. Please reboot"

exit
