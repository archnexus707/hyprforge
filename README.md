# Kali-Hyprland

**by archnexus707**

A Hyprland desktop installer for **bare-metal Kali Linux** — built so Kali's `apt` sources, display manager, and security tooling aren't broken in the process. Reproducible, dry-runnable, and reversible.

## When to use this vs D_WM-XFCE

| | Kali-Hyprland (this repo) | [D_WM-XFCE](../D_WM-XFCE/) |
|---|---|---|
| **Target** | Bare-metal Kali with a working GPU | Kali running inside VMware / VirtualBox |
| **Display server** | Wayland (Hyprland compositor) | X11 (XFCE session + i3-gaps + picom) |
| **Look** | Real Hyprland: blur, animations, hyprlock, ags | Hyprland *aesthetic* via i3-gaps + picom-ftlabs |
| **GPU requirement** | Working OpenGL ≥ 3.3 (Intel / AMD / NVIDIA) | None — works on `vmwgfx` |
| **Risk profile** | Replaces session; can swap display manager | Adds a session option; leaves XFCE intact |

**Rule of thumb:** if `systemd-detect-virt` returns anything other than `none`, install D_WM-XFCE instead. Kali-Hyprland *does* include a `vmware.sh` fallback for VMs with 3D acceleration available, but it's a fallback, not the primary use case.

## Quick start

```bash
cd ~/Kali-Hyprland         # or wherever you cloned it

# 1. Edit toggles before the first run
nano preset.sh

# 2. Compile-only smoke test (does not install anything)
./dry-run-build.sh --with-deps

# 3. Real install — interactive
./install.sh

# 4. Reboot, pick "Hyprland" from the greeter session menu

# 5. Verify everything landed
./doctor.sh
```

### Recommended first-run preset toggles

For a low-risk first install, set:

```sh
sddm="OFF"          # keep LightDM as greeter so you can fall back to XFCE
sddm_theme="OFF"
nvidia="OFF"        # leave OFF unless on real NVIDIA hardware
rog="OFF"           # only ON for ASUS ROG laptops
dots="ON"
```

After confirming Hyprland boots from LightDM, do a second pass with `sddm="ON"` if you want the prettier greeter.

## Safety design

| Promise | Mechanism |
|---|---|
| Preview before any change | `./dry-run-build.sh` — compiles every module, installs none |
| Apt sources never get clobbered on Kali | Early return in `verify_and_offer_fix_apt_sources()` when `ID=kali` |
| LightDM is never apt-purged | `sddm.sh` only `systemctl disable`s it, with a confirmation prompt |
| NVIDIA module is not built inside a VM | `nvidia.sh` early-exits on `systemd-detect-virt != none` (override with `FORCE_NVIDIA_IN_VM=1`) |
| Wrong portal isn't registered | `02-pre-cleanup.sh` confirmation-prompts removal of `xdg-desktop-portal-xfce`/`-gtk` before installing the Hyprland portal |
| Every phase is logged | `Install-Logs/install-<timestamp>.log` |
| Re-runnable | `doctor.sh` + `update-hyprland.sh` are idempotent |
| Rollback path exists | `uninstall.sh` + `recovery.sh` |

## Environment requirements

Before you run `./install.sh`, this is what the project assumes:

| Layer | Required | Why |
|---|---|---|
| **Hardware** | Real GPU with OpenGL ≥ 3.3 (Intel / AMD / NVIDIA) | Hyprland is a Wayland compositor — needs a working DRM driver. In a VM, performance and stability are degraded; install **D_WM-XFCE** instead. |
| **OS** | Kali Linux (rolling) | Kali-Hyprland's apt-source guard and trixie build shims target `ID=kali`. Pure Debian works too but is **not** the supported target. |
| **Disk** | ≥ 5 GB free under `~/` | Hyprland source build artefacts + dotfiles + caches. |
| **Session at install time** | TTY recommended | The display-manager swap and dotfile copies are safest from outside an active X/Wayland session. Drop to `Ctrl+Alt+F3`, log in, then run `./install.sh`. |
| **After install: session for helpers** | Wayland (Hyprland) for full effect | The `archnexus-*` helpers detect `WAYLAND_DISPLAY` / `HYPRLAND_INSTANCE_SIGNATURE` and pick `grim`/`slurp`/`wl-copy`/`hyprctl` etc. Inside an X11 fallback they degrade to `flameshot`/`maim`/`xclip`. |

The tools themselves verify their runtime env and print actionable errors. For example, running `archnexus-shot` from a TTY:

```
archnexus-shot: needs a graphical session (DISPLAY or WAYLAND_DISPLAY).
Run from inside Hyprland, an i3 session, or XFCE.
```

…and missing dependencies always point back to `./install-scripts/optional-deps.sh`:

