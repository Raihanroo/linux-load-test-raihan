#!/bin/bash
# Part 6 — Nightly cleanup script, run once a day by cron.
# Deploy with:
#   sudo cp bgdsvc_raihan_cleanup_old_files.sh /usr/local/bin/bgdsvc_raihan_cleanup_old_files.sh
#   sudo chmod +x /usr/local/bin/bgdsvc_raihan_cleanup_old_files.sh
# Schedule with (as the service account):
#   sudo crontab -u bgdsvc_raihan -e
#   0 2 * * * /usr/local/bin/bgdsvc_raihan_cleanup_old_files.sh

SVC_NAME="bgdsvc_raihan"
TMPDIR="/mnt/${SVC_NAME}_tmp"
LOGDIR="/var/log/${SVC_NAME}"
LOGFILE="${LOGDIR}/monitoring.log"

sudo mkdir -p "$LOGDIR"

if [ -d "$TMPDIR" ]; then
    REMOVED=$(find "$TMPDIR" -type f -mtime +1 -print -delete | wc -l)
else
    REMOVED=0
fi

echo "$(date): cleanup run - removed ${REMOVED} file(s) older than 1 day from ${TMPDIR}" >> "$LOGFILE"
