#!/bin/bash
export BINL=$(realpath ".")
mkdir -p TEST
ROOT=$(realpath "./TEST")
export TMPATH="$(realpath ./dateset)"
export TMPDATEPATH=$(realpath ./dateset)

assert() {
    if [ "$1" != "$2" ]; then
        echo "Assertion failed: $1 != $2"
        echo "$3"
    else
        echo "OK"
    fi
}

supertouch(){
    mkdir -p "$(dirname "$1")"
    touch "$1"
}

moleadd(){
    if [ "$1" = "-g" ];then
        supertouch "$3"   
        $BINL/mole "$1" "$2" "$3"
    else
        supertouch "$1"
        $BINL/mole "$1"
    fi
}

setup(){
    rm -rf TEST
    mkdir -p TEST

    #init dates
    mkdir -p dateset
    rm dateset/tmp
    $REALDATE > dateset/tmp

    #end

    export EDITOR=touch
    export MOLE_RC=$ROOT/MOLE_RC
    touch "$MOLE_RC"
    echo "Generating files. This may take some time"

    DATE1=$(./testdate '+%Y-%m-%d')


    moleadd $ROOT/.ssh/config
    moleadd -g bash $ROOT/.bashrc
    moleadd $ROOT/.local/bin/./mole
    moleadd -g bash $ROOT/.bashrc                         # (D)
    moleadd $ROOT/.indent.pro
    moleadd $ROOT/.viminfo

    ./datesadday
    ./datesadday
    ./datesadday
    ./datesadday
    DATE2=$(./testdate '+%Y-%m-%d')

    moleadd -g bash $ROOT/.bash_history
    moleadd -g git $ROOT/.gitconfig
    moleadd -g bash $ROOT/.bash_profile                   # (C)
    moleadd -g git $ROOT/proj1/.git/info/exclude
    moleadd $ROOT/.ssh/known_hosts                        # (A)
    moleadd -g git $ROOT/proj1/.git/config
    moleadd -g git $ROOT/proj1/.git/COMMIT_EDITMSG
    moleadd $ROOT/proj1/.git/COMMIT_EDITMSG
    moleadd -g git $ROOT/proj1/.git/config                # (F)
    moleadd -g project $ROOT/proj1/main.c
    moleadd -g project $ROOT/proj1/struct.c
    moleadd -g project $ROOT/proj1/struct.h
    moleadd -g project_readme $ROOT/proj1/README.md

    ./datesadday
    ./datesadday
    ./datesadday
    DATE3=$(./testdate '+%Y-%m-%d')
    ./datesadday
    DATE4=$(./testdate '+%Y-%m-%d')

    moleadd -g git2 $ROOT/.gitconfig
    moleadd $ROOT/proj1/main.c
    moleadd $ROOT/.bashrc                                 # (E)
    moleadd $ROOT/.indent.pro
    moleadd $ROOT/.vimrc                                  # (B)

    echo "Files generated."
}

setup     
export EDITOR=echo
cd $ROOT/.ssh || exit
assert "$($BINL/mole)" "$ROOT/.ssh/known_hosts" "(odpovídá řádku A)"
assert "$($BINL/mole "$ROOT")" "$ROOT/.vimrc" "(odpovídá řádku B)"
assert "$($BINL/mole -g bash "$ROOT")" "$ROOT/.bash_profile" "(odpovídá řádku C)"
assert "$($BINL/mole -g bash -b "$DATE2" "$ROOT")" "$ROOT/.bashrc" "(odpovídá řádku D)"

cd $ROOT || exit
assert "$($BINL/mole -m)" "$ROOT/.bashrc" "(odpovídá řádku E)"
assert "$($BINL/mole -m -g git $ROOT/proj1/.git)" "$ROOT/proj1/.git/config" "(odpovídá řádku F; ve skupině git byl daný soubor editován jako jediný dvakrát, zbytek souborů jednou)"

export EDITOR=touch
$BINL/mole -m -g tst >> /dev/null
assert $? 1

$BINL/mole -a 2023-02-16 -b 2023-02-20 >> /dev/null
assert $? 1

cd .. || exit
setup
export EDITOR=echo
assert "$($BINL/mole list $ROOT)" '.bash_history: bash
.bash_profile: bash
.bashrc:       bash
.gitconfig:    git,git2
.indent.pro:   -
.viminfo:      -
.vimrc:        -' "Zobrazení seznamu editovaných souborů. 1. případ"
assert "$($BINL/mole list -g bash $ROOT)" '.bash_history: bash
.bash_profile: bash
.bashrc:       bash' "Zobrazení seznamu editovaných souborů. 2. případ"
assert "$($BINL/mole list -g project,project_readme $ROOT/proj1)" 'main.c:    project
README.md: project_readme
struct.c:  project
struct.h:  project' "Zobrazení seznamu editovaných souborů. 3. případ"
assert "$($BINL/mole list -b $DATE2 $ROOT)" '.bashrc:     bash
.indent.pro: -
.viminfo:    -' "Zobrazení seznamu editovaných souborů. 4. případ"
assert "$($BINL/mole list -a $DATE3 $ROOT)" '.bashrc:     -
.gitconfig:  git2
.indent.pro: -
.vimrc:      -' "Zobrazení seznamu editovaných souborů. 5. případ" # bug in example ".viminfo" was not edited ".vimrc" was and missing : after .gitconfig
assert "$($BINL/mole list -a $DATE1 -b $DATE4 -g bash $ROOT)" '.bash_history: bash
.bash_profile: bash' "Zobrazení seznamu editovaných souborů. 6. případ"
assert "$($BINL/mole list -a $DATE2 -b $DATE4 $ROOT)" "" "Zobrazení seznamu editovaných souborů. 7. případ"
assert "$($BINL/mole list -g grp1,grp2 $ROOT)" "" "Zobrazení seznamu editovaných souborů. 8. případ"