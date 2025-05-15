# mvmm — Multi-VM Monitor for Proxmox

**mvmm** (Multi-VM Monitor) is a lightweight daemon that monitors the health of multiple VMs on a Proxmox node or cluster.  
If a VM becomes unhealthy (e.g., no network service responds), **mvmm** automatically reboots it.

Designed for **reliability**, **mvmm** uses isolated processes per VM and clean systemd integration.

---

## ✨ Features

- Monitor any number of VMs from a simple config file
- Supports VM migration from one Proxmox node to another
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

### Clone the repository

```bash
git clone https://github.com/peterhaijen/mvmm.git
cd mvmm
```
### Use the official repository

A recent version of mvmm will be available at [the official repository](https://repo.qb21.nl/).

---

## ⚙️ Configuration

### Global settings

The configuratio files are installed in '/etc/pve/mvmm'. This location is automatically synced by Proxmox to all nodes in the cluster. This makes it easy to maintain a uniform configuration accross all members of the cluster.

There is a global configuration file `/etc/pve/mvmm/mvmm.conf`, with settings that apply to all VMs.

| Field             | Meaning |
|:------------------|:--------|
| `ip`               | IP address of VM to monitor |
| `name`             | Name of the VM to monitor, used for logging |
| `portsall`         | Space-separated list of ports; all must be responsive |
| `portsany`         | Space-separated list of ports; at least one must be responsive |
| `check_interval`   | Seconds between health checks when healthy |
| `fail_interval`    | Seconds between checks when a failure is detected |
| `fail_threshold`   | **Seconds** of continuous failure allowed before reboot |
| `wait_interval`    | Seconds to wait during shutdown/startup steps |
| `log_interval`     | Seconds between "still running" logs during healthy operation |
| `recovery_time`    | Seconds after a reboot necesary for the VM to be operational again |

✅ All time values are **in seconds**.

✅ **Fail threshold** is a time duration, **not a number of failures**.

```
$ cat /etc/pve/mvmm/mvmm.conf 
check_interval=2
fail_interval=15
fail_threshold=30
wait_interval=15
log_interval=900
```

### VM specific settings

For each specific VM, a configuration file '/etc/pve/mvmm/<VMID>.conf' must be created.
Settings in this configuration file will override global settings.
Typically, this will contain the IP address and port numbers to monitor.

```
$ cat /etc/pve/mvmm/100.conf
name=nginx
ip=192.168.1.25
portsall=80
```
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

This uses the `Makefile` to:

- Package binaries, config and systemd unit
- Install appropriate `postinst`, `prerm`, `postrm` hooks

1. Build `mvmm` as a `.deb` file:

```bash
make
```

2. Install the Debian package:

```bash
sudo dpkg -i mvmm_*.deb
```

This will:
- Install the `mvmm` per script to `/usr/local/bin/mvmm`
- Install a default config `/etc/pve/mvmm/mvmm.conf`
- Install systemd service `/etc/systemd/system/mvmm.service`
- Automatically enable and start the `mvmm` systemd service.

---

## 🧹 Uninstalling

To remove `mvmm` cleanly:

```bash
sudo systemctl stop mvmm
sudo systemctl disable mvmm
sudo apt remove mvmm
```

Pre- and Post-removal scripts should handle this.

---

## 📜 License

MIT License.

You are free to use, modify, and distribute.

---

## 👨‍💻 Credits

Developed through collaboration between:

- **Me** — making life difficult for ChatGPT, and coding away the halucinations
- **ChatGPT** — assisting with architecture, reliability design, implementation, and packaging

This project follows strict traditional Unix principles:  
simple, reliable, durable, transparent.

---
