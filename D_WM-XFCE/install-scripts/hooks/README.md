# Hooks

Drop an executable script in this directory and it auto-runs around install
phases. No installer changes required.

## Recognised names

| File                | When it fires                              | Argument the hook receives |
| ------------------- | ------------------------------------------ | -------------------------- |
| `pre-all.sh`        | Before **every** phase                     | The phase name (e.g. `i3`) |
| `post-all.sh`       | After **every** phase                      | `<name>=<rc>` (e.g. `i3=0`) |
| `pre-<phase>.sh`    | Before a specific phase                    | (none)                     |
| `post-<phase>.sh`   | After a specific phase                     | The phase's exit code      |

For D_WM-XFCE the phases are: `00-deps`, `pre-clean`, `vmware`, `i3`, `picom`,
`xfce`, `kitty-zsh`, `fonts`, `themes`, `dotfiles`, `final`.

## Behaviour knobs

| Env var          | Default | Effect                                                 |
| ---------------- | ------- | ------------------------------------------------------ |
| `NO_HOOKS=1`     | unset   | Skip all hooks for this run                            |
| `STRICT_HOOKS=1` | unset   | Hook failure aborts the install (default is soft warn) |

## Examples

```bash
# hooks/pre-i3.sh — print a custom message before the i3 phase runs
#!/usr/bin/env bash
echo "[my-hook] about to install i3 stack"
```

```bash
# hooks/post-all.sh — beep on every phase completion
#!/usr/bin/env bash
ctx="$1"   # e.g. "i3=0" or "fonts=1"
case "$ctx" in
    *=0) printf '\a' ;;
    *)   printf '\a\a\a' ;;
esac
```

```bash
# hooks/post-final.sh — auto-launch a status check after the install completes
#!/usr/bin/env bash
exec "$(dirname "$0")/../../doctor.sh"
```

The installer makes each hook executable on first invocation if it isn't
already, so you can `git checkout` hooks without remembering `chmod +x`.
