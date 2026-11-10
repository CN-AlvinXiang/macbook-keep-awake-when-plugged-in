# macbook-keep-awake-when-plugged-in

[中文](README.md) | **English**

**Keep a MacBook awake with the lid closed while plugged in; let it sleep normally on battery.** A one-command macOS installer.

Useful when you use a MacBook like a small server: plugged in with the lid closed, you still want remote access (SSH, long-running jobs, downloads), but on battery you want it to sleep to save power.

> **Laptops only.** Mac mini, iMac and other desktops have no lid or battery.
> On those, just turn on "Prevent automatic sleeping when the display is off" in
> System Settings → Energy. You don't need this tool.

## Why you need it

- The System Settings option "Prevent automatic sleeping on power adapter when the display is off" only covers **idle / display-off**. It does **not** cover closing the lid, so the Mac still sleeps.
- `sudo pmset -a disablesleep 1` keeps the Mac awake with the lid closed, but it is a **global switch that ignores the power source**. If you forget to turn it off, a closed MacBook on battery stays awake, runs hot and drains the battery.
- This tool installs a root launchd daemon that checks the power source every 10 seconds and switches automatically:

| Power source | `disablesleep` | Lid closed |
| --- | --- | --- |
| AC adapter | 1 | Stays awake |
| Battery | 0 | Sleeps normally |

## Usage

Administrator rights are required; you will be asked for your sudo password.

```bash
bash lid-awake-on-ac.sh install     # install and take effect immediately
bash lid-awake-on-ac.sh status      # show current state (no sudo needed)
bash lid-awake-on-ac.sh uninstall   # remove and restore system defaults
```

Example `status` output (the tool's messages are currently in Chinese):

```
供电：Now drawing from 'AC Power'
SleepDisabled：1  （1=合盖不睡，0=正常睡眠）
守护任务：已安装
```

That is: power source, `SleepDisabled` (1 = stay awake with lid closed, 0 = sleep normally), and daemon installed.

## What it changes

- `/usr/local/bin/lid-awake-on-ac-worker.sh`: the small script that toggles the switch based on the power source
- `/Library/LaunchDaemons/com.local.lid-awake-on-ac.plist`: the daemon that runs it every 10 seconds
- The `disablesleep` value in the system power settings

`uninstall` deletes the two files above and sets `disablesleep` back to 0.

## Notes

- A MacBook running with the lid closed gets warm. **Don't put it in a bag or under a blanket.**
- After unplugging, it can take up to 10 seconds before sleep is restored; the Mac won't sleep during that window even with the lid closed.
- With the lid closed, screen sharing may show no picture or an odd resolution. SSH and other command-line access are unaffected.
- Running `install` again is safe: it removes the old daemon first.

## Verified / not verified

- Verified (macOS 26, Apple Silicon): `SleepDisabled` is 1 on AC power and returns to 0 after unplugging.
- Not verified: how long the network stays reachable with the lid closed, and other macOS versions.

## Requirements

macOS with the built-in `pmset` and `launchctl`. No other dependencies.
