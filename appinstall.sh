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
sudo apt-get update
# Unzip
sudo apt-get -y install unzip
# Fuse
sudo apt-get -y install fuse
# Unionfs
sudo apt-get -y install unionfs-fuse
sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
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
echo "finished installing apps"
echo "Setting up Docker Containers"

# Add and run Dockers
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Get Plex Claim Code
read -p "Please go to plex.tv/claim login and copy the code. Press [Enter] to continue..."
echo -n "Paste the code in: " 
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
-e PLEX_UID="1000" \
-e PLEX_GID="1000" \
-v /home/$USER/Plex:/config \
-v /home/$USER/Plex:/transcode \
-v /home/$USER/Plex:/data \
plexinc/pms-docker
exit
