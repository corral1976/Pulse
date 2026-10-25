# Pulse-Active

[![GitHub release](https://img.shields.io/github/v/release/corral1976/Pulse?cacheSeconds=3600)](https://github.com/corral1976/Pulse/releases)
[![build](https://img.shields.io/github/actions/workflow/status/corral1976/Pulse/ci.yml?style=flat&label=build&labelColor=282828&color=2ea44f&logo=githubactions&logoColor=fbf1c7&logoSize=auto)](https://github.com/corral1976/Pulse/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![stars](https://img.shields.io/github/stars/corral1976/Pulse?style=flat&label=stars&labelColor=282828&color=d79921&logo=starship&logoColor=fbf1c7&logoSize=auto&cache=refresh)](https://github.com/corral1976/Pulse)

![Pulse Preview](preview.png)

A minimalist and elegant system monitor for the terminal, designed for advanced GNU/Linux users. It offers real-time visualization of CPU (including frequency and history graphs), RAM, disk, network, and temperatures, featuring a design optimized for terminals with modern fonts.

## Features

- **Dual-mode display**: full-colour dashboard with Unicode, or plain ASCII on the Linux console
- **Real-time monitoring**: CPU, RAM, disk, network, temperature and battery
- **Works on any distribution**: a single Bash script, no dependencies beyond the basics
- **Scripting friendly**: `--quiet` / `--once`, and automatic one-line output when piped
- **Light on resources**: slow sensors are cached and refreshed every few seconds
- **Hardware support**: CPU/GPU temperature straight from sysfs (lm-sensors optional), NVIDIA via `nvidia-smi`, AMD, battery
- **Desktop integration**: launcher, icon and man page

## Installation

Pulse is a single Bash script, so it runs on **any Linux distribution**. Pick whichever method suits you:

| Your distribution | Recommended method |
|---|---|
| Debian, Ubuntu, **Linux Mint**, Pop!_OS, Zorin OS, elementary OS, MX Linux and other Debian/Ubuntu-based distros | [Method A: .deb package](#method-a-deb-package-debian-ubuntu-linux-mint-and-derivatives) |
| **Fedora**, RHEL/CentOS/Rocky/Alma, openSUSE, **Arch/Manjaro**, and any other distro | [Method B: install from source](#method-b-install-from-source-any-linux-distribution) |

> **New to Linux?** Debian, Ubuntu and Linux Mint users use Method A. Everyone else uses Method B. The `.deb` format only exists on Debian-family systems.

### Method A: .deb package (Debian, Ubuntu, Linux Mint and derivatives)

1. Download `pulse-active_<version>_all.deb` from the [Releases page](https://github.com/corral1976/Pulse/releases).
2. Install it from the folder where you downloaded it:

```bash
sudo apt install ./pulse-active_*_all.deb
```

This installs the `pulse` command, the desktop launcher, the icon and the man page.

**Building the .deb yourself (optional):**

```bash
git clone https://github.com/corral1976/Pulse.git
cd Pulse
bash BUILD_DEB.sh
sudo apt install ./pulse-active_*_all.deb
```

### Method B: install from source (any Linux distribution)

```bash
git clone https://github.com/corral1976/Pulse.git
cd Pulse
sudo make install                        # installs under /usr/local
```

**No admin rights?** Install for your user only (the command goes to `~/.local/bin`, make sure it is in your `PATH`):

```bash
make install PREFIX=$HOME/.local
```

**Prefer a script?** `install_pulse.sh` does the same and picks the right method for your distro (`--deb`, `--generic`, `--user`, `--prefix DIR`; see `--help`). Download it, review it, then run it:

```bash
curl -fLO https://raw.githubusercontent.com/corral1976/Pulse/main/install_pulse.sh
less install_pulse.sh        # press 'q' to exit
bash install_pulse.sh
```

**No `make` on your system?** One command is enough:

```bash
sudo install -Dm755 src/pulse /usr/local/bin/pulse
```

**Just trying it out?** Run it straight from the downloaded folder, nothing is installed:

```bash
bash src/pulse
```

**Distribution packagers:** `make install PREFIX=/usr DESTDIR=/path/to/pkgdir` follows the usual conventions.

### Check that it works

```bash
pulse --version
```

Then install the [optional dependencies](#optional-dependencies-installation) for your distro if you want GPU info, battery, screen refresh rate, etc. (Pulse runs without them, it just shows less information).

## Usage

```bash
pulse              # Start monitoring
pulse -i 2         # Refresh every 2 seconds
pulse --quiet      # Single-line mode
pulse --once       # Print one line and exit
pulse --help       # Show help
pulse --version    # Show version
```

Press any key to exit. `man pulse` has the full reference.

### Scripting

When standard output is not a terminal (a pipe, a file, cron) Pulse switches to quiet mode by itself and prints one line per interval:

```text
[12:00:00] CPU: 12%  RAM: 34%  DSK:  5%  NET D:0KB/s U:0KB/s  TEMP:45.0°C
```

```bash
pulse --once                      # one sample, then exit
pulse -q -i 5 >> ~/pulse.log      # log a line every 5 seconds
pulse --once | grep -o 'RAM: *[0-9]*%'   # just the RAM field
```

## Options

- `-h, --help` - Show help message
- `-v, --version` - Show version information
- `-i, --interval N` - Refresh interval in seconds (default: 1)
- `-q, --quiet` - Single-line minimal output
- `-1, --once` - Print one quiet-mode line and exit
- `-n, --no-color` - Disable colored output

## Environment Variables

```bash
DISK_PATH=/home pulse    # Monitor /home instead of /
WM=i3 pulse              # Override window manager detection
NO_COLOR=1 pulse         # Same as --no-color
```

## Display modes

- **Full dashboard** (Unicode + colours): used in any graphical session (X11/Wayland) and in UTF-8 terminals such as SSH or tmux sessions. It uses 256 colours when the terminal supports them, 16 otherwise.
- **TTY mode** (ASCII): used on the Linux virtual console (`TERM=linux`) and in terminals that cannot draw Unicode.

## Requirements

- **Required**: Bash 4.0+, Linux with `/proc`, and the usual basic tools (`awk`, `grep`, `sed`, `df`, `stat`, `cut`, `sleep`, `stty`; all part of coreutils/gawk on every distro)
- **Recommended** for enhanced functionality:
  - `lm-sensors` (extra temperature sources; CPU/GPU temperatures are read from sysfs without it on most hardware)
  - NVIDIA driver with `nvidia-smi` (NVIDIA GPU temperature)
  - `mesa-utils` / `glx-utils` (GPU name), `pciutils` (GPU name fallback)
  - `upower` (battery fallback; batteries are read from sysfs first)
  - `xrandr` (screen resolution and refresh rate), `xdpyinfo` (resolution fallback)
  - `procps` (`pgrep`/`ps`, used to detect the window manager and terminal)

Package names differ between distributions, see the next section.

## Optional Dependencies Installation

### Debian/Ubuntu/Linux Mint
```bash
sudo apt install lm-sensors mesa-utils pciutils upower x11-utils x11-xserver-utils procps
sudo sensors-detect
```

### Fedora/RHEL/CentOS
```bash
sudo dnf install lm_sensors glx-utils pciutils upower xdpyinfo xrandr procps-ng
sudo sensors-detect
```

### Arch Linux/Manjaro
```bash
sudo pacman -S lm_sensors mesa-utils pciutils upower xorg-xdpyinfo xorg-xrandr procps-ng
sudo sensors-detect
```

### Other distributions
Install the equivalents of the packages listed under [Requirements](#requirements) with your package manager.

`sensors-detect` is only needed if temperatures show `N/A` and your hardware needs extra kernel modules: answer the questions (the defaults are fine) and, if asked, let it load the suggested modules.

## Troubleshooting

**`Error: missing essential commands: ...`**: install the package that provides the listed command (on minimal installs this is usually `gawk` or `coreutils`).

**Temperatures show `N/A`**: virtual machines and some laptops expose no sensors. On real hardware install `lm-sensors` and run `sudo sensors-detect` (see above).

**Display shows `N/A`**: install `xrandr` (see above). On a Wayland-only session without XWayland the resolution is read from the kernel instead, without the refresh rate.

## How the numbers are calculated

- **CPU history graph**: smoothed and visually amplified so small peaks are visible in 8 height levels. It is a trend, not raw usage; the percentage next to the bar is the real value.
- **Network**: KB/s summed over all interfaces except loopback (`lo`).
- **Disk**: `used / total` of the filesystem at `DISK_PATH`, which can differ slightly from the `Use%` column of `df` (that one excludes space reserved for root).
- **Slow metrics** (temperatures, disk, battery) are refreshed every 5-10 seconds instead of on every frame.

## Development

```bash
make check      # syntax, ShellCheck (if installed) and smoke tests
make deb        # build the .deb
```

Layout: `src/pulse` (the program), `data/` (launcher and icon), `man/` (man page), `packaging/debian/` (package metadata), `Makefile` (generic install), `BUILD_DEB.sh`, `install_pulse.sh` and `uninstall_pulse.sh`. The version lives only in `src/pulse` (`SCRIPT_VERSION`); the package build reads it from there.

## Removal

**Any installation method:**
```bash
bash uninstall_pulse.sh
```
It detects how Pulse was installed (`.deb`, `/usr/local` or `~/.local`), removes it and checks that every file is gone.

**Method A (.deb):**
```bash
sudo apt remove pulse-active
```

**Method B (from source):**
```bash
sudo make uninstall                       # or: make uninstall PREFIX=$HOME/.local
```

## License

MIT License - See LICENSE file for details.

## Support

- **Repository**: https://github.com/corral1976/Pulse
- **Issues**: https://github.com/corral1976/Pulse/issues
- **Support**: https://ko-fi.com/retrolcdclock

## Author

Carlos Corral - Pulse Active
