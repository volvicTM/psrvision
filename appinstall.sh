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
mkdir /home/$USER/sslcerts
mkdir /home/$USER/.config
mkdir /home/$USER/.config/rclone

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

echo "finished installing apps"
echo "Setting up Docker Containers"

# Add and run Dockers
sudo systemctl enable docker

# Get Plex Claim Code
echo -n "Please go to plex.tv/claim and copy and paste the code here: "
read pclaim

# Obtain Email Address for Lets Encrypt
echo -n "Enter an email address for Let's Encrypt renewals: "
read leemail

# Obtain Domain
echo -n "Please enter your domain address, e.g. thisdomain.com: "
read durl

# nginx-proxy docker
docker run -d -p 80:80 -p 443:443 \
--name nginx-proxy \
-v /home/"$USER"/sslcerts:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
-e TERM=xterm \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy

# Let's Encrypt
docker run -d \
-v /home/"$USER"/sslcerts:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--volumes-from nginx-proxy \
jrcs/letsencrypt-nginx-proxy-companion

# Plex
docker run \
-d \
--name plex \
--network=host \
-e TZ="Europe/London" \
-e PLEX_CLAIM="$pclaim" \
-e VIRTUAL_HOST=plex."$durl" \
-e LETSENCRYPT_HOST=plex."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
-p 32400:32400/tcp \
-p 3005:3005/tcp \
-p 8324:8324/tcp \
-p 32469:32469/tcp \
-p 1900:1900/udp \
-p 32410:32410/udp \
-p 32412:32412/udp \
-p 32413:32413/udp \
-p 32414:32414/udp \
-e PLEX_UID="1000" \
-e PLEX_GID="1000" \
-v /home/$USER/Plex:/config \
-v /home/$USER/Plex:/transcode \
-v /home/$USER/Plex:/data \
plexinc/pms-docker

# Portainer
docker run \
-d \
-p 9000:9000 \
-v /var/run/docker.sock:/var/run/docker.sock \
-e PGID=1000 -e PUID=1000 \
-e VIRTUAL_HOST=portainer."$durl" \
-e LETSENCRYPT_HOST=portainer."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
portainer/portainer

# Sonarr
docker create \
--name sonarr \
-p 8989:8989 \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/plex/Sonarr:/config \
-v /home/plex/Sonarr:/tv \
-v /home/plex/NzbGet:/downloads \
-v /usr/bin/rclone:/rclone \
-e VIRTUAL_HOST=sonarr."$durl" \
-e LETSENCRYPT_HOST=sonarr."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
linuxserver/sonarr

# Radarr
docker create \
--name=radarr \
-v /home/plex/Radarr:/config \
-v /home/plex/NzbGet:/downloads \
-v /home/plex/Radarr:/movies \
-v /usr/bin/rclone:/rclone \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=1000 -e PUID=1000  \
-e VIRTUAL_HOST=radarr."$durl" \
-e LETSENCRYPT_HOST=radarr."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
-p 7878:7878 \
linuxserver/radarr

# Nzbget
docker create \
--name nzbget \
-p 6789:6789 \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /home/plex/NzbGet:/config \
-v /home/plex/NzbGet:/downloads \
-e VIRTUAL_HOST=nzbget."$durl" \
-e LETSENCRYPT_HOST=nzbget."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
linuxserver/nzbget

# NzbHydra
docker create --name=hydra \
-v /home/plex/NzbHydra:/config \
-v /home/plex/NzbGet:/downloads \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
-p 5075:5075 \
-e VIRTUAL_HOST=nzbhydra."$durl" \
-e LETSENCRYPT_HOST=nzbhydra."$durl" \
-e LETSENCRYPT_EMAIL="$leemail" \
linuxserver/hydra


exit
