#!/bin/bash
SVC_NAME="bgdsvc_raihan"
MOUNT_POINT="/mnt/${SVC_NAME}_tmp"

if mountpoint -q "$MOUNT_POINT"; then
    echo "tmpfs is already mounted at $MOUNT_POINT"
else
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount -t tmpfs -o size=256M tmpfs "$MOUNT_POINT"
    sudo chown "$SVC_NAME:$SVC_NAME" "$MOUNT_POINT"
    echo "tmpfs successfully mounted at $MOUNT_POINT"
fi

