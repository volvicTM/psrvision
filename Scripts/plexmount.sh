#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Plex/Media

#Mount
/usr/local/sbin/rclone mount \
--tpslimit 4 \
--read-only \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/plexmount.log \
Plex_Crypt: /home/USERNAME/Plex/Media &

exit
