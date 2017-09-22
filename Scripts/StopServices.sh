#! /bin/bash

# Unmount mounts and Stop Dockers
echo "Stopping Containers and unmounting."
docker stop $(docker ps -a -q) > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Radarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Sonarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Mount/Plex/Media > /dev/null 2>&1
echo "- Completed"

exit
