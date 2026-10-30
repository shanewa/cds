#---------------------------------------------------------------------------
# cds - change directory by alias.
#
# Source it from bash 3.2+ or zsh (do not execute it):
#   alias cds=". /path/to/cds"
#
# Works in interactive shells on:
#   GNU/Linux (Ubuntu, Debian, Red Hat, and other distros)
#   WSL2, Cygwin, MSYS2, Git Bash
#   macOS
#
# Windows drive paths are converted with wslpath, cygpath, or CDS_LINUX_MOUNT.
#---------------------------------------------------------------------------

if [[ -z "${BASH_VERSION:-}" && -z "${ZSH_VERSION:-}" ]]; then
    printf '%s\n' "cds: source this file from bash 3.2+ or zsh." >&2
    return 1 2>/dev/null || exit 1
fi

# Use 'export CDS_CNFG=your_cnfg' to overwrite the default.
if [[ -z "${CDS_CNFG:-}" ]]; then
    CDS_CNFG="${HOME}/.cds.cnfg"
fi

if [[ "${cds_init_flag:-}" != "yes" ]]; then

# The change history of cds
CDS_CHANGE_HISTORY="
#########################################################################
Change History:

Version  7: 2026/10/30 Run on bash 3.2+ and zsh without gawk.
                       Auto-detect WSL2, Cygwin, and MSYS/Git Bash mounts.
Version  6: 2021/07/06 Refactor code.
                       Remove the company specific information.
Version  5: 2019/03/22 Support Windows style directory.
Version  4: 2018/05/18 Add loop cd.
Version  3: 2016/09/12 Add config file.
Version  2: 2016/08/03 Enhance this tool on build servers.
Version  1: 2016/07/15 Develop this tool for CPRS testing.
#########################################################################
"

CDS_GENERAL_USAGE="
USAGE:
    cds [ --help|-h ] [ <alias> ] [ -<n> ]
        [ --go|-g ] [ --last|-l ] [ --first|-f ] [-w|--win <win_path>]
        [ --add|-a <alias> ] [ --delete|-d <alias> ] [ --path|-p <path> ]
        [ --show|-s ]
"

CDS_EXTENDED_USAGE="
    --help, -h  : Displays command usage, description and examples.

    <alias>     : Change dir to the path represented by this alias.

    -<n>        : Change dir to the <n>th folder/file in current directory.

    --go, -g    : Recursively cd into the only subdirectory until a directory
                  has zero or several subdirectories.

    --last, -l  : cd into the last folder/file in current directory.

    --first, -f : cd into the first folder/file in current directory.

    --win, -w <win_path>  : cd into a Windows path (C:\\... or C:/...).

    --add|-a <alias> --path|-p <path>: Add a new directory alias for path.

    --delete, -d <alias> : Remove an existing directory alias.

    --show, -s  : Show all directory aliases.
"

CDS_EXAMPLES_USAGE="
DESCRIPTION:
    The cds (\"change directory savor\") command changes the current directory
    by DIRECTORY ALIAS. Source it from bash 3.2+ or zsh on GNU/Linux
    (Ubuntu, Debian, Red Hat, and other distros), WSL2, Cygwin, MSYS2,
    Git Bash, and macOS.

CONFIGURATIONS:
    The default config file is \${HOME}/.cds.cnfg.
    Use 'export CDS_CNFG=your_cnfg' to overwrite the default.

    Add this line to the shell startup file (.bashrc or .zshrc):
    alias cds=\". your_local_cds_tool_path/cds\"

    Windows drive letters are converted automatically:
      WSL2             wslpath     /mnt/c/Program Files
      Cygwin           cygpath     /cygdrive/c/Program Files
      MSYS2 / Git Bash cygpath     /c/Program Files
    Set CDS_LINUX_MOUNT only when the mount prefix is custom
    (WSL automount root, a non-default Cygwin prefix, and so on).
    Example: export CDS_LINUX_MOUNT=/mnt

EXAMPLES:
    cds
        -  cd \${ROOT} by default.

    cds --help, cds -h
        - Print the help message.

    cds -3
        -  e.g. ls => file1, folder2, folder3. Then, it means 'cd folder3'.

    cds -g
        - e.g. ./folder1/folder2/folder3/ with one subdirectory at each level.
          Then it means 'cd ./folder1/folder2/folder3/'.

    cds -a test -p
        - Add a new alias 'test' for the current path \${PWD}.

    cds -a test2 -p /home/my/test/
        - Add a new alias 'test2' for /home/my/test/.

    cds -d test2
        - Remove alias 'test2'.

    cds -s
        - Show existing aliases.

    cds -w \"C:\\Program Files (x86)\"
        - cd the POSIX path for that Windows directory.
"

cds_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value#\"}"
    value="${value%\"}"
    printf '%s' "$value"
}

