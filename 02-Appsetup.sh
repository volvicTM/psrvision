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
-e PGID=1000 -e PUID=1000  \
-e EMAIL=USEREMAIL \
-e URL=USERURL \
-e SUBDOMAINS=plex \
-p 443:443 \
-e TZ=Europe/London \
linuxserver/letsencrypt > /dev/null 2>&1
sleep 12

# Sonarr Container
docker create \
--name sonarr \
--network=isolated \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /etc/localtime:/etc/localtime:ro \
-v /home/USERNAME/Sonarr:/config \
-v /home/USERNAME/Sonarr/Media:/tv \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /usr/bin/rclone:/rclone \
-v /home/USERNAME/.config/rclone:/rcloneconf \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/sonarr > /dev/null 2>&1
sleep 12

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
-e PGID=1000 -e PUID=1000 \
linuxserver/radarr > /dev/null 2>&1
sleep 12

# NZBGet Container
docker create \
--name nzbget \
--network=isolated \
-e PUID=1000 -e PGID=1000 \
-e TZ=Europe/London \
-v /home/USERNAME/Nzbget:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
linuxserver/nzbget > /dev/null 2>&1
sleep 12

# NZBHydra Container
docker create \
--name=hydra \
--network=isolated \
-v /home/USERNAME/NzbHydra:/config \
-v /home/USERNAME/Nzbget/completed:/downloads \
-v /home/USERNAME/Scripts:/Scripts \
-e PGID=1000 -e PUID=1000 \
-e TZ=Europe/London \
linuxserver/hydra > /dev/null 2>&1
sleep 12

# Plex Container
docker create \
--name plex \
--network=isolated \
-e PLEX_UID=1000 -e PLEX_GID=1000 \
-e TZ=Europe/London \
-e PLEX_CLAIM="USERPCLAIM" \
-v /home/USERNAME/Plex:/config \
-v /home/USERNAME/Plex:/transcode \
-v /home/USERNAME/Plex:/data \
-v /home/USERNAME/Scripts:/Scripts \
plexinc/pms-docker > /dev/null 2>&1
sleep 12
echo "- Complete"

# Configure Dockers and Proxy
# Start dockers to build configuration files
docker start letsencrypt
sleep 12
docker start nzbget
sleep 12
docker start sonarr
sleep 12
docker start radarr
sleep 12
docker start hydra
sleep 12
docker start plex
sleep 12

