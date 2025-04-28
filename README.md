# mvmm — Multi-VM Monitor for Proxmox

**mvmm** (Multi-VM Monitor) is a lightweight daemon that monitors the health of multiple VMs on a Proxmox node or cluster.  
If a VM becomes unhealthy (e.g., no network service responds), **mvmm** automatically reboots it.

Designed for **reliability**, **mvmm** uses isolated processes per VM and clean systemd integration.

---

## ✨ Features

- Monitor any number of VMs from a simple config file
- Per-VM health check via TCP port responsiveness
- Automatic reboot after configurable failure thresholds
- Maintenance mode toggle (disable reboot during maintenance)
- Independent child process per VM (fault isolation)
- Supervisor process auto-restarts any crashed monitors
- Full syslog logging (with per-VM tagging)
- Clean Debian package
- Minimal resource usage (only one lightweight process per VM)
- Written entirely in Perl with standard modules

---

## 📦 Requirements

You must have installed:

- Perl 5
- These Perl modules (available via apt):

```bash
apt install perl libdbi-perl libdbd-sqlite3-perl libio-socket-inet-perl libsys-syslog-perl netcat-openbsd
```

Tested on Debian 12 and Proxmox 8.

---

## 🛠 Installation

1. Clone the repository:

```bash
git clone <your-repo-url>
cd mvmm
```

2. Build and install the Debian package:

```bash
make deb
sudo dpkg -i mvmm_1.0_all.deb
```

This will:
- Install the `mvmm` binary to `/usr/local/bin/mvmm`
- Install default config `/etc/mvmm.conf`
- Install systemd service `/etc/systemd/system/mvmm.service`
- Create the database directory `/var/lib/mvmm/`
- Automatically enable and start the `mvmm` systemd service.

---

## ⚙️ Configuration

Edit `/etc/mvmm.conf` to define VMs to monitor.

Each VM has a `[section]` with parameters:

Example:

```ini
[pi-vm]
VMID=413
IP=192.168.1.105
PORTSALL=80
PORTSANY=5000 5001 5002 5003
CHECK_INTERVAL=2
FAIL_INTERVAL=15
FAIL_THRESHOLD=30
WAIT_INTERVAL=15
LOG_INTERVAL=900

[backup-vm]
VMID=420
IP=192.168.1.110
PORTSALL=443
PORTSANY=8080
CHECK_INTERVAL=5
FAIL_INTERVAL=20
FAIL_THRESHOLD=45
WAIT_INTERVAL=15
LOG_INTERVAL=900
```

| Field             | Meaning |
|:------------------|:--------|
| `VMID`             | Proxmox VM ID (integer, primary key in database) |
| `IP`               | IP address of VM to monitor |
| `PORTSALL`         | Space-separated list of ports; all must be responsive |
| `PORTSANY`         | Space-separated list of ports; at least one must be responsive |
| `CHECK_INTERVAL`   | Seconds between health checks when healthy |
| `FAIL_INTERVAL`    | Seconds between checks when a failure is detected |
| `FAIL_THRESHOLD`   | **Seconds** of continuous failure allowed before reboot |
| `WAIT_INTERVAL`    | Seconds to wait during shutdown/startup steps |
| `LOG_INTERVAL`     | Seconds between "still running" logs during healthy operation |
| `RECOVERY_TIME`    | Seconds after a reboot necesary for the VM to be operational again |

✅ All time values are **in seconds**.

✅ **Fail threshold** is a time duration, **not a number of failures**.

---

## 🏃 Managing the Service

After installation, manage `mvmm` with `systemctl`:

```bash
sudo systemctl start mvmm
sudo systemctl stop mvmm
sudo systemctl restart mvmm
sudo systemctl status mvmm
sudo systemctl enable mvmm
sudo systemctl disable mvmm
```

Check logs via:

```bash
journalctl -u mvmm
```

Logs are tagged under `mvmm` in syslog.

---

## 🛎 Signal Handling

The `mvmm` parent process listens for Unix signals to perform dynamic actions:

| Signal | Effect |
|:-------|:-------|
| `SIGUSR1` | Print current runtime and uptime/downtime stats to syslog |
| `SIGUSR2` | Toggle maintenance mode (no reboot while enabled) |
| `SIGTERM` | Graceful shutdown of all monitoring processes |

Examples:

```bash
kill -USR1 $(pidof mvmm)
kill -USR2 $(pidof mvmm)
kill -TERM $(pidof mvmm)
```

✅ Maintenance mode persists until toggled again.

---

## 🛡️ Supervisor and Process Model

- Each VM is monitored by its own **child process**.
- If a child crashes or exits, the **supervisor** detects and **restarts** it immediately.
- Child processes are fully independent:  
  a slow reboot or crash of one VM **does not affect others**.

---

## 📦 Building the Debian Package

To rebuild `mvmm` as a `.deb` file:

```bash
make deb
```

This uses the `Makefile` to:

- Package binaries, config, systemd unit, and database scripts
- Install appropriate `postinst`, `prerm`, `postrm` hooks

Result:

```bash
mvmm_1.0_all.deb
```

Install it:

```bash
sudo dpkg -i mvmm_1.0_all.deb
```

---

## 🧹 Uninstalling

To remove `mvmm` cleanly:

```bash
sudo systemctl stop mvmm
sudo systemctl disable mvmm
sudo apt remove mvmm
```

Post-removal scripts will reload systemd properly.

---

## 📜 License

MIT License.

You are free to use, modify, and distribute.

---

## 👨‍💻 Credits

Developed through collaboration between:

- **You** — setting extremely high technical quality standards
- **ChatGPT** — assisting with architecture, reliability design, implementation, and packaging

This project follows strict traditional Unix principles:  
simple, reliable, durable, transparent.

---
