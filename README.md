# cds
The cds (\"change directory savor\") command is used to change 
the current working directory by using the DIRECTORY ALIAS
when working on the Linux terminal in Linux and other Unix-like
operating systems and even Windows implemented by the pure Shell.

Linux users often need to change to some deep directores over and over again.
Typing or remembering the same directory path again and again reduces your 
productivity and distracts you from what you are actually doing.

You can save yourself some time by creating directory aliases for your most 
used directories. Aliases are like custom shortcuts used to represent a directory.

# Configurations
The default config file is ${HOME}/.cds.cnfg.
Use 'export CDS_CNFG=your_cnfg' to overwrite the default.

Must add this line in your .profile or .bash_profile:
alias cds=\". your_local_cds_tool_path/cds\"

If you use Cygwin or Windows Ubuntu, set the Linux mount base in profile file:
export CDS_LINUX_MOUNT=/mnt
So, \"C:\Program Files (x86)\" will be converted to \"/mnt/c/Program Files (x86)\".# 

# General usage
```
    cds [ --help|-h ] [ <alias> ] [ -<n> ] 
        [ --go|-g ] [ --last|-l ] [ --first|-f ] [-w|--win <win_path>]
        [ --add|-a <alias> ] [ --delete|-d <alias> ] [ --path|-p <path> ]
        [ --show|-s ]
```
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

# Examples
    cds
        -  cd \${ROOT}

    cds --help, cds -h
        - Print the help message

    cds -3
        -  e.g. ls => file1, folder2, folder3. Then, it means 'cd folder3'

    cds -g
        - e.g. ./folder1/folder2/foler3/. Then it means 'cd ./folder1/folder2/foler3/'.

    cds -a test -p
        - Add a new alias 'test' for the current path \${PWD}.
    
    cds -a test2 -p /home/my/test/
        - Add a new alias 'test2' for /home/my/test/.
    
    cds -d test2
        - Remove alias 'test2'
    
    cds -s
        - Show exsiting alaises.
    
    cds -w \"C:\Program Files (x86)\"
        - cd \"/mnt/c/Program Files (x86)\"

