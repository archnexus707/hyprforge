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
![Audit](https://img.shields.io/badge/audit-31_bugs_fixed-00ff9c?style=for-the-badge&labelColor=0a0a0a)

<br/>

[**▸ Kali-Hyprland**](Kali-Hyprland/) &nbsp;·&nbsp; [**▸ D_WM-XFCE**](D_WM-XFCE/) &nbsp;·&nbsp; [**▸ Quick start**](#-quick-start) &nbsp;·&nbsp; [**▸ FAQ**](#-faq)

</div>

---

## ◆ Two stacks, one brand

```
   ┌───────────────────────────────┐    ┌──────────────────────────────┐
   │       Kali-Hyprland/          │    │        D_WM-XFCE/            │
   │  ──────────────────────────── │    │  ─────────────────────────── │
   │   Wayland · Hyprland          │    │   X11 · i3wm · picom         │
   │   bare-metal + real GPU       │    │   VMware / VirtualBox safe   │
   │   hyprlock · ags · blur       │    │   apt-installable · light    │
   │   built from source (~5GB)    │    │   modular 8-phase installer  │
   │   screenshots: grim+slurp     │    │   screenshots: maim+flameshot │
   │   60+ build scripts           │    │   6 phase-scripts + 6 tools   │
   └───────────────┬───────────────┘    └──────────────┬───────────────┘
                   │                                   │
                   └────────── shared brand ───────────┘
                                archnexus707
                              accent #00ff9c
                 cyberpunk neon · vim keybinds · interactive tours
                   doctor.sh diagnostics · idempotent installs
```

Both stacks share the same neon `#00ff9c` identity, vim-style keybind conventions, Tokyo Night + Catppuccin palettes, structured logging, and cyberpunk interactive welcome experiences. Muscle memory transfers — pick the stack that matches your hardware.

---

## ▸ Quick start

```bash
git clone https://github.com/archnexus707/hyprforge.git ~/hyprforge
cd ~/hyprforge

# ▸ Bare-metal Kali with a real GPU → Hyprland (Wayland)
cd Kali-Hyprland
./install.sh                  # interactive phased installer

# ▸ Kali in VMware / VirtualBox → i3wm + XFCE (X11)
cd ../D_WM-XFCE
./setup.sh                    # quick dependency bootstrap (optional)
./install.sh                  # 8-phase cyberpunk rice
./doctor.sh                   # 21-check system diagnostic
./welcome.sh                  # interactive neon tour
```

> **▲ heads-up** — Both installers are **idempotent** (safe to re-run). D_WM-XFCE adds an i3 session entry alongside your existing XFCE desktop — nothing is removed. Kali-Hyprland replaces your display manager and session configs (see its README for recovery).

---

## ◆ Which stack do I want?

| | **Kali-Hyprland/** | **D_WM-XFCE/** |
|---|---|---|
| **Target** | Bare-metal Kali with real GPU | Kali in VMware / VirtualBox / KVM |
| **Display** | Wayland (Hyprland) | X11 (i3wm + picom) |
| **Aesthetic** | Real Hyprland: blur, animations, hyprlock | Tokyo Night i3wm + picom blur + rofi + dunst |
| **GPU needed** | OpenGL ≥ 3.3 | None — works on `vmwgfx` |
| **Risk** | Replaces session + display manager | Adds i3 session — XFCE untouched |
| **Build** | From source (~5 GB) | All apt except oh-my-zsh |
| **Recovery** | Pick another session at greeter | Pick *Xfce Session* at greeter |
| **Tooling** | doctor.sh, recovery.sh, update-hyprland.sh, uninstall.sh | doctor.sh, setup.sh, welcome.sh, spawn.sh |

> **Rule of thumb:** if `systemd-detect-virt` returns anything other than `none`, install **D_WM-XFCE**. It auto-detects VMware and switches to a safe xrender compositor backend.

---

## ▸ D_WM-XFCE

### Tool belt

```bash
D_WM-XFCE/
├── install.sh           ● 8-phase modular installer (idempotent)
├── setup.sh             ● quick apt dependency bootstrap
├── doctor.sh            ● 21-check system health diagnostic
├── welcome.sh           ● post-install interactive cyberpunk tour
│                          (system scan, rice integrity, keybinds, pro tips)
├── spawn.sh             ● session launcher with neon boot sequence
│                          (auto-starts picom, dunst, nm-applet, polkit)
├── preset.sh            ● feature toggles
├── install-scripts/
│   ├── 00-deps.sh       ● apt package installation (idempotent)
│   ├── 01-i3.sh         ● greeter session registration
│   ├── 02-picom.sh      ● compositor (auto-detects VMware → xrender)
│   ├── 03-terminal.sh   ● oh-my-zsh + powerlevel10k + plugins
│   ├── 04-theme.sh      ● Catppuccin GTK + Bibata cursor + xfconf
│   └── 05-dotfiles.sh   ● deploy configs to ~/.config/
├── dotfiles/            ● i3 · kitty · picom · rofi · dunst · zsh
└── wallpaper/           ● cyberpunk.png (1920×1080)
```

### Install stack

| Layer | Components |
|-------|-----------|
| **WM** | i3-wm + i3status + i3lock |
| **Compositor** | picom (GLX bare metal / xrender VMware) |
| **Terminal** | kitty (Tokyo Night, 92% opacity, powerline tabs) |
| **Shell** | zsh + oh-my-zsh + powerlevel10k + plugins |
| **Launcher** | rofi (cyberpunk themed, 3 modes) |
| **Notifications** | dunst (3 urgency levels, neon frame) |
| **Theme** | Catppuccin-Mocha-Mauve GTK + Bibata-Modern-Ice cursor + Papirus icons |
| **CLI** | fastfetch · eza · bat · btop · maim · xclip · flameshot |
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
| `SUPER+Shift+q` | Logout menu (rofi) |
| `SUPER+Shift+c` | Reload i3 config |
| `SUPER+t` | Resize mode |
| `Print` | Screenshot area → clipboard |
| `SUPER+Print` | Screenshot (flameshot GUI) |

---

## ▸ Kali-Hyprland

Full Wayland compositor stack compiled from source on Kali Linux. Fork of [JaKooLit's Debian-Hyprland](https://github.com/JaKooLit/Debian-Hyprland). **31 bugs fixed** in latest audit (19 critical build/runtime bugs + 12 D_WM-XFCE bugs).

```bash
Kali-Hyprland/
├── install.sh              ● interactive phased installer
├── update-hyprland.sh      ● per-component rebuild
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
│   ├── sddm.sh              ● SDDM display manager
│   └── ...                  ● and 45+ more
├── assets/                 ● fastfetch configs, fonts, GTK prefs, patches
└── KALI-CHANGES.md          ● line-by-line delta from upstream
```

### Recent audit — 19 bugs fixed (ce4fd6a)

| Severity | Count | Key fix |
|----------|-------|---------|
| **CRITICAL** | 7 | `run_cmd()` broken in nvidia.sh (all CUDA/GRUB ops were no-ops), log collisions, cmake parallelism broken in 7 scripts, APT `.sources` format ignored, undefined variables, `re_install_package` failing on clean installs |
| **HIGH** | 6 | Relative paths breaking CI, double-nested font directories, `mv` breaking cargo tracking, fastfetch configs overwritten |
| **MEDIUM** | 6 | Unquoted `rm -rf`, 34 unnecessary sleeps in CI, `--help` broken, sudo keep-alive orphan, fragile distro detection |

> See [`Kali-Hyprland/README.md`](Kali-Hyprland/README.md) for full docs and [`KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md) for the complete fork delta.

---

## ◆ Installing both environments

You can install **both** stacks on the same Kali machine. D_WM-XFCE adds a session entry — it never touches i3 or Hyprland configs. Kali-Hyprland takes over the compositor layer. Switch between them at the greeter:

```bash
# Setup both
cd ~/hyprforge

# Install XFCE+i3 side first (safe, non-destructive)
cd D_WM-XFCE && ./setup.sh && ./install.sh

# Then install Hyprland side (will swap DM session)
cd ../Kali-Hyprland && ./install.sh

# Post-install check for both
cd ../D_WM-XFCE && ./doctor.sh
cd ../Kali-Hyprland && ./doctor.sh
```

At the login greeter, pick:
- **i3 Cyberpunk** → D_WM-XFCE (X11, VM-safe)
- **Hyprland** → Kali-Hyprland (Wayland, GPU-accelerated)
- **Xfce Session** → stock XFCE (fallback, always available)

---

## ◆ Safety design

### D_WM-XFCE
- **Idempotent** — re-run safely; installed packages are skipped
- **VMware auto-detection** — switches picom to xrender backend automatically
- **`.bak` rollback** — existing configs get `.bak.<timestamp>` before overwrite
- **XFCE never touched** — adds an i3 session entry, leaves XFCE intact
- **Non-root** — refuses root execution; uses `sudo` only where needed
- **All scripts `bash -n` clean** — syntax-validated on every commit

### Kali-Hyprland
- **`--dry-run` everywhere** — preview apt, file-writes, and systemctl changes
- **Manifest-backed rollback** — all changes logged to `Install-Logs/`
- **Display manager is sacred** — LightDM is disabled, never purged
- **NVIDIA build is VM-aware** — skips kernel module builds inside VMs
- **Kali APT sources untouched** — source rewriter early-returns when `ID=kali`
- **`.sources` (deb822) format supported** — works on modern Kali/Debian

---

## ▸ FAQ

<details>
<summary><b>◇ Is this a fork of JaKooLit's Debian-Hyprland?</b></summary>

`Kali-Hyprland/` started as a fork with Kali-specific patches. Every functional delta is documented in [`KALI-CHANGES.md`](Kali-Hyprland/KALI-CHANGES.md). `D_WM-XFCE/` is original work.

</details>

<details>
<summary><b>◇ Can I run Kali-Hyprland in a VM?</b></summary>

`vmware.sh` detects the guest and writes a software-rendering fallback. But Hyprland on `vmwgfx` is fragile. **Install `D_WM-XFCE` instead** — it's designed for virtualized environments.

</details>

<details>
<summary><b>◇ What if picom doesn't start / I get a black screen in i3?</b></summary>

Check VMware detection: `systemd-detect-virt`. If in VMware, run `./install-scripts/02-picom.sh` to redeploy the xrender config. Verify: `command -v picom`.

</details>

<details>
<summary><b>◇ How do I update?</b></summary>

```bash
cd ~/hyprforge && git pull

# D_WM-XFCE: re-run installer (idempotent)
cd D_WM-XFCE && ./install.sh

# Kali-Hyprland: per-component rebuild
cd ../Kali-Hyprland && ./update-hyprland.sh
```

</details>

<details>
<summary><b>◇ Can I customize keybinds?</b></summary>

**D_WM-XFCE:** Edit `~/.config/i3/config` directly. Re-run install with `dotfiles="OFF"` in `preset.sh` to skip dotfile deployment.

**Kali-Hyprland:** Write binds to `~/.config/hypr/UserConfigs/UserKeybinds.conf`.

</details>

<details>
<summary><b>◇ Something broke — how do I check?</b></summary>

```bash
# Full diagnostic for both stacks
cd D_WM-XFCE && ./doctor.sh      # 21 checks (packages, dotfiles, shell, themes, fonts, VMware)
cd ../Kali-Hyprland && ./doctor.sh  # binaries, libs, configs, keybind drop-in
```

</details>

---

## ☕ Support

If hyprforge made your desktop glow:

[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-archnexus707@gmail.com-yellow?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](mailto:archnexus707@gmail.com)

---

## ◆ Special thanks

**[JaKooLit](https://github.com/JaKooLit)** — his Debian-Hyprland project inspired the Kali-Hyprland fork. The Hyprland community wouldn't be what it is without his work.

Hyprland: [hyprwm](https://github.com/hyprwm). Themes: [Tokyo Night](https://github.com/folke/tokyonight.nvim), [Catppuccin](https://github.com/catppuccin).

---

<div align="center">

`forged by archnexus707 · for the rebels of the terminal`

**◆ ◆ ◆**

[**▸ Star**](https://github.com/archnexus707/hyprforge/stargazers) &nbsp;·&nbsp; [**▸ Fork**](https://github.com/archnexus707/hyprforge/fork) &nbsp;·&nbsp; [**▸ Issues**](https://github.com/archnexus707/hyprforge/issues)

**GPL-3.0** · See `Kali-Hyprland/LICENSE.md`

</div>
