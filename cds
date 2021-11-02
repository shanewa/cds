#---------------------------------------------------------------------------
#--- cds
#---
#--- Usage: The cds ("change directory savor") command is used to change 
#---        the current working directory by using the DIRECTORY ALIAS
#---        when working on the Linux terminal in Linux and other Unix-like
#---        operating systems and even Windows implemented by the pure Shell.
#---
#--- Info: ATTENTION: Add this line in your .profile: alias cds=". ~/bin/cds"
#---------------------------------------------------------------------------

# Use 'export CDS_CNFG=your_cnfg' to overwrite the default.
[[ -z ${CDS_CNFG} ]] && CDS_CNFG=${HOME}/.cds.cnfg

if [[ "${cds_init_flag}" != "yes" ]]; then {

# The change history infomation of cds
CDS_CHANGE_HISTORY="
#########################################################################
Change History:

Version  6: 2021/07/06 Refactor code.
                       Remove the company specific information.
Version  5: 2019/03/22 Support Windows style directory.
Version  4: 2018/05/18 Add loop cd.
Version  3: 2016/09/12 Add config file.
Version  2: 2016/08/03 Enhance this tool on build servers.
Version  1: 2016/07/15 Develop this tool for CPRS testing.
#########################################################################
"

# Usage section
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

    --go, -g    : Recursively cd into the folder until no more folders in current dir.

    --last, -l  : cd into the last folder/file in current directory.

    --first, -f : cd into the first folder/file in current directory.

    --win, -w <win_path>  : cd into a windowns style path.

    --add|-a <alias> --path|-p <path>: Add a new directory alias for path.

    --delete, -d <alias> : Remove an existing directory alias.

    --show, -s  : Show all directory aliases.
"

CDS_EXAMPLES_USAGE="
DESCRIPTION:
    The cds (\"change directory savor\") command is used to change 
    the current working directory by using the DIRECTORY ALIAS
    when working on the Linux terminal in Linux and other Unix-like
    operating systems and even Windows implemented by the pure Shell.

    Linux users often need to change to some deep directores over and over again.
    Typing or remembering the same directory path again and again reduces your 
    productivity and distracts you from what you are actually doing.

    You can save yourself some time by creating directory aliases for your most 
    used directories. Aliases are like custom shortcuts used to represent a directory.

CONFIGURATIONS:
    The default config file is ${HOME}/.cds.cnfg.
    Use 'export CDS_CNFG=your_cnfg' to overwrite the default.
    
    Must add this line in your .profile or .bash_profile:
    alias cds=\". your_local_cds_tool_path/cds\"

    If you use Cygwin or Windows Ubuntu, set the Linux mount base in profile file:
    export CDS_LINUX_MOUNT=/mnt
    So, \"C:\Program Files (x86)\" will be converted to \"/mnt/c/Program Files (x86)\".

EXAMPLES:
    cds
        -  cd \${ROOT} by default.

    cds --help, cds -h
        - Print the help message.

    cds -3
        -  e.g. ls => file1, folder2, folder3. Then, it means 'cd folder3'.

    cds -g
        - e.g. ./folder1/folder2/foler3/. Then it means 'cd ./folder1/folder2/foler3/'.

    cds -a test -p
        - Add a new alias 'test' for the current path \${PWD}.
    
    cds -a test2 -p /home/my/test/
        - Add a new alias 'test2' for /home/my/test/.
    
    cds -d test2
        - Remove alias 'test2'.
    
    cds -s
        - Show exsiting alaises.
    
    cds -w \"C:\Program Files (x86)\"
        - cd \"/mnt/c/Program Files (x86)\".
"

if [[ -z ${CDS_LS} ]]; then {
   CDS_LS=$(alias ls 2>/dev/null | cut -d"'" -f2 | cut -d" " -f1)
   [[ -z ${CDS_LS} ]] && CDS_LS=ls
}
fi

function cds_load_cnfg() {
    typeset cds_tmp_key
    typeset cds_tmp_value
    typeset cds_tmp_line
    if [[ "${cds_init_flag}" != "yes" ]]; then {
        for cds_tmp_line in $(cat ${CDS_CNFG} 2>/dev/null); do {
            cds_tmp_key=$(echo ${cds_tmp_line} | cut -d: -f1)
            cds_tmp_value=$(echo ${cds_tmp_line} | cut -d: -f2)
            cds_configurations["${cds_tmp_key}"]="${cds_tmp_value}"
        }
        done 
        cds_init_flag="yes"
    }
    fi
}

function cds_add_alias() {
    # If --path is not provided, use the current path.
    [[ -z ${cds_new_path} ]] && cds_new_path=${PWD}
    # Use ${ROOT} instead of the absolute path
    if [[ "${ROOT}" != "" && "${cds_new_path}" == ${ROOT}* ]]; then {
        cds_new_path="\${ROOT}$(echo ${cds_new_path} | gawk -F"${ROOT}" '{print $2}')"
    }
    fi
    # Save
    cat ${CDS_CNFG} 2>/dev/null | grep -v "^${cds_new_alias}:" > ${CDS_CNFG}.journal
    echo "${cds_new_alias}:${cds_new_path}" >> ${CDS_CNFG}.journal
    mv ${CDS_CNFG}.journal ${CDS_CNFG}
    # Sync
    cds_init_flag="no"
    cds_load_cnfg
}

function cds_delete_alias() {
    typeset alias2remove="$1"
    # Remove alias from cnfg file
    cat ${CDS_CNFG} 2>/dev/null | grep -v "^${alias2remove}:" > ${CDS_CNFG}.journal
    mv ${CDS_CNFG}.journal ${CDS_CNFG}
    # Sync
    cds_init_flag="no"
    cds_load_cnfg
}

function cds_show_all() {
    gawk '{
        split($0, tmp, ":")        
        printf "%10s\t%s\n", tmp[1], tmp[2]
    }' ${CDS_CNFG} 2>/dev/null
}

function cds_cd_alias() {
    typeset myalias="$1"
    typeset mypath="${cds_configurations[${myalias}]}"
    if [[ ! -z ${mypath} ]]; then {
        if [[ "${mypath}" == "\${ROOT}"* ]]; then {
            typeset relative_path=$(echo "${mypath}" | gawk '{gsub(/\${ROOT}/, ""); print $0}')
            mypath="$(cd ${ROOT} && pwd)${relative_path}"
        }
        fi
        cd "${mypath}"
    }
    fi
}

function cds_go() {
    typeset cds_d_num=1
    typeset cds_d_name=""
    while [[ ${cds_d_num} -eq 1 ]]; do { 
        eval $(${CDS_LS} -l | gawk '{
                if ($0 ~ /^d/) {
                    cds_d_num++
                    cds_d_name=$NF
                }
            } END {
                printf("cds_d_num=%d; cds_d_name=%s", cds_d_num, cds_d_name)
            }')
        [[ ${cds_d_num} -eq 1 ]] && cd "${cds_d_name}"
    }
    done
    pwd && ${CDS_LS}
}

function cds_path_windowns_2_linux() {
    typeset win_path="$1"
    echo "${win_path}" | tr '\' '\n' 2>/dev/null | \
    gawk -v cds_linux_mount="${CDS_LINUX_MOUNT}" '{
        if ($0 ~ /^[C-Z]:$/) {
            split($0, tmp, ":")
            disk=tolower(tmp[1])
            linux_path=sprintf("%s/%s", cds_linux_mount, disk)
        } else {
            linux_path=sprintf("%s/%s", linux_path, $0)
        }
    } END {
        print linux_path
    }'
}

function cds_clear_vars() {
    cds_new_alias=""
    cds_new_path=""
}

}
fi

