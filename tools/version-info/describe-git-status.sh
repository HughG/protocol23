#!/bin/sh

# Echo a single line describing the state of the working copy.
#
# $1 should be the path to git
# $2 should be the output filename

VERSION_INFO=`$1 rev-parse --verify HEAD`
if ! $1 diff-index --quiet HEAD; then
    VERSION_INFO=$VERSION_INFO", plus uncommitted changes"
fi
if $1 ls-files --others --exclude-standard --error-unmatch "./`$1 rev-parse --show-cdup`" >/dev/null 2>&1; then
    VERSION_INFO=$VERSION_INFO", plus untracked files"
fi
echo $VERSION_INFO >$2
