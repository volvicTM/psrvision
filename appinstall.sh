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
-v /home/$USER/sslcerts:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
-e TERM=xterm \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy

# Let's Encrypt
docker run -d \
-v /home/$USER/sslcerts:/etc/nginx/certs:rw \
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
-e VIRTUAL_HOST=plex.$durl \
-e LETSENCRYPT_HOST=plex.$durl \
-e LETSENCRYPT_EMAIL=$leemail \
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
exit
