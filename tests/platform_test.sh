#!/usr/bin/env bash
# Exercise cds on the current Unix-like shell (WSL2, Git Bash, Linux, macOS).
set -u

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cds_file="$root/cds"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0

fail() {
    printf 'FAIL %s\n' "$*" >&2
    failures=$((failures + 1))
}

pass() {
    printf 'ok %s\n' "$1"
}

bash -n "$cds_file" || fail "bash -n"
[[ "$failures" -eq 0 ]] && pass "syntax"

capture() {
    local start="$1"
    shift
    (
        set -e
        unset ROOT cds_init_flag CDS_LINUX_MOUNT CDS_PLATFORM
        export CDS_CNFG="$tmp/cnfg"
        export LC_ALL=C
        cd "$start" || exit 1
        # shellcheck disable=SC1090
        . "$cds_file" "$@" >/dev/null
        pwd
    )
}

expect_pwd() {
    local name="$1" start="$2" expected="$3"
    shift 3
    local got=""
    got=$(capture "$start" "$@") || {
        fail "$name (cds failed)"
        return
    }
    if [[ "$got" == "$expected" ]]; then
        pass "$name"
    else
        fail "$name got=$got expected=$expected"
    fi
}

# --go follows the only subdirectory, including names that contain spaces.
mkdir -p "$tmp/go/only/leaf/stop-a" "$tmp/go/only/leaf/stop-b"
mkdir -p "$tmp/spaces/My Dir/Next"
expect_pwd "go nested" "$tmp/go" "$tmp/go/only/leaf" -g
expect_pwd "go spaces" "$tmp/spaces" "$tmp/spaces/My Dir/Next" -g
expect_pwd "go stop" "$tmp/go/only/leaf" "$tmp/go/only/leaf" -g

# -f / -n / -l use plain ls order.
mkdir -p "$tmp/list/01-a" "$tmp/list/02-m" "$tmp/list/03-z"
expect_pwd "first" "$tmp/list" "$tmp/list/01-a" -f
expect_pwd "second" "$tmp/list" "$tmp/list/02-m" -2
expect_pwd "last" "$tmp/list" "$tmp/list/03-z" -l

# Aliases, paths with spaces, and ${ROOT}.
alias_root="$tmp/alias-root"
mkdir -p "$alias_root/deep" "$tmp/My Dir"
(
    set -e
    unset cds_init_flag CDS_LINUX_MOUNT CDS_PLATFORM
    export ROOT="$alias_root"
    export CDS_CNFG="$tmp/aliases"
    export LC_ALL=C
    cd "$alias_root/deep"
    # shellcheck disable=SC1090
    . "$cds_file" -a proj -p
    grep -F '${ROOT}/deep' "$CDS_CNFG" >/dev/null
    cd "$tmp"
    # shellcheck disable=SC1090
    . "$cds_file" proj >/dev/null
    [[ "$(pwd)" == "$alias_root/deep" ]]
) && pass "root alias" || fail "root alias"

(
    set -e
    unset ROOT cds_init_flag CDS_LINUX_MOUNT CDS_PLATFORM
    export CDS_CNFG="$tmp/spaces-alias"
    export LC_ALL=C
    cd "$tmp"
    # shellcheck disable=SC1090
    . "$cds_file" -a spaced -p "$tmp/My Dir"
    cd "$tmp/go"
    # shellcheck disable=SC1090
    . "$cds_file" spaced >/dev/null
    [[ "$(pwd)" == "$tmp/My Dir" ]]
    # shellcheck disable=SC1090
    . "$cds_file" -s | grep -F "$tmp/My Dir" >/dev/null
    # shellcheck disable=SC1090
    . "$cds_file" -d spaced
    if . "$cds_file" -s | grep -F "$tmp/My Dir" >/dev/null; then
        exit 1
    fi
) && pass "spaced alias" || fail "spaced alias"

# Manual Windows conversion honors CDS_LINUX_MOUNT over wslpath/cygpath.
convert() {
    local mount="$1" win="$2"
    (
        set -e
        unset ROOT cds_init_flag CDS_PLATFORM
        export CDS_CNFG="$tmp/cnfg"
        export CDS_LINUX_MOUNT="$mount"
        cd "$tmp"
        # shellcheck disable=SC1090
        . "$cds_file" >/dev/null
        cds_win_to_posix "$win"
    )
}

got=$(convert "/mnt" 'C:\Program Files (x86)') || fail "convert /mnt"
[[ "$got" == "/mnt/c/Program Files (x86)" ]] && pass "mount /mnt" || fail "mount /mnt got=$got"
got=$(convert "/cygdrive" 'C:/Program Files (x86)') || fail "convert /cygdrive"
[[ "$got" == "/cygdrive/c/Program Files (x86)" ]] && pass "mount /cygdrive" || fail "mount /cygdrive got=$got"
got=$(convert "" 'C:\Windows') || fail "convert empty mount"
[[ "$got" == "/c/Windows" ]] && pass "mount empty" || fail "mount empty got=$got"

# Native helper when CDS_LINUX_MOUNT is unset.
if command -v wslpath >/dev/null 2>&1; then
    expect=$(wslpath -u 'C:\Program Files (x86)')
    got=$(
        unset ROOT cds_init_flag CDS_LINUX_MOUNT CDS_PLATFORM
        export CDS_CNFG="$tmp/cnfg"
        cd "$tmp"
        # shellcheck disable=SC1090
        . "$cds_file" >/dev/null
        cds_win_to_posix 'C:\Program Files (x86)'
    )
    [[ "$got" == "$expect" ]] && pass "wslpath" || fail "wslpath got=$got expected=$expect"
fi

if command -v cygpath >/dev/null 2>&1; then
    expect=$(cygpath -u 'C:\Program Files (x86)')
    got=$(
        unset ROOT cds_init_flag CDS_LINUX_MOUNT CDS_PLATFORM
        export CDS_CNFG="$tmp/cnfg"
        cd "$tmp"
        # shellcheck disable=SC1090
        . "$cds_file" >/dev/null
        cds_win_to_posix 'C:\Program Files (x86)'
    )
    [[ "$got" == "$expect" ]] && pass "cygpath" || fail "cygpath got=$got expected=$expect"
fi

help_status=0
help_out=$(
    unset ROOT cds_init_flag CDS_LINUX_MOUNT
    export CDS_CNFG="$tmp/cnfg"
    cd "$tmp"
    # shellcheck disable=SC1090
    . "$cds_file" -h
) || help_status=$?
[[ "$help_status" -eq 2 ]] && pass "help status" || fail "help status=$help_status"
printf '%s' "$help_out" | grep -F "WSL2" >/dev/null && pass "help mentions WSL2" || fail "help text"

version_out=$(
    unset ROOT cds_init_flag CDS_LINUX_MOUNT
    export CDS_CNFG="$tmp/cnfg"
    cd "$tmp"
    # shellcheck disable=SC1090
    . "$cds_file" -v
) || true
printf '%s' "$version_out" | grep -E '^Platform: (wsl|cygwin|msys|macos|linux|unix)$' >/dev/null \
    && pass "platform" || fail "platform output: $version_out"

if [[ "$failures" -ne 0 ]]; then
    printf '%s\n' "$failures test(s) failed"
    exit 1
fi
printf '%s\n' "all tests passed"
