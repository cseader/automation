#!/bin/bash
#
# Compares local branch of crowbar and barclamps repositories with upstream
# using 'git cherry -v'.  Run with --help for help.

compare () {
    local="$1"
    upstream="$2"
    subbranch="$3"
    name="$4"

    if ! git cat-file -e $upstream/$subbranch >&/dev/null; then
        echo "$upstream/$subbranch does not exist in $name" >&2
        return 1
    fi
    git cherry -v $upstream/$subbranch $local/$subbranch
    #git --no-pager log --no-merges --pretty=format:%H $upstream..$local
}

get_barclamps () {
    # This only works if we have the right branch checked out ...
    #git submodule --quiet foreach 'echo $toplevel ${name#barclamps/}'

    # ... so hardcode the list of barclamps we care about:
    for bc in \
        crowbar database deployer dns ganglia glance ipmi \
        keystone kong logging mysql nagios network nova \
        nova_dashboard ntp openstack postgresql provisioner \
        swift test
    do
        echo `pwd` $bc
    done
}

me=`basename $0`

usage () {
    # Call as: usage [EXITCODE] [USAGE MESSAGE]
    exit_code=1
    if [[ "$1" == [0-9] ]]; then
        exit_code="$1"
        shift
    fi
    if [ -n "$1" ]; then
        echo "$*" >&2
        echo
    fi

    cat <<EOF >&2
Usage: $me [SUB-BRANCH [LOCAL [UPSTREAM]]]

Compares local branch of crowbar and barclamps repositories with upstream
using 'git cherry -v'.  Commits missing from upstream are prefixed with
a plus (+) symbol, and commits with an equivalent change already upstream
are prefixed with a minus (-) symbol.

Must be run from the top-level crowbar repository.

LOCAL is the local feature "super-branch" to compare [$DEFAULT_LOCAL]
UPSTREAM is the upstream feature "super-branch" to compare [$DEFAULT_UPSTREAM]
SUB-BRANCH is the sub-branch of the crowbar "super-branch" to compare [$DEFAULT_SUB_BRANCH]
EOF
    exit "$exit_code"
}

DEFAULT_SUB_BRANCH=openstack-os-build
DEFAULT_LOCAL=release/essex-hack-suse
DEFAULT_UPSTREAM=origin/release/essex-hack

if [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ $# -gt 3 ]; then
    usage 0
fi


if ! [ -e extra/install-chef.sh ]; then
    echo "You must run this from the top of the crowbar tree; aborting." >&2
    exit 1
fi

local=${2:-$DEFAULT_LOCAL}
upstream=${3:-$DEFAULT_UPSTREAM}

echo -e "\e[0;1mComparing top-level crowbar repo with upstream ...\e[0m"
compare $local $upstream ${1:-$DEFAULT_SUB_BRANCH} 'top-level crowbar repo'

get_barclamps | while read toplevel name; do
    echo -e "\n\e[0;1mComparing $name barclamp with upstream ...\e[0m"
    cd $toplevel/barclamps/$name
    compare $local $upstream master "$name barclamp"
done
