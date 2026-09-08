# Linux Load Test Assignment

This repository contains the complete implementation, automation scripts, system execution proofs, and final observations for the BongoDev Linux Fundamentals / DevOps Practical Lab.

## Student Information
- **Name:** Raihan Islam
- **Service Account Used (`$SVC_NAME`):** `bgdsvc_raihan`

---

## Repository Structure
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
    ├── 00_svc_name.png
    ├── 01_id_created.png
    ├── 02_df_before.png
    ├── 02_df_after.png
    ├── 03_free_before.png
    ├── 03_free_during.png
    ├── 03_free_after.png
    ├── 03_dmesg_oom.png
    ├── 04_ssh_success.png
    ├── 05_crontab_l.png
    └── 06_cleanup_verify.png

---

## Deliverables & Execution Overview
1. **User Creation & Idempotency:** Created isolated service user securely.
2. **Tmpfs Setup:** Mounted a memory-based filesystem with a strict size cap.
3. **Stress Testing:** Conducted CPU, memory, and I/O load tests using stress tools and analyzed OOM behavior.
4. **SSH Hardening:** Configured key-based authentication on custom port 2222 with password login disabled.
5. **Cron Monitoring & Logrotate:** Automated routine health checks, log cleanup, and log rotation.
6. **Cleanup:** Executed safe, reverse-order unmounting and account deletion.
