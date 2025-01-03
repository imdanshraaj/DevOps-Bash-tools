#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-03 10:41:23 +0300 (Thu, 03 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

code="git_commit_times.gnuplot"
data="data/git_commit_times.dat"
image="images/git_commit_times.png"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates a GNUplot graph of Git commit times from the current Git repo checkout's git log

Generates the following files:

    $code - Code

    $data  - Data

    $image - Image

A MermaidJS version of this script is adjacent at:

    git_graph_commit_times_mermaidjs.sh

Requires Git and GNUplot to be installed to generate the graph
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

if ! is_in_git_repo; then
    die "ERROR: must be run from a git repo checkout as it relies on the 'git log' command"
fi

for x in $code \
         $data \
         $image; do
    mkdir -p -v "$(dirname "$x")"
done

git_repo="$(git_repo)"

timestamp "Running inside checkout of Git repo: $git_repo"
timestamp "Fetching Hour of all commits from Git log"
git log --date=format:'%H' --pretty=format:'%ad' |
sort |
uniq -c |
awk '{print $2" "$1}' > "$data"
echo

timestamp "Generating GNUplot code for Commits per Hour"
sed '/^[[:space:]]*$/d' > "$code" <<EOF
#
# Generated by ${0##*/}
#
# from https://github.com/HariSekhon/DevOps-Bash-tools
#
set terminal pngcairo size 1280,720 enhanced font "Arial,14"
set title "$git_repo - Git Commits by Hour"
set xlabel "Hour of Day (author's local time)"
set ylabel "Number of Commits"
set grid
#set xtics rotate by -45
set boxwidth 0.8 relative
set style fill solid
set datafile separator " "
# results in X axis labels every 2 years
#set xdata time
#set timefmt "%H"
#set format x "%H"
# trick to get X axis labels for every year
stats "$data" using 1 nooutput
set xrange [STATS_min:STATS_max]
set xtics 1
set output "$image"
plot "$data" using 1:2 with boxes title 'Commits'
EOF
timestamp "Generated GNUplot code: $code"

timestamp "Generating bar chart for Commits per Hour"
gnuplot "$code"
timestamp "Generated bar chart image: $image"
echo

if is_CI; then
    exit 0
fi

timestamp "Opening: $image"
"$srcdir/../media/imageopen.sh" "$image"
