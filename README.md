# omarchy-sysmon

A small system monitor for the Omarchy bar. It shows CPU %, memory % and
network speed in Mbps.

```text
󰻠 7%  󰍛 38%  ↓148.3 Mbps ↑12.1 Mbps
```

It is one QML file. Every 2 seconds it reads `/proc/stat`, `/proc/meminfo`
and `/proc/net/dev` and does the math. It does not start any process or
write any file. It uses about 3 ms of CPU per update.

The first update shows `--` for CPU. It needs two samples to work out a
percentage.

Left-click opens `btop`.

## What it will not do

This plugin stays small on purpose. It will not get:

- graphs or history
- popup windows or a process list
- GPU, temperature, disk, load or uptime
- colour thresholds or per-metric switches
- helper scripts or a background process

If you want those, other system monitors in the Omarchy plugin directory
have them.

## Install

```bash
omarchy plugin add https://github.com/aganet/omarchy-sysmon.git --enable
```

Update:

```bash
omarchy plugin update anegio.sysmon
```

Remove:

```bash
omarchy plugin remove anegio.sysmon
```

## Settings

| Key | Default | What it does |
| --- | --- | --- |
| `interval` | `2` | Seconds between updates (1–60) |
| `onClick` | `omarchy-launch-or-focus-tui btop` | Command to run on left-click |

Change them like this:

```bash
omarchy bar set anegio.sysmon interval 5
omarchy bar move anegio.sysmon --section left
```

## License

MIT
