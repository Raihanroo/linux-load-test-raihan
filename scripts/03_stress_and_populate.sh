#!/bin/bash
# Part 3 — Stress testing (disk, CPU, memory, and all three combined)
# Run as: sudo ./03_stress_and_populate.sh
# Requires: 01_create_user.sh and 02_setup_tmpfs.sh already run.

set -uo pipefail

SVC_NAME="bgdsvc_raihan"
MOUNT_POINT="/mnt/${SVC_NAME}_tmp"

if ! id "$SVC_NAME" &>/dev/null; then
    echo "ERROR: user $SVC_NAME does not exist. Run 01_create_user.sh first." >&2
    exit 1
fi

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "ERROR: $MOUNT_POINT is not mounted. Run 02_setup_tmpfs.sh first." >&2
    exit 1
fi

if ! command -v stress &>/dev/null; then
    echo "'stress' not found, installing..."
    sudo apt-get update -y && sudo apt-get install -y stress
fi

echo "=============================================="
echo "3.1 — Fill the disk (tmpfs, 256M cap)"
echo "=============================================="
echo "--- df -h before ---"
df -h "$MOUNT_POINT"

for i in $(seq 1 30); do
    sudo -u "$SVC_NAME" dd if=/dev/zero of="${MOUNT_POINT}/file_${i}.dat" bs=1M count=10 2>/dev/null
    if [ $? -ne 0 ]; then
        echo ">> Write for file_${i}.dat failed/stopped — tmpfs cap reached (expected behaviour, no data corruption)."
        break
    fi
done

echo "--- df -h after (should be at/near 100%) ---"
df -h "$MOUNT_POINT"

echo
echo "=============================================="
echo "3.2 — Push the CPU"
echo "=============================================="
sudo -u "$SVC_NAME" stress --cpu 2 --timeout 30s

echo
echo "=============================================="
echo "3.3 — Squeeze the memory"
echo "=============================================="
echo "--- free -h before ---"
free -h
sudo -u "$SVC_NAME" stress --vm 1 --vm-bytes 200M --timeout 60s &
STRESS_PID=$!
sleep 5
echo "--- free -h during ---"
free -h
wait "$STRESS_PID"
echo "--- free -h after ---"
free -h

echo
echo "=============================================="
echo "3.4 — All at once (simulated real incident)"
echo "=============================================="
sudo -u "$SVC_NAME" stress --cpu 2 --io 1 --vm 1 --vm-bytes 200M --timeout 30s &
COMBO_PID=$!
sleep 10
echo "--- free -h while combined load is running ---"
free -h
wait "$COMBO_PID"

echo
echo "--- dmesg | grep -i oom (kernel OOM-killer check) ---"
dmesg | grep -i oom || echo "(empty — no OOM-killer event triggered)"

echo
echo "Clean up test files created on tmpfs:"
sudo -u "$SVC_NAME" rm -f "${MOUNT_POINT}"/file_*.dat
echo "Done. Capture screenshots of each '---' section above for the assignment."
