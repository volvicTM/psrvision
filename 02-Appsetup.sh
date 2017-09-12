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
mkdir /home/USERNAME/.config
mkdir /home/USERNAME/.config/rclone
mkdir /home/USERNAME/Proxy
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
--tpslimit 4 \
--read-only \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/plexmount.log \
Plex_Crypt: /home/USERNAME/Plex/Media &

exit
EOM

# Sonarr Mount
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
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home/USERNAME/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/USERNAME/Sonarr/local=RW:/home/USERNAME/Sonarr/gdrive=RO /home/USERNAME/Sonarr/Media/

exit
EOM


# Sonarr Upload to Google Drive Script
/bin/cat <<EOM >/home/USERNAME/Scripts/uploadtv.sh
#! /bin/bash

#Check if script is already running
if pidof -o %PPID -x "uploadtv.sh"; then
   exit 1
fi

#Variables
LOGFILE="/Scripts/logs/uploadtv.txt"
FROM="/config/local/"
TO="Sonarr_Crypt:/"

#Upload to Google Drive
echo "$(date "+%d.%m.%Y %T") RCLONE UPLOAD STARTED" | tee -a $LOGFILE
/rclone move --config=/rcloneconf/rclone.conf $FROM $TO -c --no-traverse --transfers=2 --checkers=2 --delete-after --log-file=$LOGFILE
echo "$(date "+%d.%m.%Y %T") RCLONE UPLOAD ENDED" | tee -a $LOGFILE
sleep 30s

# Remove Empty Folders
find "/config/local/" -mindepth 1 -type d -empty -delete
exit
EOM

# Radarr Mount
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
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/USERNAME/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/USERNAME/Radarr/local=RW:/home/USERNAME/Radarr/gdrive=RO /home/USERNAME/Radarr/Media/

exit
EOM

# Radarr Upload to Google Drive Script
/bin/cat <<EOM >/home/USERNAME/Scripts/uploadfilm.sh
#! /bin/bash

#Check if script is already running
if pidof -o %PPID -x "uploadfilm.sh"; then
   exit 1
fi

#Variables
LOGFILE="/Scripts/logs/uploadfilm.txt"
FROM="/config/local/"
TO="Radarr_Crypt:/"

#Upload to Google Drive
echo "$(date "+%d.%m.%Y %T") RCLONE UPLOAD STARTED" | tee -a $LOGFILE
/rclone move --config=/rcloneconf/rclone.conf $FROM $TO -c --no-traverse --transfers=2 --checkers=2 --delete-after --log-file=$LOGFILE
echo "$(date "+%d.%m.%Y %T") RCLONE UPLOAD ENDED" | tee -a $LOGFILE
sleep 30s

# Remove Empty Folders
find "/config/local/" -mindepth 1 -type d -empty -delete
exit
EOM

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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
sudo apt-get -y update > /dev/null 2>&1
sudo apt-get -y install docker-ce > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1

# Rclone
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/USERNAME/Downloads > /dev/null 2>&1
unzip /home/USERNAME/Downloads/rclone*.zip -d /home/USERNAME/Downloads/ > /dev/null 2>&1
sudo cp /home/USERNAME/Downloads/rclone*/rclone /usr/bin > /dev/null 2>&1
sudo chown root:root /usr/bin/rclone > /dev/null 2>&1
sudo chmod 755 /usr/bin/rclone > /dev/null 2>&1
rm -rf /home/USERNAME/Downloads/rclone* > /dev/null 2>&1
echo "- Complete"

# Create isolated docker Network
docker network create --driver bridge isolated

# Add and run Dockers
echo "Setting up Docker Containers"

# Letsencrypt Container (nginx, letsencrypt, fail2ban)
docker create \
--privileged \
--name=letsencrypt \
--network=isolated \
-v /home/USERNAME/Proxy:/config \
-e PGID=USERGID -e PUID=USERUID  \
-e EMAIL=USEREMAIL \
-e URL=USERURL \
-e SUBDOMAINS=plex \
-p 443:443 \
-e TZ=Europe/London \
linuxserver/letsencrypt > /dev/null 2>&1
sleep 10