cds_detect_platform() {
    local uname_s="" version=""
    uname_s=$(uname -s 2>/dev/null || printf '%s' "unknown")
    version=""
    if [[ -r /proc/version ]]; then
        version=$(cat /proc/version 2>/dev/null || true)
    fi
    if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" || "$version" == *[Mm]icrosoft* ]]; then
        CDS_PLATFORM="wsl"
    elif [[ "${OSTYPE:-}" == cygwin* || "$uname_s" == CYGWIN* ]]; then
        CDS_PLATFORM="cygwin"
    elif [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == mingw* || "$uname_s" == MINGW* || "$uname_s" == MSYS* ]]; then
        CDS_PLATFORM="msys"
    elif [[ "${OSTYPE:-}" == darwin* || "$uname_s" == Darwin ]]; then
        CDS_PLATFORM="macos"
    elif [[ "$uname_s" == Linux ]]; then
        CDS_PLATFORM="linux"
    else
        CDS_PLATFORM="unix"
    fi
}

# Prints the Windows drive mount prefix. An empty prefix means /c/... (MSYS).
cds_mount_prefix() {
    local line="" section="" key="" root=""
    if [[ -n "${CDS_LINUX_MOUNT+x}" ]]; then
        printf '%s' "$CDS_LINUX_MOUNT"
        return 0
    fi
    case "${CDS_PLATFORM:-unix}" in
        cygwin)
            printf '%s' "/cygdrive"
            ;;
        msys)
            printf '%s' ""
            ;;
        wsl)
            root=""
            if [[ -r /etc/wsl.conf ]]; then
                while IFS= read -r line || [[ -n "$line" ]]; do
                    line="${line%$'\r'}"
                    line=$(cds_trim "$line")
                    [[ -z "$line" || "$line" == '#'* || "$line" == ';'* ]] && continue
                    if [[ "$line" == '['*']' ]]; then
                        section="$line"
                        continue
                    fi
                    if [[ "$section" == "[automount]" ]]; then
                        key=$(cds_trim "${line%%=*}")
                        if [[ "$key" == "root" ]]; then
                            root=$(cds_trim "${line#*=}")
                            break
                        fi
                    fi
                done < /etc/wsl.conf
            fi
            printf '%s' "${root:-/mnt}"
            ;;
        *)
            printf '%s' "/mnt"
            ;;
    esac
}

cds_win_to_posix_manual() {
    local win="$1" mount="" drive="" rest=""
    win=${win//\\//}
    case "$win" in
        [A-Za-z]:*)
            drive=$(printf '%.1s' "$win" | tr '[:upper:]' '[:lower:]')
            rest=$(printf '%s' "$win" | cut -c3-)
            ;;
        *)
            printf '%s' "$win"
            return 0
            ;;
    esac
    case "$rest" in
        /*) ;;
        "") ;;
        *) rest="/${rest}" ;;
    esac
    mount=$(cds_mount_prefix)
    if [[ -n "$mount" ]]; then
        printf '%s/%s%s' "$mount" "$drive" "$rest"
    else
        printf '/%s%s' "$drive" "$rest"
    fi
}

cds_win_to_posix() {
    local win="$1" converted=""
    if [[ -z "$win" ]]; then
        return 1
    fi
    # An explicit mount prefix wins over wslpath and cygpath.
    if [[ -z "${CDS_LINUX_MOUNT+x}" ]]; then
        if command -v wslpath >/dev/null 2>&1; then
            converted=$(wslpath -u "$win" 2>/dev/null) && [[ -n "$converted" ]] && {
                printf '%s' "$converted"
                return 0
            }
        fi
        if command -v cygpath >/dev/null 2>&1; then
            converted=$(cygpath -u "$win" 2>/dev/null) && [[ -n "$converted" ]] && {
                printf '%s' "$converted"
                return 0
            }
        fi
    fi
    cds_win_to_posix_manual "$win"
}

cds_lookup_alias() {
    local want="$1" line="" key=""
    [[ -n "$want" && -f "$CDS_CNFG" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "$line" || "$line" == '#'* || "$line" != *:* ]] && continue
        key="${line%%:*}"
        if [[ "$key" == "$want" ]]; then
            printf '%s' "${line#*:}"
            return 0
        fi
    done < "$CDS_CNFG"
    return 1
}

cds_expand_root() {
    local path="$1" prefix='${ROOT}' rel="" root_abs=""
    if [[ -n "${ROOT:-}" && -d "$ROOT" && "$path" == "$prefix"* ]]; then
        rel="${path#"$prefix"}"
        root_abs=$(builtin cd -- "$ROOT" && pwd) || return 1
        printf '%s%s' "$root_abs" "$rel"
    else
        printf '%s' "$path"
    fi
}

cds_rewrite_config() {
    local drop="$1" append="$2" tmp="" line=""
    tmp="${CDS_CNFG}.journal"
    : > "$tmp"
    if [[ -f "$CDS_CNFG" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            [[ "${line%%:*}" == "$drop" ]] && continue
            printf '%s\n' "$line" >> "$tmp"
        done < "$CDS_CNFG"
    fi
    if [[ -n "$append" ]]; then
        printf '%s\n' "$append" >> "$tmp"
    fi
    mv "$tmp" "$CDS_CNFG"
}

cds_add_alias() {
    local stored=""
    if [[ -z "${cds_new_path:-}" ]]; then
        cds_new_path=$PWD
    fi
    if [[ "$cds_new_alias" == *:* ]]; then
        printf '%s\n' "cds: alias cannot contain ':'." >&2
        return 1
    fi
    stored="$cds_new_path"
    if [[ -n "${ROOT:-}" && "$ROOT" != "/" && "$cds_new_path" == "$ROOT"* ]]; then
        stored="\${ROOT}${cds_new_path#"$ROOT"}"
    fi
    cds_rewrite_config "$cds_new_alias" "${cds_new_alias}:${stored}"
}

cds_delete_alias() {
    local alias2remove="$1"
    [[ -n "$alias2remove" ]] || return 1
    cds_rewrite_config "$alias2remove" ""
}

cds_show_all() {
    local line="" key="" val=""
    [[ -f "$CDS_CNFG" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "$line" || "$line" == '#'* || "$line" != *:* ]] && continue
        key="${line%%:*}"
        val="${line#*:}"
        printf '%10s\t%s\n' "$key" "$val"
    done < "$CDS_CNFG"
}

cds_cd_alias() {
    local myalias="$1" mypath=""
    mypath=$(cds_lookup_alias "$myalias") || return 0
    [[ -n "$mypath" ]] || return 0
    mypath=$(cds_expand_root "$mypath") || return 1
    builtin cd -- "$mypath"
}

cds_go() {
    local count=0 name="" target="" before="" after=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        setopt localoptions nullglob
    else
        cds_nullglob_restore=0
        shopt -q nullglob || cds_nullglob_restore=1
        shopt -s nullglob
    fi
    while true; do
        count=0
        target=""
        for name in */; do
            [[ -d "$name" ]] || continue
            count=$((count + 1))
            target="$name"
            [[ "$count" -gt 1 ]] && break
        done
        [[ "$count" -eq 1 ]] || break
        before=$(pwd)
        builtin cd -- "${target%/}" || break
        after=$(pwd)
        [[ "$before" == "$after" ]] && break
    done
    if [[ -z "${ZSH_VERSION:-}" && "${cds_nullglob_restore:-0}" -eq 1 ]]; then
        shopt -u nullglob
    fi
    unset cds_nullglob_restore
    pwd && command ls
}

