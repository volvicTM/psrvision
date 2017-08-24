#!/bin/bash

# Make required directories
echo "Creating Directories"
mkdir /home/USERNAME/Downloads
mkdir /home/USERNAME/Scripts
mkdir /home/USERNAME/Scripts/logs
mkdir /home/USERNAME/Plex
mkdir /home/USERNAME/Plex/Media
mkdir /home/USERNAME/Sonarr
mkdir /home/USERNAME/Sonarr/local
mkdir /home/USERNAME/Sonarr/gdrive
mkdir /home/USERNAME/Sonarr/Media
mkdir /home/USERNAME/Radarr
mkdir /home/USERNAME/Radarr/local
mkdir /home/USERNAME/Radarr/gdrive
mkdir /home/USERNAME/Radarr/Media
mkdir /home/USERNAME/Sabnzbd
mkdir /home/USERNAME/Sabnzbd/Downloads
mkdir /home/USERNAME/Sabnzbd
mkdir /home/USERNAME/.config
mkdir /home/USERNAME/.config/rclone
mkdir /home/USERNAME/sslcerts
echo "- Complete"

echo "Creating Scripts"
# Add rclone scripts
# Plex
/bin/cat <<EOM >/home/USERNAME/Scripts/plexmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Plex/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 6 \
--read-only \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/plexmount.log \
Plex_Crypt: /home/USERNAME/Plex/Media &

exit
EOM

# Sonarr
/bin/cat <<EOM >/home/USERNAME/Scripts/sonarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Sonarr/Media
/bin/fusermount -uz /home/USERNAME/Sonarr/gdrive
/bin/fusermount -uz /home/USERNAME/Sonarr/local

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home/USERNAME/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/USERNAME/Sonarr/local=RW:/home/USERNAME/Sonarr/gdrive=RO /home/USERNAME/Sonarr/Media/

exit
EOM

# Radarr
/bin/cat <<EOM >/home/USERNAME/Scripts/radarrmount.sh
#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Radarr/gdrive
/bin/fusermount -uz /home/USERNAME/Radarr/local
/bin/fusermount -uz /home/USERNAME/Radarr/Media

#Mount
/usr/bin/rclone mount \
--tpslimit 2 \
--allow-other \
--stats 1s \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/USERNAME/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other /home/USERNAME/Radarr/local=RW:/home/USERNAME/Radarr/gdrive=RO /home/USERNAME/Radarr/Media/

exit
EOM

# Make Scripts executable
chmod +x /home/USERNAME/Scripts/*.sh
echo "- Complete"
echo "Installing Apps"
# Install necessary Applications
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
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/USERNAME/Downloads
unzip /home/USERNAME/Downloads/rclone*.zip -d /home/USERNAME/Downloads/
sudo cp /home/USERNAME/Downloads/rclone*/rclone /usr/bin
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
rm -rf /home/USERNAME/Downloads/rclone*
#touch /home/USERNAME/.config/rclone/rclone.conf
echo "- Complete"

echo "Setting up Docker Containers"
# Add and run Dockers
sudo systemctl enable docker

# Nginx-Let's Encrypt Proxy
docker run \
-d \
-p 80:80 -p 443:443 \
--name nginx-proxy \
-v /home/USERNAME/sslcerts:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy
sleep 5

docker run \
-d \
-v /home/USERNAME/sslcerts:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--volumes-from nginx-proxy \
jrcs/letsencrypt-nginx-proxy-companion
sleep 5

# Plex 
docker run \
-d \
--name plex \
--network=host \
-e TZ="Europe/London" \
-e PLEX_CLAIM="USERCLAIM" \
-e PLEX_UID="1000" \
-e PLEX_GID="1000" \
-v /home/USERNAME/Plex:/config \
-v /home/USERNAME/Plex:/transcode \
-v /home/USERNAME/Plex:/data \
-e "VIRTUAL_HOST=plex.USERURL" \
-e "VIRTUAL_PORT=32400" \
-e "LETSENCRYPT_HOST=plex.USERURL" \
-e "LETSENCRYPT_EMAIL=USEREMAIL" \
plexinc/pms-docker
sleep 5

# Sonarr
docker run \
-d \
--name sonarr \
-p 8989:8989 \
-e "VIRTUAL_PORT=8989" \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Sonarr:/config \
-v /home/USERNAME/Sonarr:/tv \
-v /home/USERNAME/Sabnzbd:/downloads \
-v /usr/bin/rclone:/rclone \
-e "VIRTUAL_HOST=sonarr.USERURL" \
-e "LETSENCRYPT_HOST=sonarr.USERURL" \
-e "LETSENCRYPT_EMAIL=USEREMAIL" \
linuxserver/sonarr
sleep 5

# Radarr
docker run \
-d \
--name radarr \
-v /home/USERNAME/Radarr:/config \
-v /home/USERNAME/Sabnzbd:/downloads \
-v /home/USERNAME/Radarr:/movies \
-v /usr/bin/rclone:/rclone \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=1000 -e PUID=1000  \
-p 7878:7878 \
-e "VIRTUAL_PORT=7878" \
-e "VIRTUAL_HOST=radarr.USERURL" \
-e "LETSENCRYPT_HOST=radarr.USERURL" \
-e "LETSENCRYPT_EMAIL=USEREMAIL" \
linuxserver/radarr
sleep 5

# Sabnzbd
docker run \
-d \
--name sabnzbd \
-v /home/USERNAME/Sabnzbd:/config \
-v /home/USERNAME/Sabnzbd:/downloads \
-v /home/USERNAME/Sabnzbd/Downloads:/incomplete-downloads \
-v /etc/localtime:/etc/localtime:ro \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
-p 8080:8080 \
-e "VIRTUAL_PORT=8080" \
-e "VIRTUAL_HOST=sabnzbd.USERURL" \
-e "LETSENCRYPT_HOST=sabnzbd.USERURL" \
-e "LETSENCRYPT_EMAIL=USEREMAIL" \
linuxserver/sabnzbd
sleep 5

# NzbHydra
docker run \
-d \
--name hydra \
-v /home/USERNAME/Nzbhydra:/config \
-v /home/USERNAME/Sabnzbd:/downloads \
-v /etc/localtime:/etc/localtime:ro \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
-p 5075:5075 \
-e "VIRTUAL_PORT=32400" \
-e "VIRTUAL_HOST=hydra.USERURL" \
-e "LETSENCRYPT_HOST=hydra.USERURL" \
-e "LETSENCRYPT_EMAIL=USEREMAIL" \
linuxserver/hydra
sleep 5

echo "- Complete"
echo "Installation Complete. Please reboot"

exit
