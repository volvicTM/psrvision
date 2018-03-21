#! /bin/bash

##### Unmounts #####
/bin/fusermount -uz /home/plex/Mount/Plexdrive/4kfilm
/bin/fusermount -uz /home/plex/Mount/Plexdrive/film
/bin/fusermount -uz /home/plex/Mount/Plexdrive/4ktv
/bin/fusermount -uz /home/plex/Mount/Plexdrive/tv

##### Plexdrive Mounts #####
### 4K Film Plexdrive ###
# Log # 
PD4KFLOG="/home/plex/Scripts/logs/plexdrive/pdmount-4kfilm.log"
# Mount #
/usr/local/sbin/plexdrive mount -c /home/plex/Plexdrive/configs/4kfilm /home/plex/Mount/Plexdrive/4kfilm \
--cache-file=/home/plex/Plexdrive/4kfilm/cache.bolt \
-o allow_other \
--chunk-check-threads=10 \
--chunk-load-ahead=4 \
--chunk-load-threads=10 \
--chunk-size=10M \
--max-chunks=200 \
--refresh-interval=1m \
-v 2 &>>"$PD4KFLOG" &

sleep 2

### Film Plexdrive ###
# Log # 
PDFLOG="/home/plex/Scripts/logs/plexdrive/pdmount-film.log"
# Mount #
/usr/local/sbin/plexdrive mount -c /home/plex/Plexdrive/configs/film /home/plex/Mount/Plexdrive/film \
--cache-file=/home/plex/Plexdrive/film/cache.bolt \
-o allow_other \
--chunk-check-threads=10 \
--chunk-load-ahead=4 \
--chunk-load-threads=10 \
--chunk-size=10M \
--max-chunks=200 \
--refresh-interval=1m \
-v 2 &>>"$PDFLOG" &

sleep 2

### TV Plexdrive ###
# Log # 
PDTVLOG="/home/plex/Scripts/logs/plexdrive/pdmount-tv.log"
# Mount #
/usr/local/sbin/plexdrive mount -c /home/plex/Plexdrive/configs/tv /home/plex/Mount/Plexdrive/tv \
--cache-file=/home/plex/Plexdrive/tv/cache.bolt \
-o allow_other \
--chunk-check-threads=10 \
--chunk-load-ahead=4 \
--chunk-load-threads=10 \
--chunk-size=10M \
--max-chunks=200 \
--refresh-interval=1m \
-v 2 &>>"$PDTVLOG" &

sleep 2

### 4K TV Plexdrive ###
# Log # 
PD4KTVLOG="/home/plex/Scripts/logs/plexdrive/pdmount-4ktv.log"
# Mount #
/usr/local/sbin/plexdrive mount -c /home/plex/Plexdrive/configs/4ktv /home/plex/Mount/Plexdrive/4ktv \
--cache-file=/home/plex/Plexdrive/4ktv/cache.bolt \
-o allow_other \
--chunk-check-threads=10 \
--chunk-load-ahead=4 \
--chunk-load-threads=10 \
--chunk-size=10M \
--max-chunks=200 \
--refresh-interval=1m \
-v 2 &>>"$PDTVLOG" &

sleep 2

exit