# Configure Lets Encrypt
echo "Please enter password to access restricted sites (sonarr, radarr, nzbget and hydra)"
docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd USERBASICAUTH
sudo rm /home/USERNAME/Proxy/nginx/site-confs/default
/bin/cat <<EOM >/home/USERNAME/Proxy/nginx/site-confs/default
# main server block
server {
	listen 443 ssl default_server;

	root /config/www;
	index index.html index.htm index.php;

	server_name _;

	ssl_certificate /config/keys/letsencrypt/fullchain.pem;
	ssl_certificate_key /config/keys/letsencrypt/privkey.pem;
	ssl_dhparam /config/nginx/dhparams.pem;
	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
	ssl_prefer_server_ciphers on;

	client_max_body_size 0;

	location / {
		try_files $uri $uri/ /index.html /index.php?$args =404;
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
		location /tv {
		auth_basic "Restricted";
                auth_basic_user_file /config/nginx/.htpasswd;
		proxy_pass http://172.18.0.4:8989;
		include /config/nginx/proxy.conf;
	}
                location /film {
		auth_basic "Restricted";
                auth_basic_user_file /config/nginx/.htpasswd;
                proxy_pass http://172.18.0.5:7878;
                include /config/nginx/proxy.conf;
        }
		location ~ ^/nzbget($|./*) {
		rewrite /nzbget/(.*) /$1 break;
                auth_basic "Restricted";
                auth_basic_user_file /config/nginx/.htpasswd;
		proxy_pass http://172.18.0.3:6789;
         }
                location ~ ^/nzbget$ {
                return 302 $scheme://$host$request_uri/;
         }
		location /hydra {
		auth_basic "Restricted";
                auth_basic_user_file /config/nginx/.htpasswd;
                proxy_pass http://172.18.0.6:5075;
                include /config/nginx/proxy.conf;
        }

}
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

#Upstream to Plex
upstream plex_backend {
    server 172.18.0.7:32400;
    keepalive 32;
}

server {
	listen 80;
	listen 443 ssl http2; #http2 can provide a substantial improvement for streaming: https://blog.cloudflare.com/introducing-http2/
	server_name plex.USERURL;

	send_timeout 100m; #Some players don't reopen a socket and playback stops totally instead of resuming after an extended pause (e.g. Chrome)

	#Faster resolving, improves stapling time. Timeout and nameservers may need to be adjusted for your location Google's have been used here.
	resolver 8.8.4.4 8.8.8.8 valid=300s;
	resolver_timeout 10s;

	#Use letsencrypt.org to get a free and trusted ssl certificate
	ssl_certificate /config/keys/letsencrypt/fullchain.pem;
	ssl_certificate_key /config/keys/letsencrypt/privkey.pem;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_prefer_server_ciphers on;
	#Intentionally not hardened for security for player support and encryption video streams has a lot of overhead with something like AES-256-GCM-SHA384.
	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';

	#Why this is important: https://blog.cloudflare.com/ocsp-stapling-how-cloudflare-just-made-ssl-30/
	ssl_stapling on;
	ssl_stapling_verify on;
	#For letsencrypt.org you can get your chain like this: https://esham.io/2016/01/ocsp-stapling
#	ssl_trusted_certificate /path/to/chain.pem;

	#Reuse ssl sessions, avoids unnecessary handshakes
	#Turning this on will increase performance, but at the cost of security. Read below before making a choice.
	#https://github.com/mozilla/server-side-tls/issues/135
	#https://wiki.mozilla.org/Security/Server_Side_TLS#TLS_tickets_.28RFC_5077.29
	#ssl_session_tickets on;
	ssl_session_tickets off;

	#Use: openssl dhparam -out dhparam.pem 2048 - 4096 is better but for overhead reasons 2048 is enough for Plex.
	ssl_dhparam /config/nginx/dhparams.pem;
	ssl_ecdh_curve secp384r1;

	#Will ensure https is always used by supported browsers which prevents any server-side http > https redirects, as the browser will internally correct any request to https.
	#Recommended to submit to your domain to https://hstspreload.org as well.
	#!WARNING! Only enable this if you intend to only serve Plex over https, until this rule expires in your browser it WONT BE POSSIBLE to access Plex via http, remove 'includeSubDomains;' if you only want it to effect your Plex (sub-)domain.
	#This is disabled by default as it could cause issues with some playback devices it's advisable to test it with a small max-age and only enable if you don't encounter issues. (Haven't encountered any yet)
	#add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

	#Plex has A LOT of javascript, xml and html. This helps a lot, but if it causes playback issues with devices turn it off. (Haven't encountered any yet)
	gzip on;
	gzip_vary on;
	gzip_min_length 1000;
	gzip_proxied any;
	gzip_types text/plain text/html text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
	gzip_disable "MSIE [1-6]\.";

	#Nginx default client_max_body_size is 1MB, which breaks Camera Upload feature from the phones.
	#Increasing the limit fixes the issue. Anyhow, if 4K videos are expected to be uploaded, the size might need to be increased even more
	client_max_body_size 100M;

	#Forward real ip and host to Plex
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_set_header X-Forwarded-Proto $scheme;

	#Websockets
	proxy_http_version 1.1;
	proxy_set_header Upgrade $http_upgrade;
	proxy_set_header Connection "upgrade";

	#Buffering off send to the client as soon as the data is received from Plex.
	proxy_redirect off;
	proxy_buffering off;

	location / {
		proxy_pass http://plex_backend;
	}
}
EOM

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
sleep 12

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
sleep 12

# Configure Hydra
sed -i~ -e 's="urlBase": null,="urlBase": /hydra,=g' /home/USERNAME/NzbHydra/hydra/settings.cfg
docker restart hydra
sleep 12

echo "Installation Complete. Please reboot"

exit
