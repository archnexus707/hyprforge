# Kali-Hyprland — engineering decisions

**by archnexus707**

This document records every functional decision made in Kali-Hyprland to support **Kali Linux** as the host and **VMware** as a fallback guest hypervisor. Cosmetic branding (banner, help text, archnexus polish) is included for completeness.

You can compare against the inherited Debian-Hyprland baseline with:

```bash
cd ~/Desktop
diff -ru Debian-Hyprland Kali-Hyprland --exclude=.git --exclude=Install-Logs
```

## Why a Kali-specific build?

Kali isn't Debian. Kali's `/etc/os-release` reports `ID=kali` and `VERSION_CODENAME=kali-rolling`, which a generic Debian-targeted installer doesn't recognise. The most consequential issue is `verify_and_offer_fix_apt_sources()` rewriting `/etc/apt/sources.list` with Debian-style overlays — on Kali that creates duplicate APT targets and breaks `apt update` until the user manually fixes the file. Kali-Hyprland intercepts before that rewrite and adds a series of other Kali-aware guards (display-manager safety, VMware fallback, security-tooling preservation) detailed below.

## Functional changes

| # | File | What changed | Why |
|---|---|---|---|
| 1 | `install.sh` | `verify_and_offer_fix_apt_sources()` returns early if `ID=kali` | Kali's sources file already enables `non-free` and `non-free-firmware`. Rewriting would duplicate APT entries. |
| 2 | `install.sh` | Trixie auto-detection also fires for `ID=kali` | Kali tracks Debian testing/sid, so the trixie build-toolchain shims (libstdc++ quirks, glaze pin) apply identically. |
| 3 | `install.sh` | Banner says "Kali-Hyprland — by archnexus707" | Disambiguate which installer is running; brand it clearly. |
| 4 | `install.sh` | `--help` header reads "Kali-Hyprland installer — by archnexus707" | Same. |
| 5 | `install.sh` | Calls `execute_script "vmware.sh"` immediately before `03-Final-Check.sh` | Run VMware adaptation after dotfiles are deployed so the Hyprland drop-in can be wired into UserSettings.conf. |
| 6 | `install-scripts/01-hypr-pkgs.sh` | Removed `cargo` from the `uninstall=( )` array | Kali users frequently have Rust-based security tooling (rustscan, custom recon scripts) depending on system cargo. The script later installs rustup which provides cargo via `~/.cargo/bin/` anyway — the apt removal was both harmful (broke user tools) and redundant. |
| 7 | `install-scripts/02-pre-cleanup.sh` | Added `xdph_conflicts=( xdg-desktop-portal-xfce xdg-desktop-portal-gtk )` array and a confirmation-prompted removal pass | Kali XFCE ships these portal implementations. Leaving them installed alongside `xdg-desktop-portal-hyprland` causes the wrong portal to register at Hyprland session start, breaking screen-share and file dialogs. Removal is confirmation-gated because it affects the user's XFCE fallback session. |
| 8 | `install-scripts/sddm.sh` | Added a `read -p "Proceed with display manager swap? [yes/NO]: "` confirmation before the `systemctl disable lightdm` loop. Comment also stresses that `lightdm` is only disabled, **never** apt-purged, so the user can `systemctl enable lightdm` from a TTY if SDDM misconfigures. | Disabling Kali's default greeter from inside an active graphical session is the single most common way to strand a user at a black screen. The confirmation and rollback hint reduce that risk. |
| 9 | `install-scripts/thunar.sh` | Removed `xfce4` from the `for DIR1 in gtk-3.0 Thunar xfce4; do … cp -r assets/$DIR1 ~/.config/ …` loop | The bundled `assets/xfce4` is built for a stripped-down XFCE. On Kali, `~/.config/xfce4` is the user's actual panel/keybinds/wallpaper config; even with the existence guard the copy is risky and Hyprland doesn't need that config to run. |
| 10 | `install-scripts/nvidia.sh` | Added a `systemd-detect-virt` early-exit before any apt operation; honours `FORCE_NVIDIA_IN_VM=1` escape hatch | A VMware guest sees `vmwgfx`, not Nvidia. Building `nvidia-kernel-dkms` against the running kernel and then trying to load it against a vmwgfx PCI tree produces a broken module or DKMS failure at install time. The early-exit prevents the user from accidentally bricking a VM by selecting the Nvidia option in the whiptail menu while running inside VMware. |
| 11 | **NEW** `install-scripts/vmware.sh` | New script. Detects VMware guest, installs `open-vm-tools` + `open-vm-tools-desktop` + `mesa-utils`, enables `vmtoolsd.service`, probes `glxinfo` for hardware GL (rejecting `llvmpipe`/`softpipe`/`swrast` renderers), then writes `~/.config/hypr/UserConfigs/vmware.conf` with either the "hardware GL available" branch (keep blur + animations) or the "software rendering" branch (disable blur + drop-shadow, set `WLR_RENDERER_ALLOW_SOFTWARE=1`). Always sets `WLR_NO_HARDWARE_CURSORS=1`. Wires the drop-in into `UserSettings.conf` if present. Idempotent and re-runnable. | Hyprland on `vmwgfx` Wayland is fragile. The probe-and-fallback approach means a VM with 3D acceleration enabled gets a pretty desktop, while a VM without it still gets a *working* desktop (just no blur). |

## What is intentionally **unchanged**

These were considered and explicitly left alone:

- **`install-scripts/00-dependencies.sh`** — every package in the dependency list is available in Kali's repos under the same names. No change needed.
- **GPL-3.0 license** — inherited LICENSE.md is preserved unchanged. Kali-Hyprland is also GPL-3.0.
- **`Global_functions.sh` and the `install_package`/`uninstall_package` helpers** — they work fine on Kali because Kali uses the same `apt-get` and `dpkg`.
- **The whiptail-driven option menu** — usability decision, not a portability one. Users get the same menu they would on Debian.
- **`hypr-tags.env` pinned versions** — these are official Hyprland release tags, not OS-specific.
- **NVIDIA logic on bare metal** — only the VMware case got an early-exit. Bare-metal Kali with Nvidia hardware still works exactly as it did on Debian.

## How to run

```bash
cd ~/Desktop/Kali-Hyprland

# 1. Strongly recommended: take a VM snapshot first if you're inside VMware,
#    or switch to a TTY (Ctrl+Alt+F2) if you're on bare metal.

# 2. Optional: edit preset.sh to set toggles before launch
$EDITOR preset.sh

# 3. Run the installer (uses whiptail UI by default; --tty for plain-text mode)
./install.sh

# 4. Reboot when prompted. SDDM will appear if you opted into the DM swap;
#    otherwise log out and pick "Hyprland" from lightdm's session menu.
```

## Verification before first run

```bash
# all 7 modified scripts pass bash -n syntax check
for f in install.sh install-scripts/{01-hypr-pkgs,02-pre-cleanup,sddm,thunar,nvidia,vmware}.sh; do
  bash -n "$f" && echo "  $f: OK"
done

# diff against the inherited baseline to see every changed line in context
diff -u ~/Desktop/Debian-Hyprland/install.sh        ./install.sh
diff -u ~/Desktop/Debian-Hyprland/install-scripts/  ./install-scripts/ | less
```

## Special thanks

Engineered by **archnexus707**. The decisions documented above are the Kali-Hyprland engineering layer.

## License

GPL-3.0. See `LICENSE.md`.
