<div align="center">
  <h1>cds</h1>

  <p align="center">
    <img src="assets/cds-logo.png" alt="cds" width="50%"/><br>
    <i>Change directory. Savor the shortcut.</i>
    <br>
  </p>

  <p align="center">
    <a href="src/cds">Source</a>
    ·
    <a href="https://github.com/shanewa/cds/issues">Submit an Issue</a>
    ·
    <a href="LICENSE">MIT License</a>
    <br>
    <br>
  </p>

  <p align="center">
    <a href="https://github.com/shanewa/cds/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/shanewa/cds?style=flat-square&color=14b8a6" /></a>&nbsp;
    <a href="https://github.com/shanewa/cds/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/shanewa/cds?style=flat-square&color=0ea5e9" /></a>&nbsp;
    <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/github/license/shanewa/cds?style=flat-square&color=2dd4bf" /></a>&nbsp;
    <img alt="bash or zsh" src="https://img.shields.io/badge/shell-bash%20%7C%20zsh-0f172a?style=flat-square" />
  </p>
  <hr>
  <br>
</div>

Deep paths get typed once and then forgotten. `cds` stores them as names, jumps straight there, and keeps working on Linux, WSL2, Cygwin, Git Bash, and macOS.

## Why the name

`cds` is typed with the left hand alone. On a QWERTY keyboard, `c`, `d`, and `s` sit close together on the left side, and `d` and `s` are on the home row. Your fingers barely leave their resting position, so the command goes out fast, one-handed, and without a reach. Each keystroke is a short, comfortable move.

## Drop in

Source it. Do not execute it. `cd` has to happen in the shell you are already using.

```bash
# ~/.bashrc on Linux, WSL2, Cygwin, and Git Bash
# ~/.zshrc on macOS
alias cds=". /path/to/cds/src/cds"
```

Requires bash 3.2+ or zsh.

```text
cds work          # jump to a saved alias
cds -a work -p    # save the current directory as work
cds -g            # walk the only subdirectory until the path forks
cds -w 'C:\src'   # land on the POSIX path for that Windows folder
```

## Commands

```text
cds [ --help|-h ] [ <alias> ] [ -<n> ]
    [ --go|-g ] [ --last|-l ] [ --first|-f ] [ --win|-w <win_path> ]
    [ --add|-a <alias> ] [ --path|-p <path> ]
    [ --delete|-d <alias> ] [ --show|-s ]
```

| Command | What it does |
| --- | --- |
| `cds` | `cd` to `$ROOT` when that directory exists |
| `cds <alias>` | `cd` to the path saved under that name |
| `cds -a <alias> -p [path]` | Save an alias. Omit the path to use `$PWD` |
| `cds -d <alias>` | Delete an alias |
| `cds -s` | List every alias |
| `cds -n` | `cd` to the nth entry from `ls` |
| `cds -f` / `cds -l` | `cd` to the first or last entry from `ls` |
| `cds -g` | Keep entering the only subdirectory until there are zero or several |
| `cds -w <win_path>` | `cd` to a Windows path (`C:\...` or `C:/...`) |
| `cds -h` / `cds -v` | Help, or the version history |

Aliases live in `~/.cds.cnfg` as `name:path`. Override the file with `CDS_CNFG`.

```bash
export CDS_CNFG="$HOME/dotfiles/cds.cnfg"
```

A path under `$ROOT` is stored as `${ROOT}/...` and expanded again when you jump.

## Windows paths

`cds -w` picks the converter for the shell you are in. Set `CDS_LINUX_MOUNT` only when the prefix is not the default.

| Shell | `C:\Program Files` becomes |
| --- | --- |
| WSL2 | `/mnt/c/Program Files` via `wslpath` |
| Cygwin | `/cygdrive/c/Program Files` via `cygpath` |
| MSYS2 / Git Bash | `/c/Program Files` via `cygpath` |

WSL2 falls back to `automount.root` in `/etc/wsl.conf` when `wslpath` is missing.

```bash
export CDS_LINUX_MOUNT=/mnt
cds -w "C:\Program Files (x86)"
```

## Where it runs

- GNU/Linux, including Ubuntu, Debian, and Red Hat
- WSL2
- Cygwin, MSYS2, and Git Bash
- macOS, with zsh or bash

No `gawk`. No bash 4 associative arrays. The same file sources on all of them.
