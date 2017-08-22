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

# Start containers and generate the configuration files
docker start letsencrypt
sleep 5
docker start sonarr
sleep 5
docker start radarr
sleep 5
docker start hydra
sleep 5
docker start sabnzbd
sleep 5

# Edit containers for Reverse Proxy
docker stop sonarr
sleep 5
rm /home/plex/Sonarr/config.xml
/bin/cat <<EOM >/home/plex/Sonarr/config.xml
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
</Config>
EOM
docker start sonarr
sleep 5

docker stop radarr
sleep 5
rm /home/plex/Radarr/config.xml
/bin/cat <<EOM >/home/plex/Radarr/config.xml
<Config>
  <LogLevel>Info</LogLevel>
  <Port>7878</Port>
  <UrlBase>/films</UrlBase>
  <BindAddress>*</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <ApiKey></ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <Branch>develop</Branch>
</Config>
EOM
docker start radarr
sleep 5

docker stop hydra
sleep 5
rm /home/plex/Nzbhydra/hydra/settings.cfg
/bin/cat <<EOM >/home/plex/Nzbhydra/hydra/settings.cfg
{
    "auth": {
        "authType": "none", 
        "rememberUsers": true, 
        "restrictAdmin": false, 
        "restrictDetailsDl": false, 
        "restrictIndexerSelection": false, 
        "restrictSearch": false, 
        "restrictStats": false, 
        "users": []
    }, 
    "categories": {
        "categories": {
            "anime": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 15000, 
                "min": 50, 
                "newznabCategories": [
                    5070
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "audio": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 2000, 
                "min": 1, 
                "newznabCategories": [
                    3000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "audiobook": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 1000, 
                "min": 50, 
                "newznabCategories": [
                    3030
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "comic": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 250, 
                "min": 1, 
                "newznabCategories": [
                    7030
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "console": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 40000, 
                "min": 100, 
                "newznabCategories": [
                    1000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "ebook": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 100, 
                "min": null, 
                "newznabCategories": [
                    7020, 
                    8010
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "flac": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 2000, 
                "min": 10, 
                "newznabCategories": [
                    3040
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "movies": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 20000, 
                "min": 500, 
                "newznabCategories": [
                    2000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "movieshd": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 20000, 
                "min": 3000, 
                "newznabCategories": [
                    2040, 
                    2050, 
                    2060
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "moviessd": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 3000, 
                "min": 500, 
                "newznabCategories": [
                    2030
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "mp3": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 500, 
                "min": 1, 
                "newznabCategories": [
                    3010
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "pc": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 50000, 
                "min": 100, 
                "newznabCategories": [
                    4000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "tv": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 5000, 
                "min": 50, 
                "newznabCategories": [
                    5000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "tvhd": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 4500, 
                "min": 300, 
                "newznabCategories": [
                    5040
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "tvsd": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "never", 
                "max": 1000, 
                "min": 50, 
                "newznabCategories": [
                    5030
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }, 
            "xxx": {
                "applyRestrictions": "both", 
                "forbiddenRegex": null, 
                "forbiddenWords": [], 
                "ignoreResults": "both", 
                "max": 10000, 
                "min": 100, 
                "newznabCategories": [
                    6000
                ], 
                "requiredRegex": null, 
                "requiredWords": null
            }
        }, 
        "enableCategorySizes": true
    }, 
    "downloaders": [], 
    "indexers": [
        {
            "accessType": "both", 
            "categories": [
                "anime"
            ], 
            "downloadLimit": null, 
            "enabled": false, 
            "generate_queries": true, 
            "hitLimit": 0, 
            "hitLimitResetTime": null, 
            "host": "https://anizb.org", 
            "loadLimitOnRandom": null, 
            "name": "anizb", 
            "password": null, 
            "preselect": true, 
            "score": 0, 
            "searchTypes": [], 
            "search_ids": [], 
            "showOnSearch": true, 
            "timeout": null, 
            "type": "anizb", 
            "username": null
        }, 
        {
            "accessType": "internal", 
            "categories": [], 
            "downloadLimit": null, 
            "enabled": true, 
            "hitLimit": 0, 
            "hitLimitResetTime": null, 
            "host": "https://binsearch.info", 
            "loadLimitOnRandom": null, 
            "name": "Binsearch", 
            "password": null, 
            "preselect": true, 
            "score": 0, 
            "searchTypes": [], 
            "search_ids": [], 
            "showOnSearch": true, 
            "timeout": null, 
            "type": "binsearch", 
            "username": null
        }, 
        {
            "accessType": "internal", 
            "categories": [], 
            "downloadLimit": null, 
            "enabled": true, 
            "hitLimit": 0, 
            "hitLimitResetTime": null, 
            "host": "https://www.nzbclub.com", 
            "loadLimitOnRandom": null, 
            "name": "NZBClub", 
            "password": null, 
            "preselect": true, 
            "score": 0, 
            "searchTypes": [], 
            "search_ids": [], 
            "showOnSearch": true, 
            "timeout": null, 
            "type": "nzbclub", 
            "username": null
        }, 
        {
            "accessType": "internal", 
            "categories": [], 
            "downloadLimit": null, 
            "enabled": true, 
            "generalMinSize": 1, 
            "hitLimit": 0, 
            "hitLimitResetTime": null, 
            "host": "https://nzbindex.com", 
            "loadLimitOnRandom": null, 
            "name": "NZBIndex", 
            "password": null, 
            "preselect": true, 
            "score": 0, 
            "searchTypes": [], 
            "search_ids": [], 
            "showOnSearch": true, 
            "timeout": null, 
            "type": "nzbindex", 
            "username": null
        }
    ], 
    "main": {
        "apikey": "", 
        "branch": "master", 
        "configVersion": 40, 
        "debug": false, 
        "dereferer": "http://www.dereferer.org/?$s", 
        "downloadCounterExecuted": true, 
        "externalUrl": null, 
        "firstStart": 1503347660, 
        "flaskReloader": false, 
        "gitPath": null, 
        "host": "0.0.0.0", 
        "httpProxy": null, 
        "httpsProxy": null, 
        "isFirstStart": false, 
        "keepSearchResultsForDays": 7, 
        "logging": {
            "consolelevel": "INFO", 
            "keepLogFiles": 25, 
            "logIpAddresses": true, 
            "logMaxSize": 1000, 
            "logRotateAfterDays": null, 
            "logfileUmask": "0640", 
            "logfilelevel": "INFO", 
            "logfilename": "nzbhydra.log", 
            "rolloverAtStart": false
        }, 
        "pollShown": 0, 
        "port": 5075, 
        "repositoryBase": "https://github.com/theotherp", 
        "runThreaded": true, 
        "secret": "", 
        "shutdownForRestart": false, 
        "socksProxy": null, 
        "ssl": false, 
        "sslca": null, 
        "sslcert": null, 
        "sslkey": null, 
        "startupBrowser": true, 
        "theme": "grey", 
        "urlBase": "/nzbhydra", 
        "useLocalUrlForApiAccess": true, 
        "verifySsl": true
    }, 
    "searching": {
        "alwaysShowDuplicates": false, 
        "applyRestrictions": "both", 
        "duplicateAgeThreshold": 2, 
        "duplicateSizeThresholdInPercent": 1.0, 
        "forbiddenGroups": null, 
        "forbiddenPosters": null, 
        "forbiddenRegex": null, 
        "forbiddenWords": "", 
        "generate_queries": [
            "internal"
        ], 
        "htmlParser": "html.parser", 
        "idFallbackToTitle": [], 
        "idFallbackToTitlePerIndexer": false, 
        "ignorePassworded": false, 
        "ignoreTemporarilyDisabled": false, 
        "maxAge": "", 
        "nzbAccessType": "redirect", 
        "removeTrailing": ".mp4, .mkv, .subs, .REPOST, repost, ~DG~, .DG, -DG, -1, .1, (1), ReUp, ReUp2, -RP, -AsRequested, -Obfuscated, -Scrambled, -Chamele0n, -BUYMORE, -[TRP], -DG, .par2, .part01, part01.rar, .part02.rar, .jpg, [rartv], [rarbg], [eztv], English, Korean, Spanish, French, German, Italian, Danish, Dutch, Japanese, Cantonese, Mandarin, Russian, Polish, Vietnamese, Swedish, Norwegian, Finnish, Turkish, Portuguese, Flemish, Greek, Hungarian", 
        "requiredRegex": null, 
        "requiredWords": "", 
        "timeout": 20, 
        "userAgent": "NZBHydra"
    }
}
EOM
docker start hydra
sleep 5

echo "Enter password to access URL's"
docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd thisnotbereal
docker stop letsencrypt
sleep 5
sudo rm /home/plex/nginx/nginx/site-confs/default
/bin/cat <<EOM >/home/plex/nginx/nginx/site-confs/default
## listening on port 80 disabled by default, remove the "#" signs to enable
# redirect all traffic to https
#server {
#	listen 80;
#	server_name thisnotbereal.info;
#	return 301 https://$host$request_uri;
#}

# main server block
server {
	listen 443 ssl default_server;

	root /config/www;
	index index.html index.htm index.php;

	server_name thisnotbereal.info;

	ssl_certificate /config/keys/letsencrypt/fullchain.pem;
	ssl_certificate_key /config/keys/letsencrypt/privkey.pem;
	ssl_dhparam /config/nginx/dhparams.pem;
	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
	ssl_prefer_server_ciphers on;

	client_max_body_size 0;

	location / {
		try_files $uri $uri/ /index.html /index.php?$args =404;
		# Reverse Proxy #
	#
 	location /sabnzbd {
	proxy_pass http://172.17.0.5:8080;
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	auth_basic "Restricted Content";
	auth_basic_user_file /config/nginx/.htpasswd;
  }
	#
        location /tv {
        proxy_pass http://172.17.0.3:8989;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        auth_basic "Restricted Content";
        auth_basic_user_file /config/nginx/.htpasswd;
  }
	location /films {
        proxy_pass http://172.17.0.4:7878;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        auth_basic "Restricted Content";
        auth_basic_user_file /config/nginx/.htpasswd;
}
	location /nzbhydra/ {
        #X-Forwarded-For is used for forwarding IP addresses
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://172.17.0.6:5075/nzbhydra/;
        auth_basic "Restricted Content";
        auth_basic_user_file /config/nginx/.htpasswd;
}
	}

	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		# With php7-cgi alone:
		fastcgi_pass 127.0.0.1:9000;
		# With php7-fpm:
		#fastcgi_pass unix:/var/run/php7-fpm.sock;
		fastcgi_index index.php;
		include /etc/nginx/fastcgi_params;
	}

}
EOM
docker start letsencrypt
echo "Installation Complete. Please reboot"

exit
