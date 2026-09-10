#!/bin/bash
# Part 8 — Cleanup (Leave No Trace)
# Reverses every step done by 01-03 and the cron/logrotate setup, in the
# opposite order they were created. Safe to re-run even if an earlier
# step already failed partway through (every action checks state first).
# Run as: sudo ./04_cleanup.sh

set -uo pipefail

SVC_NAME="bgdsvc_raihan"
MOUNT_POINT="/mnt/${SVC_NAME}_tmp"
LOGDIR="/var/log/${SVC_NAME}"
MONITOR_SCRIPT="/usr/local/bin/${SVC_NAME}_monitor.sh"
CLEANUP_SCRIPT="/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"
LOGROTATE_CONF="/etc/logrotate.d/${SVC_NAME}"

echo "=== 1. Kill any lingering processes owned by $SVC_NAME ==="
if id "$SVC_NAME" &>/dev/null; then
    sudo pkill -u "$SVC_NAME" 2>/dev/null && echo "Killed leftover processes." || echo "No leftover processes."
else
    echo "User $SVC_NAME does not exist — skipping."
fi

echo
echo "=== 2. Remove the cron automation ==="
if id "$SVC_NAME" &>/dev/null && sudo crontab -u "$SVC_NAME" -l &>/dev/null; then
    sudo crontab -u "$SVC_NAME" -r
    echo "Removed crontab for $SVC_NAME."
else
    echo "No crontab found for $SVC_NAME — skipping."
fi

for f in "$MONITOR_SCRIPT" "$CLEANUP_SCRIPT"; do
    if [ -f "$f" ]; then
        sudo rm -f "$f"
        echo "Removed $f"
    else
        echo "$f already absent — skipping."
    fi
done

echo
echo "=== 3. Remove logrotate config ==="
if [ -f "$LOGROTATE_CONF" ]; then
    sudo rm -f "$LOGROTATE_CONF"
    echo "Removed $LOGROTATE_CONF"
else
    echo "$LOGROTATE_CONF already absent — skipping."
fi

echo
echo "=== 4. Unmount storage ==="
if mountpoint -q "$MOUNT_POINT"; then
    sudo umount "$MOUNT_POINT"
    echo "Unmounted $MOUNT_POINT"
else
    echo "$MOUNT_POINT not mounted — skipping."
fi
if [ -d "$MOUNT_POINT" ]; then
    sudo rmdir "$MOUNT_POINT" 2>/dev/null && echo "Removed directory $MOUNT_POINT" || echo "$MOUNT_POINT not empty/removable — check manually."
fi

echo
echo "=== 5. Remove logs ==="
if [ -d "$LOGDIR" ]; then
    sudo rm -rf "$LOGDIR"
    echo "Removed $LOGDIR"
else
    echo "$LOGDIR already absent — skipping."
fi

echo
echo "=== 6. Finally, remove the service account itself ==="
if id "$SVC_NAME" &>/dev/null; then
    sudo userdel -r "$SVC_NAME" 2>/dev/null
    echo "Deleted user $SVC_NAME"
else
    echo "User $SVC_NAME already absent — skipping."
fi

echo
echo "=============================================="
echo "Verification (all three should show 'nothing found')"
echo "=============================================="
echo "--- id $SVC_NAME (should fail) ---"
id "$SVC_NAME" 2>&1

echo "--- mount | grep $SVC_NAME (should be empty) ---"
mount | grep "$SVC_NAME" || echo "(empty — confirmed)"

echo "--- ps -u $SVC_NAME (should be empty/error) ---"
ps -u "$SVC_NAME" 2>&1

echo
echo "Cleanup complete. Take the final screenshot of this verification block."
