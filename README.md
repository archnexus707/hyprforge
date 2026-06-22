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

*A dual desktop-ricing monorepo for Kali Linux. Hyprland on bare metal, i3wm+XFCE in VMs — same brand, one neon heartbeat.*

<br/>

![License](https://img.shields.io/badge/license-GPL--3.0-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Distro](https://img.shields.io/badge/distro-Kali_rolling-00ff9c?style=for-the-badge&labelColor=0a0a0a&logo=kalilinux&logoColor=00ff9c)
![Compositor](https://img.shields.io/badge/wayland-Hyprland-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Fallback](https://img.shields.io/badge/x11-i3wm_%2B_picom-00ff9c?style=for-the-badge&labelColor=0a0a0a)

![Accent](https://img.shields.io/badge/accent-%2300ff9c-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Safety](https://img.shields.io/badge/install-idempotent_%2B_.bak_rollback-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![Audit](https://img.shields.io/badge/audit-bash--n_clean-00ff9c?style=for-the-badge&labelColor=0a0a0a)
![VMware](https://img.shields.io/badge/vmware-safe_xrender_fallback-00ff9c?style=for-the-badge&labelColor=0a0a0a)

<br/>

[**▸ Kali-Hyprland**](Kali-Hyprland/) &nbsp;·&nbsp; [**▸ D_WM-XFCE**](D_WM-XFCE/) &nbsp;·&nbsp; [**▸ Quick start**](#-quick-start) &nbsp;·&nbsp; [**▸ FAQ**](#-faq)

</div>

---

## ◆ Two stacks, one brand

```
   ┌─────────────────────────────┐    ┌─────────────────────────────┐
   │      Kali-Hyprland/         │    │       D_WM-XFCE/            │
   │  ─────────────────────────  │    │  ─────────────────────────  │
   │   Wayland · Hyprland        │    │   X11 · i3wm · picom        │
   │   bare-metal + real GPU     │    │   VMware / VirtualBox safe  │
   │   hyprlock · ags · blur     │    │   apt-installable · lightweight │
   │   built from source (~5GB)  │    │   modular 8-phase installer │
   │   screenshots: grim+slurp   │    │   screenshots: maim+flameshot│
   └──────────────┬──────────────┘    └──────────────┬──────────────┘
                  │                                  │
                  └───────── shared brand ───────────┘
                              archnexus707
                            accent #00ff9c
                       same keybinds, same vibe
```

Both ship with the same neon `#00ff9c` brand identity, vim-style keybind conventions, cyberpunk terminal experience, and post-install diagnostic tooling. Muscle memory transfers between stacks — pick the one that matches your hardware.

---

## ▸ Quick start

```bash
git clone https://github.com/archnexus707/hyprforge.git ~/hyprforge
cd ~/hyprforge

# ▸ Bare-metal Kali with a real GPU → Hyprland (Wayland)
cd Kali-Hyprland
cat README.md
./install.sh

# ▸ Kali in VMware / VirtualBox → i3wm + XFCE (X11)
cd ../D_WM-XFCE
./setup.sh          # quick dependency bootstrap (optional)
./install.sh        # full cyberpunk rice
./doctor.sh         # post-install health check
./welcome.sh        # interactive tour
```

> **▲ heads-up** — Both installers are **idempotent** (safe to re-run). D_WM-XFCE adds an i3 session alongside your existing XFCE desktop — nothing is removed. Kali-Hyprland replaces your display manager and session configs (see its README for recovery steps).

---

## ◆ Which stack do I want?

<table>
<tr><th></th><th align="left"><code>Kali-Hyprland/</code></th><th align="left"><code>D_WM-XFCE/</code></th></tr>
<tr><td><b>Target</b></td><td>Bare-metal Kali with working GPU</td><td>Kali in VMware / VirtualBox / KVM</td></tr>
<tr><td><b>Display server</b></td><td>Wayland (Hyprland compositor)</td><td>X11 (i3wm session + picom compositor)</td></tr>
<tr><td><b>Aesthetic</b></td><td>Real Hyprland: blur, animations, hyprlock</td><td>Tokyo Night i3wm + picom blur + rofi + dunst</td></tr>
<tr><td><b>GPU requirement</b></td><td>OpenGL ≥ 3.3 (Intel / AMD / NVIDIA)</td><td>None — works on <code>vmwgfx</code></td></tr>
<tr><td><b>Risk profile</b></td><td>Replaces session; can swap display manager</td><td>Adds an i3 session entry — XFCE stays untouched</td></tr>
<tr><td><b>Build</b></td><td>Hyprland from source (~5 GB)</td><td>All apt packages except oh-my-zsh themes</td></tr>
<tr><td><b>Recover from</b></td><td>Log out → pick another session at greeter</td><td>Log out → pick <em>Xfce Session</em></td></tr>
<tr><td><b>Tools</b></td><td>doctor.sh, recovery.sh, update-hyprland.sh, uninstall.sh</td><td>doctor.sh, setup.sh, welcome.sh, spawn.sh</td></tr>
</table>

> **Rule of thumb:** if `systemd-detect-virt` returns anything other than `none`, install **D_WM-XFCE**. It auto-detects VMware and switches to a safe xrender compositor backend.

---

## ▸ D_WM-XFCE features

```bash
D_WM-XFCE/
├── install.sh              ● 8-phase modular installer (idempotent)
├── setup.sh                ● quick dependency bootstrapper  
├── doctor.sh               ● 21-check system health diagnostic
├── welcome.sh              ● post-install interactive cyberpunk tour
├── spawn.sh                ● session launcher with neon boot sequence
├── preset.sh               ● feature toggles (i3wm/picom/terminal/theme/dotfiles)
├── install-scripts/
│   ├── 00-deps.sh          ● apt package installation
│   ├── 01-i3.sh            ● i3 session registration (appears in greeter)
│   ├── 02-picom.sh         ● compositor config (auto-detects VMware → xrender)
│   ├── 03-terminal.sh      ● oh-my-zsh + powerlevel10k + plugins
│   ├── 04-theme.sh         ● Catppuccin GTK + Bibata cursor + xfconf
│   └── 05-dotfiles.sh      ● deploy all configs to ~/.config/
├── dotfiles/               ● i3 · kitty · rofi · picom · dunst · zsh
└── wallpaper/              ● cyberpunk.png (1920×1080)
```

### What gets installed

| Layer | Components |
|-------|-----------|
| **WM** | i3-wm + i3status + i3lock |
| **Compositor** | picom (GLX on bare metal, xrender in VMware) |
| **Terminal** | kitty (Tokyo Night palette, 92% opacity) |
| **Shell** | zsh + oh-my-zsh + powerlevel10k + plugins (autosuggestions, syntax-highlighting) |
| **Launcher** | rofi (cyberpunk themed, drun/window/run modes) |
| **Notifications** | dunst (3 urgency levels, neon frame) |
| **Theme** | Catppuccin-Mocha-Mauve GTK + Bibata-Modern-Ice cursor + Papirus icons |
| **CLI** | fastfetch, eza, bat, btop, maim, xclip, flameshot |
| **Wallpaper** | 1920×1080 cyberpunk PNG |

### Keybinds

| Binding | Action |
|---------|--------|
| `SUPER+Enter` | Terminal (kitty) |
| `SUPER+r` / `SUPER+d` | App launcher (rofi) |
| `SUPER+Tab` | Window switcher |
| `SUPER+q` | Close window |
| `SUPER+f` | Fullscreen toggle |
| `SUPER+space` | Float toggle |
| `SUPER+1..0` | Switch workspace |
| `SUPER+Shift+1..0` | Move window to workspace |
| `SUPER+h/j/k/l` | Vim-style focus |
| `SUPER+Shift+h/j/k/l` | Vim-style move |
| `SUPER+Shift+q` | Logout menu |
| `SUPER+Shift+c` | Reload i3 config |
| `SUPER+t` | Resize mode |
| `Print` | Screenshot (area → clipboard) |
| `SUPER+Print` | Screenshot (flameshot GUI) |

---

## ▸ Kali-Hyprland features

Full Wayland compositor stack compiled from source on Kali Linux. Fork of [JaKooLit's Debian-Hyprland](https://github.com/JaKooLit/Debian-Hyprland).

```bash
Kali-Hyprland/
├── install.sh              ● interactive phased installer
├── update-hyprland.sh      ● per-component rebuild tool
├── doctor.sh               ● post-install diagnostic
├── recovery.sh             ● TTY2 rescue menu
├── uninstall.sh            ● full removal
├── dry-run-build.sh        ● CI compile-only runner
├── preset.sh               ● feature selection
├── hypr-tags.env           ● version pins for all Hypr* packages
├── install-scripts/        ● 60+ build/install phase scripts
│   ├── hyprland.sh          ● Hyprland from source
│   ├── hyprlock.sh          ● screen locker
│   ├── hypridle.sh          ● idle daemon
│   ├── swww.sh              ● animated wallpapers
│   ├── wallust.sh           ● palette generator
│   ├── rofi-wayland.sh      ● Wayland-native launcher
│   ├── ags.sh               ● Aylur's GTK Shell (widgets)
│   ├── nvidia.sh            ● NVIDIA driver + CUDA
│   ├── vmware.sh            ● VM fallback drop-in
│   ├── zsh.sh               ● zsh + oh-my-zsh + p10k
│   ├── sddm.sh              ● SDDM display manager
│   └── ...                  ● and 45+ more
├── assets/                 ● fastfetch configs, fonts, GTK prefs, patches
├── dotfiles → Hyprland-Dots (auto-cloned)
└── KALI-CHANGES.md          ● line-by-line delta from upstream
```

> See [`Kali-Hyprland/README.md`](Kali-Hyprland/README.md) for full docs and [`KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md) for the complete fork delta.

---

## ◆ Repository layout

```
hyprforge/
├── Kali-Hyprland/      ◆ Wayland (Hyprland) — bare-metal target
│   ├── install.sh           ● phased build-from-source installer
│   ├── install-scripts/     ● 60+ per-package build scripts
│   ├── doctor.sh            ● post-install diagnostic
│   ├── recovery.sh          ● TTY rescue menu
│   ├── uninstall.sh         ● full system removal
│   ├── update-hyprland.sh   ● per-component rebuild
│   ├── hypr-tags.env        ● centralized version pins
│   ├── KALI-CHANGES.md      ● fork delta documentation
│   └── README.md            ● fork-specific docs
│
├── D_WM-XFCE/          ◆ X11 (i3wm + picom) — VM-safe target
│   ├── install.sh           ● 8-phase modular installer
│   ├── setup.sh             ● quick dependency bootstrap
│   ├── doctor.sh            ● 21-check system diagnostic
│   ├── welcome.sh           ● interactive cyberpunk tour
│   ├── spawn.sh             ● session launcher
│   ├── preset.sh            ● feature toggles
│   ├── install-scripts/     ● 00-deps.sh → 05-dotfiles.sh
│   ├── dotfiles/            ● i3, kitty, picom, rofi, dunst, zsh
│   └── wallpaper/           ● cyberpunk.png
│
├── HELP_SETTINGS       ◆ i3/D_WM keybind cheat-sheet
├── README.md           ◆ this file
└── .gitignore
```

---

## ◆ Safety design

### D_WM-XFCE
- **Idempotent** — safe to re-run; already-installed packages are skipped
- **VMware auto-detection** — switches picom to xrender backend automatically
- **`.bak` rollback** — existing configs get `.bak.<timestamp>` before overwrite
- **XFCE never touched** — adds an i3 session entry, leaves your XFCE desktop intact
- **Non-root** — installer refuses to run as root; uses `sudo` only where needed

### Kali-Hyprland
- **`--dry-run` everywhere** — preview every apt, file-write, and systemctl change
- **Manifest-backed rollback** — changes logged to `Install-Logs/install-<ts>.log`
- **Display manager is sacred** — LightDM is disabled, never purged
- **NVIDIA build is VM-aware** — skips kernel module build inside VMs
- **Apt sources untouched on Kali** — source rewriter early-returns when `ID=kali`

---

## ▸ FAQ

<details>
<summary><b>◇ Is this a fork of JaKooLit's Debian-Hyprland?</b></summary>

The `Kali-Hyprland/` subproject started as a fork. Every functional delta is documented in [`Kali-Hyprland/KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md). The `D_WM-XFCE/` subproject is entirely original work.

</details>

<details>
<summary><b>◇ Can I run Kali-Hyprland in a VM?</b></summary>

You can — `vmware.sh` detects the guest and writes a software-rendering fallback. But Hyprland on `vmwgfx` is fragile. **Install `D_WM-XFCE` instead** — it's designed for virtualized environments.

</details>

<details>
<summary><b>◇ What if picom doesn't start / I get a black screen in i3?</b></summary>

Check the VMware detection: `systemd-detect-virt`. If you're in VMware, run `./install-scripts/02-picom.sh` to redeploy the xrender config. Otherwise, verify picom is installed: `command -v picom`.

</details>

<details>
<summary><b>◇ How do I update?</b></summary>

```bash
cd ~/hyprforge && git pull
# D_WM-XFCE: re-run ./install.sh (idempotent — safe)
cd D_WM-XFCE && ./install.sh
# Kali-Hyprland: per-component rebuild
cd Kali-Hyprland && ./update-hyprland.sh
```

</details>

<details>
<summary><b>◇ I want to add my own keybinds without losing them on update.</b></summary>

**D_WM-XFCE:** Edit `~/.config/i3/config` directly. The installer creates a `.bak` backup before overwriting. Re-run install with `dotfiles="OFF"` in `preset.sh` to skip dotfile deployment.

**Kali-Hyprland:** Write your binds to `~/.config/hypr/UserConfigs/UserKeybinds.conf`. The archnexus keybind drop-in sources after it for collision resolution.

</details>

---

## ☕ Support

If hyprforge made your desktop glow, consider buying me a coffee:

[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-archnexus707@gmail.com-yellow?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](mailto:archnexus707@gmail.com)

---

## ◆ Special thanks

Heartfelt thanks to **[JaKooLit](https://github.com/JaKooLit)** — his Debian-Hyprland project laid the early foundation that the Kali-Hyprland subproject was inspired by. The Hyprland community wouldn't be what it is without his work.

Hyprland itself: [hyprwm](https://github.com/hyprwm). Theme palettes: [Tokyo Night](https://github.com/folke/tokyonight.nvim), [Catppuccin](https://github.com/catppuccin/catppuccin).

---

<div align="center">

`forged by archnexus707 · for the rebels of the terminal`

**◆ ◆ ◆**

[**▸ Star**](https://github.com/archnexus707/hyprforge/stargazers) &nbsp;·&nbsp; [**▸ Fork**](https://github.com/archnexus707/hyprforge/fork) &nbsp;·&nbsp; [**▸ Issues**](https://github.com/archnexus707/hyprforge/issues) &nbsp;·&nbsp; [**▸ Discussions**](https://github.com/archnexus707/hyprforge/discussions)

**GPL-3.0** · See `Kali-Hyprland/LICENSE.md`

</div>
