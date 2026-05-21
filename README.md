<div align="center">

```
 █████╗ ██████╗  ██████╗██╗  ██╗███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
                    ███████╗ ██████╗ ███████╗
                    ╚════██║██╔═████╗╚════██║
                        ██╔╝██║██╔██║    ██╔╝
                       ██╔╝ ████╔╝██║   ██╔╝
                       ██║  ╚██████╔╝   ██║
                       ╚═╝   ╚═════╝    ╚═╝
```

# `hyprforge`

### **Forged by [archnexus707](https://github.com/archnexus707) — for the rebels of the terminal**

*A dual desktop-ricing monorepo for Kali Linux. Hyprland on bare metal, XFCE in VMware — same brand, same helpers, one neon-mint heartbeat.*

<br/>

![License](https://img.shields.io/badge/license-GPL--3.0-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Distro](https://img.shields.io/badge/distro-Kali_rolling-00ff9c?style=for-the-badge&labelColor=0a0a0a&logo=kalilinux&logoColor=00ff9c)
![Compositor](https://img.shields.io/badge/wayland-Hyprland-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Fallback](https://img.shields.io/badge/x11-i3--gaps_%2B_picom--ftlabs-00ff9c?style=for-the-badge&labelColor=0a0a0a)

![Accent](https://img.shields.io/badge/accent-%2300ff9c-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Helpers](https://img.shields.io/badge/archnexus--*-20_helpers-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Safety](https://img.shields.io/badge/install-dry--run_%2B_rollback-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Auth](https://img.shields.io/badge/audit-bash--n_clean-00ff9c?style=for-the-badge&labelColor=0a0a0a)

<br/>

[**▸ Kali-Hyprland**](Kali-Hyprland/) &nbsp;·&nbsp; [**▸ D_WM-XFCE**](D_WM-XFCE/) &nbsp;·&nbsp; [**▸ Helpers**](#-shared-archnexus-helper-suite) &nbsp;·&nbsp; [**▸ Quick start**](#-quick-start) &nbsp;·&nbsp; [**▸ FAQ**](#-faq)

</div>

---

## ◆ Two stacks, one brand

```
   ┌─────────────────────────────┐    ┌─────────────────────────────┐
   │      Kali-Hyprland/         │    │       D_WM-XFCE/            │
   │  ─────────────────────────  │    │  ─────────────────────────  │
   │   Wayland · Hyprland        │    │   X11 · i3-gaps · XFCE      │
   │   bare-metal + GPU          │    │   VMware / VirtualBox       │
   │   hyprlock · ags · blur     │    │   picom-ftlabs · blur       │
   │   built from source         │    │   apt-installable            │
   └──────────────┬──────────────┘    └──────────────┬──────────────┘
                  │                                  │
                  └───────── shared brand ───────────┘
                              archnexus707
                            accent #00ff9c
                          20 archnexus-* tools
                       same keybinds, same dialog
```

Both ship the same **archnexus-\*** helper suite, the same neon-mint `#00ff9c` brand, the same `Super+H` / `Super+slash` help dialog. Muscle memory transfers between stacks — pick the one that matches your hardware and the rest feels identical.

---

## ▸ Quick start

```bash
git clone https://github.com/archnexus707/hyprforge.git ~/hyprforge
cd ~/hyprforge

# Pick the one that matches your target hardware.

# ▸ Bare-metal Kali with a real GPU → Hyprland (Wayland)
cd Kali-Hyprland
cat README.md                 # then ./install.sh --help

# ▸ Kali in VMware / VirtualBox → XFCE + i3-gaps (X11)
cd ../D_WM-XFCE
cat README.md                 # then ./install.sh --dry-run
```

> **▲ heads-up** — both installers default to **safe mode**: `--dry-run`, manifest-backed rollback, opt-in display-manager swap. Read `preset.sh` once, snapshot your VM, then run for real.

---

## ◆ Which stack do I want?

<table>
<tr><th></th><th align="left"><code>Kali-Hyprland/</code></th><th align="left"><code>D_WM-XFCE/</code></th></tr>
<tr><td><b>Target</b></td><td>Bare-metal Kali with working GPU</td><td>Kali in VMware / VirtualBox / KVM</td></tr>
<tr><td><b>Display server</b></td><td>Wayland (Hyprland compositor)</td><td>X11 (XFCE session + i3-gaps + picom)</td></tr>
<tr><td><b>Aesthetic</b></td><td>Real Hyprland: blur, animations, hyprlock, ags</td><td>Hyprland <em>vibe</em> via i3-gaps + picom-ftlabs</td></tr>
<tr><td><b>GPU requirement</b></td><td>OpenGL ≥ 3.3 (Intel / AMD / NVIDIA)</td><td>None — works on <code>vmwgfx</code></td></tr>
<tr><td><b>Risk profile</b></td><td>Replaces session; can swap display manager</td><td>Adds an i3 layer to XFCE, leaves XFCE intact</td></tr>
<tr><td><b>Build</b></td><td>Hyprland from source (~5 GB)</td><td>picom-ftlabs from source, rest apt</td></tr>
<tr><td><b>Recover from</b></td><td>Log out → pick another session at greeter</td><td>Log out → pick <em>Xfce Session</em></td></tr>
</table>

> **Rule of thumb:** if `systemd-detect-virt` returns anything other than `none`, install **D_WM-XFCE**. The Hyprland fork includes a VMware fallback (software-rendered, blur-off picom), but it's a backup plan, not the goal.

---

## ▸ Shared archnexus-* helper suite

Both subprojects symlink the same **20 operator-grade CLI helpers** into `~/.local/bin/`. Each verifies its runtime env (stderr + `notify-send`) and points missing-deps errors at `install-scripts/optional-deps.sh`.

<table>
<tr>
<td valign="top">

**◆ Hardware controls**
- `archnexus-audio` · sink/source picker (wpctl)
- `archnexus-volume` · OSD volume + mute
- `archnexus-brightness` · brightnessctl/light wrapper
- `archnexus-bt` · bluetoothctl rofi picker
- `archnexus-wifi` · nmcli rofi picker
- `archnexus-display` · autorandr / wlr-randr
- `archnexus-nightlight` · wlsunset / redshift

</td>
<td valign="top">

**◆ Capture & paste**
- `archnexus-shot` · grim+slurp / flameshot / maim
- `archnexus-screenrecord` · wf-recorder / ffmpeg
- `archnexus-ocr` · region OCR via tesseract
- `archnexus-clip` · cliphist / greenclip
- `archnexus-notify-history` · dunst history

</td>
</tr>
<tr>
<td valign="top">

**◆ Session**
- `archnexus-power` · rofi power menu
- `archnexus-cheatsheet` · live keybinds (Hypr/i3, recursive `source =`)
- `archnexus-welcome` · first-login tour
- `archnexus-theme` · hot-swap GTK/icon/kitty/rofi/dunst/Hypr/i3
- `archnexus-automount` · udiskie wrapper

</td>
<td valign="top">

**◆ Ops**
- `archnexus-recovery` · wrapper for `recovery.sh`
- `archnexus-sync` · dotfile sync (+ age encryption)
- `archnexus-watch` · live-reload dotfiles via inotify

</td>
</tr>
</table>

> **`Super+H`** or **`Super+/`** brings up the live keybind dialog (`archnexus-cheatsheet`) — same as JaKooLit's convention. Memorise that one, you'll find the rest.

---

## ◆ Repository layout

```
hyprforge/
├── Kali-Hyprland/      ◆ Wayland (Hyprland) — bare-metal target
│   ├── install.sh           — phased installer
│   ├── install-scripts/     — per-phase shell modules
│   │   ├── archnexus-keybinds.sh   — wires Super+X/W/A/… into Hyprland
│   │   ├── cli-tools.sh            — symlinks 20 helpers into ~/.local/bin
│   │   ├── optional-deps.sh        — apt deps grouped by helper
│   │   ├── polish-archnexus.sh     — palette regen + wlogout power menu
│   │   ├── vmware.sh               — guest-aware Hyprland drop-in (fallback)
│   │   └── bin/                    — 20 archnexus-* helpers
│   ├── doctor.sh            — post-install self-diagnostic
│   ├── recovery.sh          — restore backed-up configs
│   ├── update-hyprland.sh   — per-component rebuild
│   ├── KALI-CHANGES.md      — line-by-line delta from upstream baseline
│   └── README.md            — fork-specific docs
│
├── D_WM-XFCE/          ◆ X11 (i3-gaps + XFCE) — VM-safe target
│   ├── install.sh           — phased installer w/ safety chassis
│   ├── install-scripts/
│   │   ├── lib/safety.sh           — manifest-driven rollback
│   │   ├── i3-gaps.sh / picom-ftlabs.sh / xfce-tweaks.sh
│   │   ├── kitty-zsh.sh / fonts.sh / themes.sh
│   │   └── bin/                    — same 20 archnexus-* helpers
│   ├── dotfiles/            — i3, kitty, picom, rofi, dunst, zsh configs
│   ├── themes/              — Catppuccin / Tokyo Night / Cyberpunk Edgerunners
│   ├── doctor.sh / recovery.sh / uninstall.sh
│   └── README.md            — XFCE-specific docs
│
├── HELP_SETTINGS       ◆ quick i3/D_WM keybind cheat-sheet (plain text)
├── README.md           ◆ this file
└── .gitignore
```

---

## ▸ Environment requirements

<details>
<summary><b>◆ Click to expand the install-time matrix</b></summary>

| Layer | Required | Why |
|---|---|---|
| **OS** | Kali Linux (rolling) | Both installers' `apt`-source guards and trixie shims target `ID=kali`. Pure Debian works but is **not** the supported target. |
| **Disk (Hyprland)** | ≥ 5 GB free under `~/` | Hyprland is built from source. The XFCE side is much lighter (~1 GB). |
| **Session at install time** | TTY recommended (`Ctrl+Alt+F3`) | The display-manager swap and dotfile copies are safest from outside an active X/Wayland session. |
| **Session for helpers (post-install)** | Wayland for `Kali-Hyprland`, X11 for `D_WM-XFCE` | Helpers detect `WAYLAND_DISPLAY` / `DISPLAY` and pick the right backend (`grim`+`slurp` vs `flameshot`/`maim`, `wl-copy` vs `xclip`, …). |
| **Architecture** | x86_64 only (so far) | Hyprland builds and `vmwgfx` driver path are x86-only. |

</details>

<details>
<summary><b>◆ What the tools verify themselves</b></summary>

Every helper that needs a graphical session runs a preflight check. From a TTY without `$DISPLAY` / `$WAYLAND_DISPLAY`:

```
archnexus-shot: archnexus-shot needs a graphical session (DISPLAY or
WAYLAND_DISPLAY). Run from inside Hyprland, an i3 session, or XFCE.
```

Missing deps point back at the installer instead of a bare `apt` hint:

```
archnexus-ocr: tesseract-ocr missing — install via
./install-scripts/optional-deps.sh (group: OCR)
```

`./doctor.sh` (both subprojects) verifies every helper is on `$PATH`, smoke-tests `archnexus-cheatsheet --raw`, and on the Hyprland side checks the keybind drop-in is wired into `UserSettings.conf`.

</details>

---

## ◆ Safety design

Both subprojects share the same first principles:

- **`--dry-run` everywhere** — preview every `apt --simulate`, every file-write, every systemctl change before anything actually happens.
- **Manifest-backed rollback** — every change is logged to a per-session manifest (`~/.dwm-backup/<ts>/manifest.sh` for XFCE, `Install-Logs/install-<ts>.log` for Hyprland). One command undoes everything.
- **Display manager is sacred** — LightDM is `systemctl disable`d, never `apt purge`d. Recovery from a black screen: drop to a TTY, `sudo systemctl enable --now lightdm`, log back into XFCE.
- **NVIDIA build is VM-aware** — `nvidia.sh` early-exits inside a VM (override with `FORCE_NVIDIA_IN_VM=1`). No more dead kernel modules in vmwgfx guests.
- **Apt sources untouched on Kali** — the upstream's apt-source rewriter early-returns when `ID=kali`. Your `non-free` + `non-free-firmware` lines stay intact.

---

## ▸ FAQ

<details>
<summary><b>◇ Is this a fork of JaKooLit's Debian-Hyprland?</b></summary>

The `Kali-Hyprland/` subproject started as one. Every functional delta from the inherited baseline is documented in [`Kali-Hyprland/KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md). The `D_WM-XFCE/` subproject is original; it only borrows the install-script *pacing pattern*.

</details>

<details>
<summary><b>◇ Can I run Kali-Hyprland in a VM?</b></summary>

You can — `install-scripts/vmware.sh` detects the guest, probes for hardware OpenGL, and writes a software-rendering fallback drop-in if GL is `llvmpipe`. But Hyprland on `vmwgfx` is fragile. **Install `D_WM-XFCE` instead** unless you have a specific reason.

</details>

<details>
<summary><b>◇ Why two READMEs (this one + Kali-Hyprland/README.md + D_WM-XFCE/README.md)?</b></summary>

This is the umbrella. Each subproject has its own README with phase names, recovery flow, keybind reference, env requirements specific to that stack. They are siblings and assume you cloned the whole monorepo.

</details>

<details>
<summary><b>◇ How do I update?</b></summary>

```bash
cd ~/hyprforge && git pull
cd Kali-Hyprland && ./update-hyprland.sh   # per-component rebuild
# or for the XFCE side, just re-run ./install.sh — it's idempotent.
```

</details>

<details>
<summary><b>◇ I want to add my own keybinds without losing them on update.</b></summary>

**Hyprland side:** write `~/.config/hypr/UserConfigs/UserKeybinds.conf` (or anything else under `UserConfigs/`). Our drop-in (`archnexus-keybinds.conf`) is sourced **after** `UserKeybinds.conf` for collision resolution, but anything you add to `UserKeybinds.conf` that doesn't collide stays.

**XFCE / i3 side:** dotfiles are deployed once. Edit `~/.config/i3/config` directly — re-running the installer backs up and overwrites, but you can also `--skip dotfiles` to keep your edits.

</details>

---

## ◆ Special thanks

Heartfelt thanks to **[JaKooLit](https://github.com/JaKooLit)** — his Debian-Hyprland project laid the early foundation that the Kali-Hyprland subproject was inspired by. The Hyprland community wouldn't be what it is without his work.

Hyprland itself: [hyprwm](https://github.com/hyprwm). Theme palettes: [Tokyo Night](https://github.com/folke/tokyonight.nvim), [Catppuccin](https://github.com/catppuccin/catppuccin), and Cyberpunk: Edgerunners (Studio Trigger / CD Projekt Red).

---

<div align="center">

`forged by archnexus707 · for the rebels of the terminal`

**◆ ◆ ◆**

[**▸ Star**](https://github.com/archnexus707/hyprforge/stargazers) &nbsp;·&nbsp; [**▸ Fork**](https://github.com/archnexus707/hyprforge/fork) &nbsp;·&nbsp; [**▸ Issues**](https://github.com/archnexus707/hyprforge/issues) &nbsp;·&nbsp; [**▸ Discussions**](https://github.com/archnexus707/hyprforge/discussions)

**GPL-3.0** · See `Kali-Hyprland/LICENSE.md` and `D_WM-XFCE/LICENSE`

</div>
