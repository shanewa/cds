#!/bin/sh
# Install cds: download src/cds into ~/.local/share/cds and add a `cds` alias
# to the shell startup file. Safe to run more than once.
#
#   curl -fsSL https://raw.githubusercontent.com/shanewa/cds/main/install.sh | sh
#
# Overrides:
#   CDS_HOME      install directory          (default: $HOME/.local/share/cds)
#   CDS_RAW_BASE  where src/cds is fetched   (default: GitHub raw, main branch)

set -eu

RAW_BASE="${CDS_RAW_BASE:-https://raw.githubusercontent.com/shanewa/cds/main}"
CDS_HOME="${CDS_HOME:-$HOME/.local/share/cds}"
target="$CDS_HOME/cds"

die() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

command -v curl >/dev/null 2>&1 || die "curl is required"

mkdir -p "$CDS_HOME"
tmp="$target.tmp.$$"
if ! curl -fsSL "$RAW_BASE/src/cds" -o "$tmp"; then
    rm -f "$tmp"
    die "download failed: $RAW_BASE/src/cds"
fi
# cds is sourced, never executed, so it does not need the execute bit.
chmod 644 "$tmp"
mv "$tmp" "$target"
printf 'Installed %s\n' "$target"

# Pick the startup file from the login shell.
shell_name=$(basename "${SHELL:-/bin/sh}")
case "$shell_name" in
    zsh)
        rc="$HOME/.zshrc"
        ;;
    bash)
        # macOS login shells read .bash_profile instead of .bashrc.
        if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
            rc="$HOME/.bash_profile"
        else
            rc="$HOME/.bashrc"
        fi
        ;;
    *)
        printf 'Unsupported shell "%s" (cds needs bash 3.2+ or zsh).\n' "$shell_name"
        printf 'Add this line to your shell startup file yourself:\n'
        printf '  alias cds=". %s"\n' "$target"
        exit 0
        ;;
esac

alias_line="alias cds=\". $target\""

touch "$rc"
if grep -Fqx "$alias_line" "$rc"; then
    printf 'Alias already present in %s\n' "$rc"
elif grep -q '^[[:space:]]*alias cds=' "$rc"; then
    printf 'An existing "alias cds=" line is in %s. Left unchanged.\n' "$rc"
    printf 'Make it point to: %s\n' "$target"
else
    {
        printf '\n# cds (installed by install.sh)\n'
        printf '%s\n' "$alias_line"
    } >> "$rc"
    printf 'Added alias to %s\n' "$rc"
fi

printf 'Open a new terminal, or run: . %s\n' "$rc"
