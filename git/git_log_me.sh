#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-20 14:50:09 +0700 (Thu, 20 Feb 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Shows only commits in the Git log done by you

Useful to remind yourself what parts the current Git repo you've been working on
for periodic reviews, reports or or even updating your CV!

Filters the Git log for your Git configured username and email address

If you have a global Git config using your personal email address but work repo specific overrides using your work email
this script will include to filter for both which will also catch commits that may have been accidentally committed
before you overrode your Git email in work repo or if using Squash Merges in GitHub UI that defaulted to the wrong email
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

authors="$(git config -l | awk -F= '/^user.(name|email)/ {print $2}' | sort -u)"

author_opts=()

while read -r author; do
    author_opts+=(--author "$author")
done <<< "$authors"

git log "${author_opts[@]}"
