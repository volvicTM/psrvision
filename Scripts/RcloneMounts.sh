#! /bin/bash

##### Unmounts #####
/bin/fusermount -uz /home/plex/Mount/Radarr/gdrive
/bin/fusermount -uz /home/plex/Mount/Radarr/local
/bin/fusermount -uz /home/plex/Mount/Radarr/Media
/bin/fusermount -uz /home/plex/Mount/Sonarr/Media
/bin/fusermount -uz /home/plex/Mount/Sonarr/gdrive
/bin/fusermount -uz /home/plex/Mount/Sonarr/local
/bin/fusermount -uz /home/plex/Mount/4kSonarr/Media
/bin/fusermount -uz /home/plex/Mount/4kSonarr/gdrive
/bin/fusermount -uz /home/plex/Mount/4kSonarr/local
/bin/fusermount -uz /home/plex/Mount/4kRadarr/gdrive
/bin/fusermount -uz /home/plex/Mount/4kRadarr/local
/bin/fusermount -uz /home/plex/Mount/4kRadarr/Media
/bin/fusermount -uz /home/plex/Mount/Plex/Media/4kMovies
/bin/fusermount -uz /home/plex/Mount/Plex/Media/Movies
/bin/fusermount -uz /home/plex/Mount/Plex/Media/"TV Shows"
/bin/fusermount -uz /home/plex/Mount/Plex/Media/"4k TV Shows"

##### Rclone Direct Mounts #####
### Rclone-Radarr-film ###
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/rclone/radarrmount.log \
Radarr_Crypt: /home/plex/Mount/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/plex/Mount/Radarr/local=RW:/home/plex/Mount/Radarr/gdrive=RO /home/plex/Mount/Radarr/Media/

sleep 2

### Rclone-Sonarr-tv ###
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/rclone/sonarrmount.log \
Sonarr_Crypt: /home/plex/Mount/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/plex/Mount/Sonarr/local=RW:/home/plex/Mount/Sonarr/gdrive=RO /home/plex/Mount/Sonarr/Media/

sleep 2

### Rclone-Radarr-4kfilms ###
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/rclone/4kradarrmount.log \
4kRadarr_Crypt: /home/plex/Mount/4kRadarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/plex/Mount/4kRadarr/local=RW:/home/plex/Mount/4kRadarr/gdrive=RO /home/plex/Mount/4kRadarr/Media/

sleep 2

### Rclone-Sonarr-4ktv ###
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/plex/Scripts/logs/rclone/4ksonarrmount.log \
4kSonarr_Crypt: /home/plex/Mount/4kSonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/plex/Mount/4kSonarr/local=RW:/home/plex/Mount/4kSonarr/gdrive=RO /home/plex/Mount/4kSonarr/Media/

sleep 2

##### Rclone Mounts for Plexdrive #####
### Plexdrive-Rclone-Plex-4kfilms ###
/usr/local/sbin/rclone mount \
--allow-other \
--log-file=/home/plex/Scripts/logs/rclone/plexmount-4kfilm.log \
-v \
PD4kFILM: /home/plex/Mount/Plex/Media/4kMovies &

sleep 2

### Plexdrive-Rclone-Plex-films ###
/usr/local/sbin/rclone mount \
--allow-other \
--log-file=/home/plex/Scripts/logs/rclone/plexmount-film.log \
-v \
PDFILM: /home/plex/Mount/Plex/Media/Movies &

sleep 2

### Plexdrive-Rclone-Plex-tv ###
/usr/local/sbin/rclone mount \
--allow-other \
--log-file=/home/plex/Scripts/logs/rclone/plexmount-tv.log \
-v \
PDTV: /home/plex/Mount/Plex/Media/"TV Shows" &

sleep 2

### Plexdrive-Rclone-Plex-tv ###
/usr/local/sbin/rclone mount \
--allow-other \
--log-file=/home/plex/Scripts/logs/rclone/plexmount-4ktv.log \
-v \
PDTV: /home/plex/Mount/Plex/Media/"4k TV Shows" &

exit
