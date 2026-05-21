# D_WM-XFCE

**by archnexus707**

Hyprland-style ricing for **XFCE on Kali Linux**, designed to run smoothly inside **VMware** (or any virtualised guest).

This is a curated install profile, not a window manager from scratch. The look and feel are achieved by:

- replacing XFCE's stock window manager with **i3-gaps** inside the XFCE session (tiling + gaps + Hyprland-like keybinds)
- adding **picom-ftlabs** as the compositor (window animations, dual-kawase blur, rounded corners, fades)
- a **three-theme switcher**: Cyberpunk Edgerunners, Tokyo Night Storm, Catppuccin Mocha
- kitty + zsh + oh-my-zsh + powerlevel10k + fastfetch + pokemon-colorscripts
- Nerd fonts (JetBrains Mono, Maple Mono, Iosevka)
- rofi launcher, dunst notifications, themed XFCE panel or polybar
- animated anime wallpapers via xwinwrap + mpv

## When to use this vs Kali-Hyprland

| | D_WM-XFCE (this repo) | [Kali-Hyprland](../Kali-Hyprland/) |
|---|---|---|
| **Target** | Kali in VMware / VirtualBox | Bare-metal Kali with a working GPU |
| **Display server** | X11 (rock-solid in VMs) | Wayland (Hyprland) |
| **GPU requirement** | None — works on `vmwgfx` | Working OpenGL ≥ 3.3 |
| **Risk profile** | Adds an i3 layer to XFCE, leaves XFCE intact | Replaces the session entirely |

**Why XFCE, not Hyprland, in a VM?** Hyprland is Wayland and needs working GPU acceleration. Inside VMware the `vmwgfx` driver has patchy Wayland/OpenGL support, and Hyprland often crashes or falls back to software rendering. XFCE + picom is **X11**, which VMware has supported flawlessly for 15+ years. You get most of the Hyprland aesthetic with none of the VM instability.

## Quick start

```bash
cd ~/Desktop/D_WM/D_WM-XFCE

# 1. Preview every action without changing anything
./install.sh --dry-run

# 2. Read the dry-run output. If it looks right:
./install.sh

# 3. Verify
./doctor.sh

# 4. Something broke?
./uninstall.sh --latest
```

## Flags

```
--dry-run       Preview every change. Recommended for first run.
--force         Skip confirmations. Only use after a clean --dry-run.
--preset FILE   Use a different preset file (default: ./preset.sh).
--only PHASE    Run a single phase. Useful for iterating.
--skip PHASES   Comma-separated phases to skip.
--resume TS     Continue an interrupted session by its backup timestamp.
```

Phase names: `00-deps`, `pre-clean`, `vmware`, `i3`, `picom`, `xfce`, `kitty-zsh`, `fonts`, `themes`, `dotfiles`, `polish`, `final`.

## Safety design

The installer is built so it can be **reversed without reinstalling Kali**:

| Promise | Mechanism |
|---|---|
| Nothing modifies the system without your confirmation | `safety_banner` + `safety_preflight` + `confirm()` prompts |
| Every modified file is backed up before being touched | `backup_file` / `backup_dir` → `~/.dwm-backup/<timestamp>/` |
| Every apt install/remove and systemctl change is recorded | Manifest at `~/.dwm-backup/<timestamp>/manifest.sh` |
| Full rollback in one command | `./uninstall.sh <timestamp>` replays the manifest in reverse |
| Run from a TTY recommended, never required | Banner warns if `$DISPLAY` is set; install proceeds with confirmation |
| Kernel modules are **not** built unless you explicitly opt in | `nvidia.sh` is bare-metal only and disabled by default |
| Display manager swap is opt-in only | `sddm_swap="OFF"` by default in `preset.sh` |
| Always preview before acting | `--dry-run` runs `apt --simulate` and prints every file write |

## Environment requirements

Before you run `./install.sh`, this is what the project assumes:

| Layer | Required | Why |
|---|---|---|
| **Hardware / hypervisor** | Kali running in a virtualised guest (VMware / VirtualBox / KVM) **or** bare metal — both work | X11 + picom on `vmwgfx` is rock-solid; bare metal works too but if you have a real GPU you may prefer **Kali-Hyprland**. |
| **OS** | Kali Linux (rolling) with XFCE | The installer assumes Kali's package names and XFCE's default panel/keybind layout. Other Debian-family XFCE installs likely work but are not tested. |
| **Session at install time** | Active XFCE session is fine | The installer never swaps the display manager by default (`sddm_swap="OFF"`), so running from inside your live XFCE session is safe. |
| **After install: session for helpers** | X11 (XFCE / i3 inside XFCE) | The `archnexus-*` helpers detect `DISPLAY` and pick `flameshot`/`maim`/`xclip`/`xfconf-query` etc. Wayland fallbacks exist but aren't the target. |

