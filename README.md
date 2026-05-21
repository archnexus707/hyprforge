# hyprforge

**by archnexus707**

archnexus707's dual desktop-ricing monorepo. Two sibling installers, one brand — pick the one that matches your hardware:

- **[`Kali-Hyprland/`](Kali-Hyprland/)** — Wayland (Hyprland) for **bare-metal** Kali with a working GPU. Full Hyprland session: hyprlock, ags, blur, animations, swaylock-style power menu.
- **[`D_WM-XFCE/`](D_WM-XFCE/)** — X11 (i3-gaps inside XFCE) for Kali running in **VMware / VirtualBox**. The Hyprland aesthetic without the Wayland fragility on `vmwgfx`.

Both ship the same **archnexus-\*** helper suite (audio, brightness, bluetooth, clipboard, OCR, power menu, screenshot, screen recording, theme picker, wifi, …), the same neon-mint `#00ff9c` brand, and the same `Super+H` / `Super+slash` help dialog. Muscle memory transfers between stacks.

## Quick start

```bash
# Pick the one that matches your target.

# Bare-metal Kali with a real GPU → Hyprland (Wayland):
cd Kali-Hyprland
cat README.md       # then ./install.sh --help

# Kali in VMware / VirtualBox → XFCE + i3-gaps (X11):
cd D_WM-XFCE
cat README.md       # then ./install.sh --dry-run
```

## When to use which

| | `Kali-Hyprland/` | `D_WM-XFCE/` |
|---|---|---|
| **Target** | Bare-metal Kali with a working GPU | Kali in VMware / VirtualBox |
| **Display server** | Wayland (Hyprland compositor) | X11 (XFCE session + i3-gaps + picom-ftlabs) |
| **Look** | Real Hyprland: blur, animations, hyprlock, ags | Hyprland *aesthetic* via i3-gaps + picom-ftlabs |
| **GPU requirement** | OpenGL ≥ 3.3 (Intel / AMD / NVIDIA) | None — works on `vmwgfx` |
| **Risk profile** | Replaces session; can swap display manager | Adds an i3 layer to XFCE, leaves XFCE intact |

**Rule of thumb:** if `systemd-detect-virt` returns anything other than `none`, install **D_WM-XFCE**. Kali-Hyprland *does* include a VMware fallback (software rendering + safe-mode picom), but it's a fallback, not the primary use case.

## Repository layout

```
hyprforge/
├── Kali-Hyprland/      # Wayland fork (bare-metal target)
├── D_WM-XFCE/          # X11 rice (VM-safe target)
├── HELP_SETTINGS       # quick i3/D_WM keybind cheat-sheet
└── README.md           # this file
```

Each subproject is self-contained: own `install.sh`, `uninstall.sh`, `recovery.sh`, `doctor.sh`, `preset.sh`, dotfiles, themes, install-scripts.

## Shared helpers

Both subprojects symlink the same 20 `archnexus-*` utilities into `~/.local/bin/`:

| Helper | Purpose |
|---|---|
| `archnexus-audio` / `archnexus-volume` | pipewire / wpctl wrappers |
| `archnexus-brightness` | brightnessctl / light wrapper with OSD |
| `archnexus-bt` / `archnexus-wifi` | bluetoothctl / nmcli rofi pickers |
| `archnexus-cheatsheet` | rofi keybind cheat-sheet (auto-detects compositor + follows `source =` includes) |
| `archnexus-clip` | clipboard history (cliphist / greenclip) |
| `archnexus-display` | autorandr / wlr-randr helper |
| `archnexus-nightlight` | wlsunset / redshift toggle |
| `archnexus-notify-history` | dunst history viewer |
| `archnexus-ocr` | region OCR via tesseract |
| `archnexus-power` | rofi power menu (lock / suspend / logout / reboot) |
| `archnexus-recovery` | wrapper around the project's `recovery.sh` |
| `archnexus-screenrecord` | wf-recorder / ffmpeg screen recorder |
| `archnexus-shot` | grim+slurp / maim / flameshot screenshot |
| `archnexus-sync` | dotfile sync with optional age encryption |
| `archnexus-theme` | hot-swap GTK + icon + cursor + kitty + rofi + dunst + Hyprland/i3 |
| `archnexus-watch` | dotfile live-reload via inotify |
| `archnexus-welcome` | first-login tour |
| `archnexus-automount` | udiskie wrapper |

Every helper runs a graphical-session preflight (stderr + notify-send) and points missing-deps errors at the project's `install-scripts/optional-deps.sh`.

## Environment requirements

| Layer | Required |
|---|---|
| **OS** | Kali Linux (rolling). Pure Debian works but is not the supported target — see [`Kali-Hyprland/KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md). |
| **Disk (Hyprland subproject)** | ≥ 5 GB free under `~/` — Hyprland is built from source. |
| **Session at install time** | TTY recommended (`Ctrl+Alt+F3`). Both installers can run inside an active X session but the display-manager swap and dotfile copies are safest from outside one. |
| **Session for helpers (post-install)** | Wayland (Hyprland) for `Kali-Hyprland` — degrades gracefully to X11 fallback paths inside `archnexus-shot`, `archnexus-ocr`, etc. X11 (XFCE / i3) for `D_WM-XFCE`. |

## Special thanks

Special thanks from **archnexus707** to [JaKooLit](https://github.com/JaKooLit) — his Debian-Hyprland project laid the early foundation that this Kali-targeted build was inspired by. The Hyprland community wouldn't be what it is without his work.

## License

GPL-3.0. See [`Kali-Hyprland/LICENSE.md`](Kali-Hyprland/LICENSE.md) and [`D_WM-XFCE/LICENSE`](D_WM-XFCE/LICENSE).
