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