######################## MAIN PROGRAM ###############################
# If there's no input parameter, change to ${ROOT}.
[[ $# -eq 0 ]] && [[ -d ${ROOT} ]] && cd "${ROOT}"
if [[ ${#cds_configurations[@]} -eq 0 ]]; then {
    unset cds_configurations
    declare -A cds_configurations
}
fi
cds_load_cnfg
cds_clear_vars
# Handle the input parameters.
while [[ $# -gt 0 ]]; do {
    case ${1} in
        # Directive options
        -h|--help)
            echo "${CDS_GENERAL_USAGE}"
            echo "${CDS_EXTENDED_USAGE}"
            echo "${CDS_EXAMPLES_USAGE}"
            return 2
        ;;
        -v|--version)
            echo "${CDS_CHANGE_HISTORY}"
            return 2
        ;;
        -s|--show)
            cds_show_all
        ;;
        -g|--go)
            cds_go
        ;;
        -l|--last)
            cd "$(${CDS_LS} | sed -n '$p')"
        ;;
        -f|--first)
            cd "$(${CDS_LS} | head -1)"
        ;;
        -d|--delete)
            [[ $# -gt 0 ]] && shift
            cds_delete_alias "$1"
        ;;
        -w|--win)
            [[ $# -gt 0 ]] && shift
            cd "$(cds_path_windowns_2_linux "$1")"
        ;;
        # Combined options
        -a|--add)
            [[ $# -gt 0 ]] && shift
            cds_new_alias="$1"
        ;;
        -p|--path)
            [[ $# -gt 0 ]] && shift
            cds_new_path="$1"
        ;;
        # Change dir to the <n>th folder.
        -[1-9]*)
            [[ "$1" =~ ^-[1-9][0-9]*$ ]] && cd "$(${CDS_LS} | sed -n "$(echo ${1} | cut -d- -f2)p")"
        ;;
        # Change dir to alias
        *)
            cds_cd_alias "$1"
        ;;
    esac

    # Next parameter
    [[ $# -gt 0 ]] && shift
}
done

[[ ! -z ${cds_new_alias} ]] && cds_add_alias
