#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-05-14 05:27:20 +0300 (Wed, 14 May 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Launches tmux and runs the commands given as args in horizontally balanced panes

Fast way to launch a bunch of commands in an easily reviewable way

If there is only one arg which is a single digit integer, then launches that many \$SHELL panes

Autogenerates a new session name in the form of \$PWD-\$epoch for uniqueness

Example:

    ${0##*/} htop 'iostat 1'

    ${0##*/} bash bash

    ${0##*/} 2
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args='"<command_1>" "<command_2>" ["<command_3>" ...]'

help_usage "$@"

min_args 1 "$@"

pwd="${PWD:-$(pwd)}"
epoch="$(date +%s)"

# cannot separate the session name with a dot as this breaks:
#
#   tmux has-session -t "$session"
#
# this command:
#
#   tmux has-session -t /Users/hari/mydir.1747191485
#
# results in this:
#
#   can't find window: /Users/hari/mydir
#
session="$pwd-$epoch"

cmd1="$1"

shift || :

if [ $# -eq 0 ]; then
   if [[ "$cmd1" =~ ^[[:digit:]]$ ]]; then
        shell="${SHELL:-bash}"
        count="$cmd1"
        cmd1="$shell"
        args=()
        for ((i = 1; i < count; i++)); do
            args+=("$shell")
        done
        set -- "${args[@]}"
    else
        usage "Error: two or more args required unless you are specifying a count of shell panes to launch, otherwise there would be no panes to split"
    fi
fi

timestamp "Starting new tmux session in detached mode called '$session' with command: $cmd1"
tmux new-session -d -s "$session" "$cmd1"

if ! tmux has-session -t "$session"; then
    die "ERROR: tmux session exited too soon from first command: $cmd1"
fi

for cmd; do
    timestamp "Splitting the tmux window vertically and launching command: $cmd"
    tmux split-window -h -t "$session":0 "$cmd"
done

timestamp "Balancing the tmux pane layout vertically for tmux session: $session"
tmux select-layout -t "$session":0 even-horizontal

timestamp "Attaching to tmux session: $session"
tmux attach-session -t "$session"
