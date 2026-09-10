# Linux Load Test Assignment

This repository contains the complete implementation, automation scripts, system execution proofs, and final observations for the BongoDev Linux Fundamentals / DevOps Practical Lab.

## Student Information
- **Name:** Raihan Islam
- **Service Account Used (`$SVC_NAME`):** `bgdsvc_raihan`

---

## Repository Structure

```
linux-load-test-raihan/
├── README.md
├── observations.md
├── scripts/
│   ├── 01_create_user.sh
│   ├── 02_setup_tmpfs.sh
│   ├── 03_stress_and_populate.sh
│   ├── 04_cleanup.sh
│   ├── bgdsvc_raihan_monitor.sh
│   └── bgdsvc_raihan_cleanup_old_files.sh
└── screenshots/
    ├── 00_svc_name.png            # echo $SVC_NAME
    ├── 01_id_created.png          # id $SVC_NAME right after creation
    ├── 02_df_before.png           # df -h before tmpfs mount
    ├── 02_df_after.png            # df -h after tmpfs mount
    ├── 03_free_before.png         # free -h before stress test
    ├── 03_free_during.png         # free -h during stress test
    ├── 03_free_after.png          # free -h after stress test
    ├── 03_dmesg_oom.png           # dmesg | grep -i oom
    ├── 04_ssh_success.png         # SSH connection succeeding on hardened port
    ├── 05_crontab_l.png           # crontab -l -u $SVC_NAME
    └── 06_cleanup_verify.png      # final verification block from 04_cleanup.sh
```

> Note: rename your actual screenshot files to this exact list before committing —
> the previous commit history had filenames (`04_stress_install.png`,
> `06_ssh_config.png`, `09_logrotate_d.png`, `11_tmpfs_mount.png`, etc.) that no
> longer match what this README describes. Keep the README and the real files in
> the folder in sync going forward.

---

## How to Run (in order)

```bash
sudo ./scripts/01_create_user.sh          # Part 1 — create bgdsvc_raihan (idempotent)
sudo ./scripts/02_setup_tmpfs.sh          # Part 2 — mount 256M tmpfs (idempotent)
sudo ./scripts/03_stress_and_populate.sh  # Part 3 — disk / CPU / memory / combined stress
```

**Part 4 — SSH key-based access**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/bgdsvc_raihan_key
sudo mkdir -p /home/bgdsvc_raihan/.ssh
sudo cp ~/.ssh/bgdsvc_raihan_key.pub /home/bgdsvc_raihan/.ssh/authorized_keys
sudo chown -R bgdsvc_raihan:bgdsvc_raihan /home/bgdsvc_raihan/.ssh
sudo chmod 700 /home/bgdsvc_raihan/.ssh
sudo chmod 600 /home/bgdsvc_raihan/.ssh/authorized_keys
```

**Part 5 — SSH hardening** (edit `/etc/ssh/sshd_config`, then `sudo systemctl restart sshd`)
```
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers bgdsvc_raihan
```
Test the new connection/port **before** closing the terminal you used to make the change, so a mistake in the config doesn't lock you out.

**Part 6 — Cron monitoring + cleanup**
```bash
sudo cp scripts/bgdsvc_raihan_monitor.sh /usr/local/bin/
sudo cp scripts/bgdsvc_raihan_cleanup_old_files.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/bgdsvc_raihan_monitor.sh /usr/local/bin/bgdsvc_raihan_cleanup_old_files.sh
sudo crontab -u bgdsvc_raihan -e
```
Add:
```
*/5 * * * * /usr/local/bin/bgdsvc_raihan_monitor.sh
0 2 * * *   /usr/local/bin/bgdsvc_raihan_cleanup_old_files.sh
```

**Part 7 — Logrotate**
```bash
sudo mkdir -p /var/log/bgdsvc_raihan
sudo chown bgdsvc_raihan:bgdsvc_raihan /var/log/bgdsvc_raihan
sudo tee /etc/logrotate.d/bgdsvc_raihan > /dev/null << 'CONF'
/var/log/bgdsvc_raihan/*.log {
    daily
    rotate 5
    compress
    missingok
    notifempty
    size 5M
    create 0640 bgdsvc_raihan bgdsvc_raihan
}
CONF
sudo logrotate -f /etc/logrotate.d/bgdsvc_raihan
ls -lh /var/log/bgdsvc_raihan
```

**Part 8 — Cleanup**
```bash
sudo ./scripts/04_cleanup.sh
```

---

## Deliverables & Execution Overview
1. **User Creation & Idempotency (`01_create_user.sh`):** Creates `bgdsvc_raihan` as a system account with `/usr/sbin/nologin`; safe to re-run.
2. **Tmpfs Setup (`02_setup_tmpfs.sh`):** Mounts a 256M tmpfs at `/mnt/bgdsvc_raihan_tmp`, owned by the service account; safe to re-run.
3. **Stress Testing (`03_stress_and_populate.sh`):** Fills the tmpfs to its cap, then runs CPU, memory, and combined stress with `free -h`/`df -h`/`dmesg` captured at each stage — see `observations.md` for what was actually seen.
4. **SSH Key-Based Access:** Key pair generated, public key installed for the service account.
5. **SSH Hardening:** Custom port `2222`, `PermitRootLogin no`, `PasswordAuthentication no`, access restricted to `bgdsvc_raihan`.
6. **Cron Monitoring & Cleanup (`bgdsvc_raihan_monitor.sh`, `bgdsvc_raihan_cleanup_old_files.sh`):** Health snapshot every 5 minutes, stale tmpfs files purged nightly at 2 AM.
7. **Logrotate:** Daily rotation of `/var/log/bgdsvc_raihan/*.log`, 5 rotations kept, compressed.
8. **Cleanup (`04_cleanup.sh`):** Idempotent, reverse-order teardown (processes → cron/scripts → logrotate config → unmount → logs → account), with a final verification block.

## Commit Convention
One commit per part (Part 1 … Part 8), each including the script(s), any config snippet, and the matching screenshot(s) for that part. The SSH private key is never committed.