The tools themselves verify their runtime env and print actionable errors. For example, running `archnexus-shot` from a TTY:

```
archnexus-shot: needs a graphical session (DISPLAY or WAYLAND_DISPLAY).
Run from inside Hyprland, an i3 session, or XFCE.
```

…and missing dependencies always point back to `./install-scripts/optional-deps.sh`:

```
archnexus-ocr: tesseract-ocr missing — install via ./install-scripts/optional-deps.sh (group: OCR)
```

If something doesn't behave, run `./doctor.sh` — it checks every helper is on `$PATH` and smoke-tests `archnexus-cheatsheet --raw`.

## Recovery

If i3 or picom is misbehaving after install:

1. Log out, pick **Xfce Session** (not the i3 one) from the LightDM menu — you're back where you started.
2. From a TTY (`Ctrl+Alt+F3`), run `./recovery.sh` to restore backed-up dotfiles.
3. Full rollback: `./uninstall.sh --latest`.

The installer **never** disables LightDM by default (`sddm_swap="OFF"` in `preset.sh`), so the greeter you log in with is the same one you booted into Kali with.

## Keybinds

See [`../HELP_SETTINGS`](../HELP_SETTINGS) for the i3 cheat-sheet. Highlights:

- `SUPER+Enter` — kitty
- `SUPER+R` — rofi launcher
- `SUPER+Tab` — window switcher
- `SUPER+Q` — close window
- `SUPER+SHIFT+T` — theme picker
- `SUPER+SHIFT+E` — power menu (logout / lock / reboot)
- `SUPER+1..9` — workspace switch

## What's intentionally **not** shipped

- **No wallpaper image** — `~/.config/i3/wallpaper.sh` falls back to a solid color. Drop a `wallpaper.png` into `~/.config/i3/` to enable.
- **p10k not pre-configured** — first interactive zsh launch runs `p10k configure` (~2 min of prompts).
- **No animated wallpapers** by default — `xwinwrap` + `mpv` integration is a future polish task.
- **xfce4-panel stays default-looking** — custom panel XML / polybar is left to the user.

## Repository layout

```
D_WM-XFCE/
├── install.sh                 # entry point (parses flags, dispatches phases)
├── uninstall.sh               # rolls back a session via its manifest
├── recovery.sh                # restore backed-up dotfiles
├── doctor.sh                  # post-install self-diagnostic
├── preset.sh                  # ON/OFF toggles for each phase
├── README.md
├── LICENSE                    # GPL-3.0
├── install-scripts/
│   ├── lib/
│   │   ├── safety.sh          # logging, backups, apt wrappers, preflight
│   │   └── archnexus_banner.sh
│   ├── 00-dependencies.sh
│   ├── 02-pre-cleanup.sh
│   ├── 03-final-check.sh
│   ├── vmware.sh
│   ├── i3-gaps.sh
│   ├── picom-ftlabs.sh
│   ├── xfce-tweaks.sh
│   ├── kitty-zsh.sh
│   ├── fonts.sh
│   ├── themes.sh
│   ├── dotfiles.sh
│   ├── polish-archnexus.sh    # dwm-palette + dwm-powermenu
│   ├── optional-deps.sh       # apt packages for archnexus-* helpers
│   ├── bin/                   # archnexus-* user-facing helpers (19 tools)
│   ├── themes/                # three-theme switcher payloads
│   ├── systemd/               # display-hotplug + watch units
│   └── hooks/                 # post-install hook scripts
├── dotfiles/                  # configs deployed to ~/.config/ on install
│   ├── kitty/
│   ├── i3/
│   ├── picom/
│   ├── rofi/
│   ├── dunst/
│   └── zsh/
├── themes/                    # three-theme switcher source palettes
│   ├── cyberpunk-edgerunners/
│   ├── tokyo-night-storm/
│   └── catppuccin-mocha/
├── assets/                    # wallpapers, icons we ship
└── Install-Logs/              # timestamped log per install run
```

## Special thanks

Special thanks from **archnexus707** to [JaKooLit](https://github.com/JaKooLit) — his Debian-Hyprland work was an early reference for the install-script pacing this project follows. The Hyprland community is better for it.

Theme palettes referenced by the three-theme switcher: Cyberpunk: Edgerunners, [Tokyo Night](https://github.com/folke/tokyonight.nvim), and [Catppuccin](https://github.com/catppuccin/catppuccin).

## License

GPL-3.0. See `LICENSE`.