# Sonarr Container
docker create \
--name sonarr \
--network=isolated \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Sonarr:/config \
-v /home/USERNAME/Sonarr/Media:/tv \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /usr/bin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/sonarr > /dev/null 2>&1
sleep 10

# Radarr Container
docker create \
--name=radarr \
--network=isolated \
-v /home/USERNAME/Radarr:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Radarr/Media:/movies \
-v /usr/bin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Scripts:/Scripts \
-e TZ=Europe/London \
-e PGID=USERGID -e PUID=USERUID \
linuxserver/radarr > /dev/null 2>&1
sleep 10

# NZBGet Container
docker create \
--name nzbget \
--network=isolated \
-e PUID=USERUID -e PGID=USERGID \
-e TZ=Europe/London \
-v /home/USERNAME/Nzbget:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/nzbget > /dev/null 2>&1
sleep 10

# NZBHydra Container
docker create \
--name=hydra \
--network=isolated \
-v /home/USERNAME/NzbHydra:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
-e PGID=USERGID -e PUID=USERUID \
-e TZ=Europe/London \
linuxserver/hydra > /dev/null 2>&1
sleep 10

# Plex Container
docker create \
--name plex \
--network=isolated \
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
# Start dockers to build configuration files
docker start letsencrypt
sleep 10
docker start nzbget
sleep 5
docker start sonarr
sleep 5
docker start radarr
sleep 5
docker start hydra
sleep 5
docker start plex
sleep 5

# Configure Lets Encrypt
echo "Please enter password to access restricted sites (sonarr, radarr, nzbget and hydra)"
docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd USERBASICAUTH
sudo rm /home/USERNAME/Proxy/nginx/site-confs/default
sudo cp /home/USERNAME/psrvision/Scripts/default /home/USERNAME/Proxy/nginx/site-confs/default
docker restart letsencrypt
sleep 5

# Configure Sonarr
sudo rm /home/USERNAME/Sonarr/config.xml
/bin/cat <<EOM >/home/USERNAME/Sonarr/config.xml
<Config>
  <LogLevel>Info</LogLevel>
  <Port>8989</Port>
  <UrlBase>/tv</UrlBase>
  <BindAddress>*</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <ApiKey></ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <Branch>master</Branch>
  <LaunchBrowser>True</LaunchBrowser>
  <SslCertHash></SslCertHash>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <AnalyticsEnabled>False</AnalyticsEnabled>
</Config>
EOM
docker restart sonarr
sleep 5

# Configure Radarr
sudo rm /home/USERNAME/Sonarr/config.xml
/bin/cat <<EOM >/home/USERNAME/Radarr/config.xml
<Config>
  <LogLevel>Info</LogLevel>
  <Port>7878</Port>
  <UrlBase>/film</UrlBase>
  <BindAddress>*</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <ApiKey></ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <Branch>develop</Branch>
  <LaunchBrowser>True</LaunchBrowser>
  <SslCertHash></SslCertHash>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <AnalyticsEnabled>False</AnalyticsEnabled>
</Config>
EOM
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

echo
echo "Please record your username and password. (You may change the password at any time!)"
echo
echo "****************************"
echo "*** Username for website login:  USERBASICAUTH"
echo "*** Use the password you created earlier"
echo "*** URL's to access services: "
echo "*** Sonarr: USERURL/tv"
echo "*** Radarr: USERURL/film"
echo "*** Nzbget: USERURL/nzbget"
echo "*** Hydra: USERURL/hydra"
echo "*** Plex: plex.USERURL"
echo "****************************"
echo
echo "Installation Complete. Please reboot and run the startservices.sh script"
sudo rm -rf /home/USERNAME/psrvision

exit
