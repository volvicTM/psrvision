#! /bin/bash

# Unmount mounts and Stop Dockers
echo "Stopping Containers and unmounting."
docker stop $(docker ps -a -q) > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Radarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Radarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Radarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kRadarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kRadarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kRadarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Sonarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Sonarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Sonarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kSonarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kSonarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/4kSonarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Plex/Media/"TV Shows" > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Plex/Media/Movies > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Plexdrive > /dev/null 2>&1
/bin/fusermount -uz /home/plex/Mount/Plexdrive/film > /dev/null 2>&1 
/bin/fusermount -uz /home/plex/Mount/Plexdrive/tv > /dev/null 2>&1 
/bin/fusermount -uz /home/plex/Mount/Plexdrive/4kfilm > /dev/null 2>&1 


echo "- Completed"

exit
