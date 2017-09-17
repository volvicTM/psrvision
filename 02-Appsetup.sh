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
mkdir /home/USERNAME/Nzbget
mkdir /home/USERNAME/Nzbget/completed
mkdir /home/USERNAME/NzbHydra
mkdir /home/USERNAME/.config
mkdir /home/USERNAME/.config/rclone
mkdir /home/USERNAME/Proxy
echo "- Complete"

echo "Creating Scripts"
cp /home/USERNAME/psrvision/Scripts/ /home/USERNAME/Scripts/

# Make Scripts executable
chmod +x /home/USERNAME/Scripts/*.sh
echo "- Complete"

# Install necessary Applications
echo "Installing Apps"
sudo apt-get -y install unzip fuse unionfs-fuse> /dev/null 2>&1
sudo sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Docker
sudo apt-get -y install \
apt-transport-https \
ca-certificates \
curl \
software-properties-common > /dev/null 2>&1
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable" > /dev/null 2>&1
sudo apt-get -y update > /dev/null 2>&1
sudo apt-get -y install docker-ce > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1

# Rclone
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/USERNAME/Downloads > /dev/null 2>&1
unzip /home/USERNAME/Downloads/rclone*.zip -d /home/USERNAME/Downloads/ > /dev/null 2>&1
sudo cp /home/USERNAME/Downloads/rclone*/rclone /usr/local/sbin/rclone > /dev/null 2>&1
sudo chown root:root /usr/local/sbin/rclone > /dev/null 2>&1
sudo chmod 755 /usr/local/sbin/rclone > /dev/null 2>&1
rm -rf /home/USERNAME/Downloads/rclone* > /dev/null 2>&1
echo "- Complete"

# Create isolated docker Network
docker network create \
--driver bridge \
--subnet 172.18.0.0/16 \
isolated

# Add and run Dockers
echo "Setting up Docker Containers"

# Letsencrypt Container (nginx, letsencrypt, fail2ban)
docker create \
--privileged \
--name=letsencrypt \
--network=isolated \
--ip=172.18.0.2 \
-v /home/USERNAME/Proxy:/config \
-e PGID=USERGID -e PUID=USERUID  \
-e EMAIL=USEREMAIL \
-e URL=USERURL \
-e SUBDOMAINS=plex \
-p 443:443 \
-e TZ=Europe/London \
linuxserver/letsencrypt > /dev/null 2>&1
sleep 15

# Sonarr Container
docker create \
--name sonarr \
--network=isolated \
--ip=172.18.0.4 \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Sonarr:/config \
-v /home/USERNAME/Sonarr/Media:/tv \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /usr/local/sbin:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/sonarr > /dev/null 2>&1
sleep 15

# Radarr Container
docker create \
--name=radarr \
--network=isolated \
--ip=172.18.0.5 \
-v /home/USERNAME/Radarr:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Radarr/Media:/movies \
-v /usr/local/sbin:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=USERGID -e PUID=USERUID \
linuxserver/radarr > /dev/null 2>&1
sleep 15

# NZBGet Container
docker create \
--name nzbget \
--network=isolated \
--ip=172.18.0.3 \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /home/USERNAME/Nzbget:/config \
-v /home/USERNAME/Nzbget:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/nzbget > /dev/null 2>&1
sleep 15

# NZBHydra Container
docker create \
--name=hydra \
--network=isolated \
--ip=172.18.0.6 \
-v /home/USERNAME/NzbHydra:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
-e PGID=USERGID -e PUID=USERUID \
-e TZ=Europe/London \
linuxserver/hydra > /dev/null 2>&1
sleep 15

# Plex Container
docker create \
--name plex \
--network=isolated \
--ip=172.18.0.7 \
-e PLEX_UID=USERUID -e PLEX_GID=USERGID \
-e TZ=Europe/London \
-e PLEX_CLAIM="USERPCLAIM" \
-v /home/USERNAME/Plex:/config \
-v /home/USERNAME/Plex:/transcode \
-v /home/USERNAME/Plex:/data \
-v /home/USERNAME/Scripts:/Scripts \
plexinc/pms-docker > /dev/null 2>&1
sleep 10
echo "- Complete"

# Configure Dockers and Proxy
echo "Configuring Containers"
# Start dockers to build configuration files
docker start letsencrypt > /dev/null 2>&1
sleep 10
docker start nzbget > /dev/null 2>&1
sleep 5
docker start sonarr > /dev/null 2>&1
sleep 5
docker start radarr > /dev/null 2>&1
sleep 5
docker start hydra > /dev/null 2>&1
sleep 5
docker start plex > /dev/null 2>&1
sleep 5

# Configure Lets Encrypt
echo "Please enter password to access restricted sites (sonarr, radarr, nzbget and hydra)"
docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd USERBASICAUTH
sudo rm /home/USERNAME/Proxy/nginx/site-confs/default
sudo cp /home/USERNAME/psrvision/Scripts/default /home/USERNAME/Proxy/nginx/site-confs/default
docker restart letsencrypt > /dev/null 2>&1
sleep 5

# Configure Sonarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/tv</UrlBase>=g' /home/USERNAME/Sonarr/config.xml
docker restart sonarr > /dev/null 2>&1
sleep 5

# Configure Radarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/film</UrlBase>=g' /home/USERNAME/Radarr/config.xml
docker restart radarr > /dev/null 2>&1
sleep 5

# Configure Hydra
sed -i~ -e 's="urlBase": null,="urlBase": "/hydra",=g' /home/USERNAME/NzbHydra/hydra/settings.cfg
docker restart hydra > /dev/null 2>&1
sleep 5

# Configure Nzbget
sed -i 's/ControlUsername=nzbget/ControlUsername=/' /home/USERNAME/Nzbget/nzbget.conf
sed -i 's/ControlPassword=tegbzn6789/ControlPassword=/' /home/USERNAME/Nzbget/nzbget.conf
docker restart nzbget > /dev/null 2>&1

docker stop $(docker ps -a -q) > /dev/null 2>&1
echo "- Complete"
echo "Please record your username and password. (You may change the password at any time!)"
echo
echo "****************************"
echo "*** Username for website login:  USERBASICAUTH"
echo "*** Use the password you created earlier"
echo "*** URL's to access services: "
echo "*** Sonarr: https://USERURL/tv"
echo "*** Radarr: https://USERURL/film"
echo "*** Nzbget: https://USERURL/nzbget"
echo "*** Hydra:  https://USERURL/hydra"
echo "*** Plex:   https://plex.USERURL"
echo "****************************"
echo
echo "Installation Complete. Please reboot and run the StartServices.sh script"
sudo rm -rf /home/USERNAME/psrvision

exit