```
archnexus-ocr: tesseract-ocr missing — install via ./install-scripts/optional-deps.sh (group: OCR)
```

If something doesn't behave, run `./doctor.sh` — it checks every helper is on `$PATH`, confirms the Hyprland keybind drop-in is wired, and smoke-tests `archnexus-cheatsheet --raw`.

## Recovery

If Hyprland fails to start:

1. From the greeter, choose a different session (Xfce / GNOME).
2. From a TTY (`Ctrl+Alt+F3`), run `./recovery.sh` — it restores backed-up config files and reports what it touched.
3. To rebuild a single Hyprland component without re-running the whole installer, use `./update-hyprland.sh`.
4. To wipe the Hyprland install entirely: `./uninstall.sh`.

If LightDM was disabled and SDDM is broken: drop to a TTY, `sudo systemctl enable --now lightdm`, log back into XFCE, then troubleshoot.

## Design decisions

Key Kali-specific design choices (full table in [`KALI-CHANGES.md`](KALI-CHANGES.md)):

1. **Kali apt sources are sacred** — `install.sh` early-returns from the apt-sources rewriter when `ID=kali`; Kali already enables `non-free` and `non-free-firmware`.
2. **Trixie build shims apply to Kali** — Kali tracks Debian testing/sid, so the libstdc++ quirks and glaze pin apply identically.
3. **System `cargo` is preserved** — Kali security tooling (rustscan, custom recon scripts) depends on it; rustup gets installed alongside.
4. **Desktop-portal conflicts are confirmation-purged** — `xdg-desktop-portal-xfce`/`-gtk` are removed (with a prompt) before installing the Hyprland portal.
5. **LightDM is never apt-purged** — only `systemctl disable`d, and only after explicit confirmation. Recovery via TTY remains possible.
6. **Thunar config doesn't clobber `~/.config/xfce4`** — preserves your XFCE fallback session.
7. **NVIDIA build is VM-aware** — `nvidia.sh` early-exits inside a VM (override with `FORCE_NVIDIA_IN_VM=1`).
8. **VM fallback path** — `vmware.sh` detects VMware, probes GL, and writes `~/.config/hypr/UserConfigs/vmware.conf` with hardware-GL and software-fallback branches.
9. **Operator helpers ship by default** — `install-scripts/bin/` adds 19 `archnexus-*` utilities (audio, brightness, clip, display, ocr, power, recovery, shot, theme, watch, …) usable from any session.
10. **Three-theme switcher** — Cyberpunk Edgerunners / Tokyo Night Storm / Catppuccin Mocha, swappable via `archnexus-theme`.

## Repository layout

```
Kali-Hyprland/
├── install.sh                  # entry point
├── auto-install.sh             # non-interactive wrapper for repeatable runs
├── uninstall.sh
├── recovery.sh
├── doctor.sh                   # post-install self-diagnostic
├── update-hyprland.sh          # rebuild a single component
├── dry-run-build.sh            # compile-only smoke test
├── preset.sh                   # ON/OFF toggles
├── refresh-hypr-tags.sh
├── hypr-tags.env               # pinned Hyprland release tags
├── KALI-CHANGES.md
├── install-scripts/
│   ├── 00-dependencies.sh
│   ├── 01-hypr-pkgs.sh
│   ├── 02-pre-cleanup.sh
│   ├── 03-Final-Check.sh
│   ├── archnexus_banner.sh     # ARCHNEXUS rainbow banner + phase headers
│   ├── vmware.sh               # VM detect + GL probe + Hyprland drop-in
│   ├── hyprland.sh / hyprlock.sh / hyprpaper.sh / …
│   ├── nvidia.sh / nvidia-ori.sh
│   ├── sddm.sh / sddm_theme.sh
│   ├── thunar.sh / zsh.sh / fonts.sh / …
│   ├── bin/                    # archnexus-* user-facing helpers
│   ├── themes/                 # three-theme switcher
│   ├── systemd/                # hotplug + watch units
│   └── hooks/                  # post-install hook scripts
├── assets/                     # dotfiles, patches, .deb shims
└── Install-Logs/               # per-run logs
```

## Special thanks

Special thanks from **archnexus707** to [JaKooLit](https://github.com/JaKooLit) — his Debian-Hyprland project laid the early foundation that this Kali-targeted build was inspired by. The Hyprland community wouldn't be what it is without his work.

Shoutouts also to [Hypr Development](https://github.com/hyprwm) for Hyprland itself, and to the palette authors behind [Tokyo Night](https://github.com/folke/tokyonight.nvim), [Catppuccin](https://github.com/catppuccin/catppuccin), and Cyberpunk: Edgerunners.

## License

GPL-3.0. See `LICENSE.md`.
