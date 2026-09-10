#!/bin/bash
# Part 6 — Monitoring script, run every 5 minutes by cron.
# Deploy with:
#   sudo cp bgdsvc_raihan_monitor.sh /usr/local/bin/bgdsvc_raihan_monitor.sh
#   sudo chmod +x /usr/local/bin/bgdsvc_raihan_monitor.sh
# Schedule with (as the service account):
#   sudo crontab -u bgdsvc_raihan -e
#   */5 * * * * /usr/local/bin/bgdsvc_raihan_monitor.sh

SVC_NAME="bgdsvc_raihan"
LOGDIR="/var/log/${SVC_NAME}"
LOGFILE="${LOGDIR}/monitoring.log"

sudo mkdir -p "$LOGDIR"

{
    echo "---- $(date) ----"
    echo "[memory]"
    free -h
    echo "[disk - tmpfs]"
    df -h "/mnt/${SVC_NAME}_tmp" 2>/dev/null || echo "tmpfs not mounted"
    echo "[processes owned by ${SVC_NAME}]"
    ps -u "$SVC_NAME" 2>/dev/null || echo "no processes"
    echo
} >> "$LOGFILE"
