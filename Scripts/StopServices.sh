#! /bin/bash

# Unmount mounts and Stop Dockers
echo "Stopping Containers and unmounting."
docker stop $(docker ps -a -q) > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Plex/Media > /dev/null 2>&1
echo "- Completed"

exit
