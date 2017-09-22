#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/gdrive
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/local
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/Media

#Mount
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/USERNAME/Mount/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/USERNAME/Mount/Radarr/local=RW:/home/USERNAME/Mount/Radarr/gdrive=RO /home/USERNAME/Mount/Radarr/Media/

exit
