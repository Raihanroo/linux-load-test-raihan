# Load Testing Observations

## Test Summary
* **Service Account:** bgdsvc_raihan
* **Mount Point:** /mnt/bgdsvc_raihan_tmp
* **Allocated RAM Size:** 256MB
* **Tool Used:** stress

## Observations
1. **User Creation:** The system service user `bgdsvc_raihan` was configured as a system account without interactive shell access (`/usr/sbin/nologin`) following security best practices.
2. **tmpfs Mount:** A temporary RAM-based filesystem of 256MB was mounted at `/mnt/bgdsvc_raihan_tmp` with ownership assigned to `bgdsvc_raihan`.
3. **Stress Testing:** System memory load was tested using the `stress` utility (`--vm 1 --vm-bytes 300M --timeout 10s`). The stress test completed successfully within the allocated timeframe in the WSL2 environment.

