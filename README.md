# rega.screentime — Screen Time for Omarchy

Native screen-time tracker + beautiful bar widget for [Omarchy](https://omarchy.org/) (Hyprland).
ARM-friendly: no ActivityWatch needed (`activitywatch-bin` is x86_64-only).

![bar](https://img.shields.io/badge/bar-◷_today-blue) ![popup](https://img.shields.io/badge/popup-week+top_apps-green)

## What it does

* **Bar:** `◷ 3h12m` — today unlocked screen time
* **Popup:** today hero, last-7-days bars, top apps with bars, top browser tab titles
* **Tracking:** samples Hyprland active window every 15s, skips while `hyprlock` runs
* **Data:** `~/.local/share/omarchy/screentime/days/YYYY-MM-DD.json` (local only)

## Install

```bash
omarchy plugin add https://github.com/Chandraprakash-Darji/rega.screentime --enable
omarchy bar put rega.screentime --after omarchy.clock
```

Or clone manually into `~/.config/omarchy/plugins/rega.screentime` then enable.

## CLI

```bash
~/.config/omarchy/plugins/rega.screentime/bin/screentime status
~/.config/omarchy/plugins/rega.screentime/bin/screentime status --json
~/.config/omarchy/plugins/rega.screentime/bin/screentime week
```

* Right-click bar widget = terminal summary
* Left-click = popup breakdown

## Browser tabs / URLs

Shows tab **titles** (e.g. `GitHub - Chromium`). Per-URL history needs
ActivityWatch `aw-watcher-web` extension, which requires x86 — not available
on ARM Macs, so titles are the best native option.

## Files

```
manifest.json          # omarchy plugin manifest (bar-widget)
Panel.qml              # bar button + popup
Model.js               # JSON parsing / formatting helpers
bin/screentime         # tracker CLI (tick / status / week)
```

## License

MIT
