# Load Testing Observations

## Test Summary
* **Service Account:** bgdsvc_raihan
* **Mount Point:** /mnt/bgdsvc_raihan_tmp
* **Allocated tmpfs Size:** 256MB
* **Tools Used:** `stress`, `dd`, `free`, `df`, `dmesg`

## Part 1 — User Creation
The system service user `bgdsvc_raihan` was created as a system account without interactive shell access (`/usr/sbin/nologin`), following the principle of least privilege for a service identity. Re-running `01_create_user.sh` correctly detects the existing account and does nothing (idempotent).

## Part 2 — Tmpfs Setup
A 256MB RAM-backed tmpfs was mounted at `/mnt/bgdsvc_raihan_tmp` and ownership assigned to `bgdsvc_raihan`. Re-running `02_setup_tmpfs.sh` detects the existing mount and skips re-mounting.

## Part 3 — Stress Testing
* **Disk fill:** Writing 10MB files in a loop against the 256M tmpfs cap. As the mount approached 100% usage, further `dd` writes failed with "No space left on device" rather than corrupting existing files — a clean failure, not a crash.
* **CPU:** `stress --cpu 2 --timeout 30s` drove load average up sharply for the duration and returned to baseline immediately after the timeout.
* **Memory:** `stress --vm 1 --vm-bytes 200M --timeout 60s` measurably reduced available memory in `free -h` while running and released it back afterward.
* **Combined (disk + CPU + memory together):** Running all three at once produced a much sharper drop in available memory and a visible load spike compared to any single test — closer to what a real traffic-spike incident looks like.
* **OOM check:** `dmesg | grep -i oom` was checked after every stress run — output was empty every time, confirming the kernel's OOM-killer was never triggered even under combined CPU+I/O+memory load.

## Part 4 — SSH Key-Based Access
An `ed25519` key pair was generated and the public key installed into `bgdsvc_raihan`'s `authorized_keys` (`~/.ssh` set to `700`, `authorized_keys` set to `600`). Connecting as `bgdsvc_raihan` with the private key succeeded without a password prompt, and direct login without a key was refused.

## Part 5 — SSH Hardening
`sshd_config` was updated to move SSH to port `2222`, disable `PermitRootLogin`, and disable `PasswordAuthentication`, restricting access to key-based login for `bgdsvc_raihan` only. The new configuration was verified by opening a **second** session on the new port and confirming login worked before closing the original session — avoiding a lockout if the config had a mistake.

## Part 6 — Cron Monitoring & Cleanup
`bgdsvc_raihan_monitor.sh` is scheduled every 5 minutes and appends memory, tmpfs usage, and process snapshots to `/var/log/bgdsvc_raihan/monitoring.log`. `bgdsvc_raihan_cleanup_old_files.sh` is scheduled nightly at 2 AM and removes tmpfs files older than 1 day, logging how many files were removed. `crontab -l -u bgdsvc_raihan` confirms both jobs are registered.

## Part 7 — Logrotate
A logrotate policy at `/etc/logrotate.d/bgdsvc_raihan` rotates `*.log` files daily, keeps 5 rotations, compresses old logs, and forces rotation early if a log exceeds 5M. Running `logrotate -f` manually produced the expected rotated/compressed file alongside the active log.

## Part 8 — Cleanup
`04_cleanup.sh` tore everything down in reverse order: killed leftover processes owned by the service account, removed its crontab and the two `/usr/local/bin` scripts, removed the logrotate config, unmounted and removed the tmpfs mount point, removed the log directory, and finally deleted the service account. The verification block afterward confirmed `id bgdsvc_raihan` fails, `mount | grep bgdsvc_raihan` is empty, and `ps -u bgdsvc_raihan` returns nothing.

## Reflection
**What did you observe when the system was under load, and what would you do differently if this were a real production server?**

Under combined load, memory pressure was the first thing to visibly degrade the system — CPU stress alone recovered instantly, but memory + disk pressure together came much closer to triggering the kernel OOM-killer. On a real production server I would not run monitoring and cleanup on a 5-minute/nightly cron alone; I'd add real alerting (not just a log file nobody reads at 3 AM), set a memory/CPU threshold that pages someone before the OOM-killer has to step in, and give the service its own cgroup limits instead of relying on tmpfs size caps alone to contain a runaway process.
