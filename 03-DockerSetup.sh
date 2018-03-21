#! /bin/bash

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
-p 443:443 -p 80:80 \
-e TZ=Europe/London \
linuxserver/letsencrypt

# Sonarr Container
docker create \
--name sonarr \
--network=isolated \
--ip=172.18.0.4 \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Sonarr:/config \
-v /home/USERNAME/Mount/Sonarr:/tv \
-v /home/USERNAME/Nzbget:/downloads \
-v /usr/local/sbin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/sonarr

# 4K Sonarr Container
docker create \
--name 4ksonarr \
--network=isolated \
--ip=172.18.0.5 \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/4kSonarr:/config \
-v /home/USERNAME/Mount/4kSonarr:/tv \
-v /home/USERNAME/Nzbget:/downloads \
-v /usr/local/sbin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/sonarr

# Radarr Container
docker create \
--name=radarr \
--network=isolated \
--ip=172.18.0.6 \
-v /home/USERNAME/Radarr:/config \
-v /home/USERNAME/Nzbget:/downloads \
-v /home/USERNAME/Mount/Radarr:/movies \
-v /usr/local/sbin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=USERGID -e PUID=USERUID \
linuxserver/radarr

# Radarr Container
docker create \
--name=4kradarr \
--network=isolated \
--ip=172.18.0.7 \
-v /home/USERNAME/4kRadarr:/config \
-v /home/USERNAME/Nzbget:/downloads \
-v /home/USERNAME/Mount/4kRadarr:/movies \
-v /usr/local/sbin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
-v /etc/localtime:/etc/localtime:ro \
-e TZ=Europe/London \
-e PGID=USERGID -e PUID=USERUID \
linuxserver/radarr

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
linuxserver/nzbget

# NZBHydra Container
docker create \
--name=hydra \
--network=isolated \
--ip=172.18.0.8 \
-v /home/USERNAME/NzbHydra:/config \
-v /home/USERNAME/Nzbget:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
-e PGID=USERGID -e PUID=USERUID \
-e TZ=Europe/London \
linuxserver/hydra

# Plex Container
docker create \
--name plex \
--network=isolated \
--ip=172.18.0.9 \
--device=/dev/dri:/dev/dri \
-e PLEX_UID=USERUID -e PLEX_GID=USERGID \
-e TZ=Europe/London \
-e PLEX_CLAIM="USERPCLAIM" \
-v /home/USERNAME/Plex:/config \
-v /home/USERNAME/Plex:/transcode \
-v /home/USERNAME/Mount/Plex/Media:/data \
-v /home/USERNAME/Scripts:/Scripts \
plexinc/pms-docker
echo "- Complete"

# WatchTower Container
docker create \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
v2tec/watchtower --cleanup

# Configure Dockers and Proxy
echo "Configuring Containers"
# Start dockers to build configuration files
docker start letsencrypt
sleep 10
docker start nzbget
sleep 5
docker start sonarr
sleep 5
docker start radarr
sleep 5
docker start 4ksonarr
sleep 5
docker start 4kradarr
sleep 5
docker start hydra
sleep 5
docker start plex
sleep 5
docker start watchtower
sleep 5

# Configure Lets Encrypt
echo "Please enter password to access restricted sites (sonarr, radarr, nzbget and hydra)"
docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd USERBASICAUTH
sudo rm /home/USERNAME/Proxy/nginx/site-confs/default
sudo cp /home/USERNAME/psrvision/Scripts/default /home/USERNAME/Proxy/nginx/site-confs/default
docker restart letsencrypt
sleep 5

# Configure Sonarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/tv</UrlBase>=g' /home/USERNAME/Sonarr/config.xml
docker restart sonarr
sleep 5

# Configure 4kSonarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/4ktv</UrlBase>=g' /home/USERNAME/4kSonarr/config.xml
docker restart sonarr
sleep 5

# Configure Radarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/film</UrlBase>=g' /home/USERNAME/Radarr/config.xml
docker restart radarr
sleep 5

# Configure 4kRadarr
sed -i~ -e 's=<UrlBase></UrlBase>=<UrlBase>/4kfilm</UrlBase>=g' /home/USERNAME/4kRadarr/config.xml
docker restart radarr
sleep 5

# Configure Hydra
sed -i~ -e 's="urlBase": null,="urlBase": "/hydra",=g' /home/USERNAME/NzbHydra/hydra/settings.cfg
docker restart hydra
sleep 5

# Configure Nzbget
sed -i 's/ControlUsername=nzbget/ControlUsername=/' /home/USERNAME/Nzbget/nzbget.conf
sed -i 's/ControlPassword=tegbzn6789/ControlPassword=/' /home/USERNAME/Nzbget/nzbget.conf
docker restart nzbget

docker stop $(docker ps -a -q)
echo "- Complete"
echo "Please record your username and password. (You may change the password at any time!)"
echo
echo "****************************"
echo "*** Username for website login:  USERBASICAUTH"
echo "*** Use the password you created earlier"
echo "*** URL's to access services: "
echo "*** Sonarr: https://USERURL/tv"
echo "*** 4K Sonarr: https://USERURL/4ktv"
echo "*** Radarr: https://USERURL/film"
echo "*** 4K Radarr: https://USERURL/4kfilm"
echo "*** Nzbget: https://USERURL/nzbget"
echo "*** Hydra:  https://USERURL/hydra"
echo "*** Plex:   https://plex.USERURL"
echo "****************************"
echo
echo "Installation Complete. Please reboot and run the StartServices.sh script"
sudo rm -rf /home/USERNAME/psrvision

exit
