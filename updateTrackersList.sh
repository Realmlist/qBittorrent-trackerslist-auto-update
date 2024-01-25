#!/bin/bash

#Retrieve latest tracker list and apply

QBITTORRENT_SERVER="localhost";
QBITTORRENT_PORT=8080;

LOG_FILE=/config/trackers-list/updateTrackersList.log

if [ ! -e "$LOG_FILE" ] ; then
    mkdir -p /config/trackers-list
    touch "$LOG_FILE"
fi

if [ ! -w "$LOG_FILE" ] ; then
    echo cannot write to $LOG_FILE
    exit 1
fi

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}


qbt_getcurrenttrackerlist(){
    curl -s -i "http://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/app/preferences" | awk -F'"' '/"add_trackers":/{print $4}'
}

qbt_gettrackerlist(){
    # Adjust URL to your preference
    # See https://github.com/ngosang/trackerslist
    curl -s "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt" | sed ':a;N;$!ba;s/\n/\\n/g'
}

#Function to update the trackers through the qBittorrent API
qbt_updatetrackers(){
    curl -s -i --data-urlencode "json={\"add_trackers\":${NEW_TRACKERS},\"add_trackers_enabled\":true}" "http://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/app/setPreferences"
}


CURRENT_TRACKERS="\"$(qbt_getcurrenttrackerlist)\"";
NEW_TRACKERS="\"$(qbt_gettrackerlist)\"";

#Determine if the tracker list has changed from what is configured
if [ ${NEW_TRACKERS} != ${CURRENT_TRACKERS} ]; then
    echo "------------------------------START OF RUN------------------------------";
    #Notify of tracker update
    echo "$(timestamp) The tracker list has changed";

    #Now use qBittorrent API to update the active configuration and wait 5 seconds for the configuration to update in the background
    echo "$(timestamp) Updating qBittorrent with the new trackers: $(qbt_updatetrackers).. waiting 5 seconds for configuration to update. $(sleep 5)";

    #Run function again to find the updated port in the qBittorrent configuration
    UPDATED_TRACKERS="\"$(qbt_getcurrenttrackerlist)\"";

        #Verify the configured trackers now match the active trackers
        if [ ${UPDATED_TRACKERS} = ${CURRENT_TRACKERS} ]; then
            #If trackers are correct write out the success to the specified log file
            echo "$(timestamp) The trackers were succesfully updated.";
        else
            #We attempted to update qBittorrent, but the values don't match so time to panic
            echo "$(timestamp) Something went wrong.";
        fi
    echo "-------------------------------END OF RUN-------------------------------";
else
    #Nothing needs to be done because the values already match
    echo "------------------------------START OF RUN------------------------------";
    echo "$(timestamp) Configured trackers are already up-to-date!";
    echo "-------------------------------END OF RUN-------------------------------";
fi >> $LOG_FILE