cds_cd_from_ls() {
    local spec="$1" target=""
    target=$(CLICOLOR_FORCE= LS_COLORS= command ls -1 | sed -n "${spec}p")
    [[ -n "$target" ]] || return 1
    builtin cd -- "$target"
}

cds_cd_win() {
    local posix=""
    posix=$(cds_win_to_posix "$1") || return 1
    [[ -n "$posix" ]] || return 1
    builtin cd -- "$posix"
}

cds_clear_vars() {
    cds_new_alias=""
    cds_new_path=""
}

fi

######################## MAIN PROGRAM ###############################
cds_detect_platform

# If there's no input parameter, change to ${ROOT}.
if [[ $# -eq 0 && -n "${ROOT:-}" && -d "$ROOT" ]]; then
    builtin cd -- "$ROOT"
fi
cds_clear_vars

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            printf '%s\n' "$CDS_GENERAL_USAGE"
            printf '%s\n' "$CDS_EXTENDED_USAGE"
            printf '%s\n' "$CDS_EXAMPLES_USAGE"
            return 2
            ;;
        -v|--version)
            printf '%s\n' "$CDS_CHANGE_HISTORY"
            printf 'Platform: %s\n' "${CDS_PLATFORM:-unix}"
            return 2
            ;;
        -s|--show)
            cds_show_all
            ;;
        -g|--go)
            cds_go
            ;;
        -l|--last)
            cds_cd_from_ls '$'
            ;;
        -f|--first)
            cds_cd_from_ls '1'
            ;;
        -d|--delete)
            if [[ $# -gt 1 ]]; then
                shift
                cds_delete_alias "$1"
            fi
            ;;
        -w|--win)
            if [[ $# -gt 1 ]]; then
                shift
                cds_cd_win "$1"
            fi
            ;;
        -a|--add)
            if [[ $# -gt 1 ]]; then
                shift
                cds_new_alias="$1"
            fi
            ;;
        -p|--path)
            if [[ $# -gt 1 ]]; then
                shift
                cds_new_path="$1"
            fi
            ;;
        -[1-9]*)
            if [[ "$1" =~ ^-[1-9][0-9]*$ ]]; then
                cds_cd_from_ls "${1#-}"
            fi
            ;;
        *)
            cds_cd_alias "$1"
            ;;
    esac
    [[ $# -gt 0 ]] && shift
done

[[ -n "${cds_new_alias:-}" ]] && cds_add_alias
cds_clear_vars
