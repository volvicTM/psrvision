#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/Media
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/gdrive
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/local

#Mount
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/sonarrmount.log \
Sonarr_Crypt: /home/USERNAME/Mount/Sonarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/USERNAME/Mount/Sonarr/local=RW:/home/USERNAME/Mount/Sonarr/gdrive=RO /home/USERNAME/Mount/Sonarr/Media/

exit
