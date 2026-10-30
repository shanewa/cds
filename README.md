<p align="center">
  <img src="assets/cds-logo.png" alt="PanRelay logo" width="200">
</p>

# cds
The cds ("change directory savor") command changes the current directory
by directory alias. Source it from bash 3.2+ or zsh.

Supported environments:

- GNU/Linux, including Ubuntu, Debian, Red Hat, and other distributions
- Windows Subsystem for Linux 2 (WSL2)
- Cygwin, MSYS2, and Git Bash
- macOS (zsh or bash)

Linux users often need to change to some deep directores over and over again.
Typing or remembering the same directory path again and again reduces your 
productivity and distracts you from what you are actually doing.

You can save yourself some time by creating directory aliases for your most 
used directories. Aliases are like custom shortcuts used to represent a directory.

# Configurations
The default config file is ${HOME}/.cds.cnfg.
Use 'export CDS_CNFG=your_cnfg' to overwrite the default.

Source cds from the shell startup file (`.bashrc` on Linux, WSL2, Cygwin, and Git Bash; `.zshrc` on macOS):

`alias cds=". your_local_cds_tool_path/src/cds"`

`cds -w` converts a Windows path with `wslpath` (WSL2), `cygpath` (Cygwin, MSYS2, Git Bash), or a mount prefix:

| Environment | Example result for `C:\Program Files` |
| --- | --- |
| WSL2 | `/mnt/c/Program Files` |
| Cygwin | `/cygdrive/c/Program Files` |
| MSYS2 / Git Bash | `/c/Program Files` |

Set `CDS_LINUX_MOUNT` only when that prefix is different. WSL2 also reads the `automount.root` value in `/etc/wsl.conf` when `wslpath` is not available. 

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

    --win, -w <win_path>  : cd into a Windows path.

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
    
    cds -w "C:\Program Files (x86)"
        - cd the POSIX path for that Windows directory.

