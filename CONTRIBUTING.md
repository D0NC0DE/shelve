# Contributing to shelve

Thanks for wanting to contribute. This guide covers everything you need to know before writing a line of code.

---

## Before you start

**Open an issue first.** If you want to work on something from the roadmap, or have a new idea, open an issue before building it. This saves you from spending time on something that doesn't fit the project's direction.

shelve is intentionally simple — a bash tool with no build system, no dependencies beyond Homebrew and gum. When evaluating contributions, the first question is always: does this make shelve simpler or more complex?

---

## The single most important rule

**All scripts must work with bash 3.2.**

macOS ships with bash 3.2 (from 2007) and this will never change for licensing reasons. Bash 4 and 5 have many conveniences — associative arrays, `mapfile`, `readarray`, improved string handling — that are simply not available here.

Things that will break on bash 3.2:

```bash
# ❌ Associative arrays — bash 4+ only
declare -A my_map
my_map["key"]="value"

# ❌ mapfile / readarray — bash 4+ only
mapfile -t my_array < <(some_command)

# ❌ ${var,,} and ${var^^} — bash 4+ only
lower="${var,,}"

# ❌ -u flag on set — crashes on empty arrays in bash 3.2
set -euo pipefail  # the -u will bite you

# ✅ Use this instead
set -eo pipefail   # no -u
```

Always test your changes by running `bash shelve save` explicitly — not by sourcing files in zsh. The shebang is `#!/usr/bin/env bash` on every file, and that's what matters in production.

---

## How to test

There is no test framework. Testing is manual and straightforward:

```bash
# Test the three main commands
bash shelve save
bash shelve restore
bash shelve fresh

# Test help
bash shelve help

# Test install from scratch (in a temp dir)
bash install.sh
```

For CI, every push and pull request runs a clean macOS install via GitHub Actions (`.github/workflows/test-install.yml`). This catches broken installs before users see them. You can see what it checks — the install must complete, `shelve help` must run, and `shelve.json` must NOT be created by the install alone.

If you're adding a new command or changing detection logic, manually verify:
- The happy path works
- Missing dependencies are handled gracefully (not every Mac has `mas`, `gh`, etc.)
- No files are created or modified that shouldn't be

---

## File structure

```
shelve/
├── shelve              ← entry point — parses the command, sources the right lib file
├── install.sh          ← one-liner curl bootstrap — installs Homebrew, gum, clones repo
├── README.md
├── CONTRIBUTING.md
├── ROADMAP.md
└── lib/
    ├── utils.sh        ← colours, logging, gum wrapper, shared helpers — sourced by all
    ├── detect.sh       ← scans the Mac, read-only, never installs anything
    ├── menu.sh         ← all gum interactive UI — sources detect.sh
    ├── save.sh         ← shelve save command
    ├── restore.sh      ← shelve restore command
    └── fresh.sh        ← shelve fresh command
```

The rule is simple: **detect.sh never installs, menu.sh never writes files, save/restore/fresh own their side effects.**

---

## Code style

These patterns come from the existing codebase. Match them.

### Sourcing

Every lib file sources `utils.sh` first using this portable pattern:

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"
```

`${BASH_SOURCE[0]:-$0}` is the bash 3.2 safe way to get the current file's path. Don't simplify it.

### Logging

All output goes through the helpers in `utils.sh`:

```bash
log_info "Something is happening"     # cyan bullet
log_success "It worked"               # green checkmark
log_warn "Something looks off" >&2    # yellow warning, stderr
log_error "Something broke" >&2       # red X, stderr
log_step "Starting a phase"           # bold cyan header
log_dim "A detail"                    # dimmed supplementary info
```

**Inside menu functions, all log calls must go to stderr (`>&2`).** Menu functions capture their output via command substitution — anything that goes to stdout gets captured as a selection. This is the most common source of subtle bugs. When in doubt, add `>&2`.

### The gum wrapper

`utils.sh` defines a wrapper around gum that strips the `BOLD` environment variable, which causes a display bug in gum 0.17.0:

```bash
gum() { env -u BOLD command gum "$@"; }
```

Always call `gum` — never call `command gum` directly.

### gum choose after pipes

When `gum choose` needs to read from the terminal (not stdin from a pipe), add `</dev/tty`:

```bash
choice=$(gum choose "Yes" "No" </dev/tty)
```

Forgetting this causes silent hangs when the function is called inside a subshell.

### Arrays

Bash functions don't share array scope. Arrays that need to persist across function calls must be declared at the top of the file as globals. See `restore.sh` for the pattern:

```bash
# At the top of the file, before any functions
selected_brews=()
selected_casks=()
```

### Avoiding the lsd alias

The project owner's shell aliases `ls` to `lsd`. Always use `/bin/ls` directly in scripts to bypass this:

```bash
/bin/ls -1 /Applications
```

### JSON

`shelve.json` is read and written with `grep`/`sed` — there is no `jq` dependency. Keep it that way. The JSON structure is simple enough that manual parsing works. See `restore.sh` for the `parse_json_array` and `parse_json_value` patterns.

### set flags

Every script uses:

```bash
set -eo pipefail
```

Not `-u`. The `-u` flag treats unset variables as errors, which crashes on empty arrays in bash 3.2. Leave it out.

---

## Security rules

These are non-negotiable:

- **Never back up SSH private keys** (`~/.ssh/id_*`). Not with a warning, not with a flag, never.
- **Never back up `.env` files.** Secret files are always excluded.
- **Warn before backing up dotfiles that may contain secrets.** Pattern match for `API_KEY`, `TOKEN`, `PASSWORD`, `SECRET` (case-insensitive).
- **`safe_remove()` is mandatory for any `rm` inside `~/.shelve/`.** It guards against empty variables expanding into dangerous paths. Never call `rm` directly on a variable path.

---

## What shelve will never be

From `ROADMAP.md` — don't propose these:

- SSH private key backup
- `.env` file backup
- Linux or Windows support
- A web dashboard or account system
- A GUI app

shelve is local-first, macOS-only, terminal-only. That's a feature.

---

## Claiming a roadmap item

1. Check [ROADMAP.md](ROADMAP.md) for the version and feature you want to build
2. Open an issue: "I want to build X from v0.2.0"
3. We'll discuss approach, edge cases, and any constraints before you start
4. Build it, test it, open a PR referencing the issue

Small fixes and documentation improvements don't need an issue first — just open a PR.

---

## Commit style

No strict convention, but keep commits focused and descriptive:

```
add: detect volta and fnm in detect_manual_installs
fix: gum choose hangs when called inside subshell
docs: add bash 3.2 examples to CONTRIBUTING
```

One logical change per commit. Don't bundle unrelated fixes.

---

## Questions

Open an issue with the `question` label. No question is too small.
