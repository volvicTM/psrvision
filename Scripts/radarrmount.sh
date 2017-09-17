#! /bin/bash

#Unmount
/bin/fusermount -uz /home/USERNAME/Radarr/gdrive
/bin/fusermount -uz /home/USERNAME/Radarr/local
/bin/fusermount -uz /home/USERNAME/Radarr/Media

#Mount
/usr/local/sbin/rclone mount \
--tpslimit 2 \
--allow-other \
--quiet \
--buffer-size 512M \
--log-file=/home/USERNAME/Scripts/logs/radarrmount.log \
Radarr_Crypt: /home/USERNAME/Radarr/gdrive &

#UnionFuse Local and gdrive into Media
unionfs-fuse -o cow,allow_other,direct_io,auto_cache,sync_read /home/USERNAME/Radarr/local=RW:/home/USERNAME/Radarr/gdrive=RO /home/USERNAME/Radarr/Media/

exit
