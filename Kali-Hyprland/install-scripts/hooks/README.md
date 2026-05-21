# Hooks

Drop an executable script in this directory and it auto-runs around every
`execute_script` call. No installer changes required.

## Recognised names

| File                  | When it fires                            | Argument the hook receives |
| --------------------- | ---------------------------------------- | -------------------------- |
| `pre-all.sh`          | Before **every** sub-script              | The sub-script filename    |
| `post-all.sh`         | After **every** sub-script               | `<script.sh>=<rc>`         |
| `pre-<basename>.sh`   | Before a specific sub-script             | (none)                     |
| `post-<basename>.sh`  | After a specific sub-script              | The sub-script's exit code |

Basename = the sub-script's filename without the `.sh` extension. Examples:

- `pre-hyprland.sh`  fires before `hyprland.sh` builds Hyprland from source
- `post-hyprutils.sh` fires after `hyprutils.sh` finishes
- `pre-fonts.sh`     fires before the fonts phase
- `post-03-Final-Check.sh` fires after the final-check phase

## Behaviour knobs

| Env var          | Default | Effect                                                 |
| ---------------- | ------- | ------------------------------------------------------ |
| `NO_HOOKS=1`     | unset   | Skip all hooks for this run                            |
| `STRICT_HOOKS=1` | unset   | Hook failure aborts the install (default is soft warn) |

## Examples

```bash
# hooks/pre-hyprland.sh — bump build parallelism for the Hyprland phase
#!/usr/bin/env bash
export MAKEFLAGS="-j$(nproc)"
```

```bash
# hooks/post-all.sh — log every phase result to a single line
#!/usr/bin/env bash
echo "[$(date +%H:%M:%S)] $1" >> ~/.cache/archnexus/phase-results.log
```

```bash
# hooks/post-03-Final-Check.sh — auto-run doctor.sh once the install finishes
#!/usr/bin/env bash
[ -x "$(dirname "$0")/../../doctor.sh" ] && "$(dirname "$0")/../../doctor.sh"
```

The installer makes each hook executable on first invocation if it isn't
already, so you can `git checkout` hooks without remembering `chmod +x`.
