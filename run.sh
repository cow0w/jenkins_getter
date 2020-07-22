#!/bin/bash

URL=http://updates.jenkins-ci.org
DIR=$(basename $URL)
JOBS=$((`nproc` * 2))
WGET_FLAGS="-e robots=off -U mozilla -N -x"

function wget_ls
{
    local SITE=$1
    wget -O- $SITE 2>/dev/null | grep -Po '(?<=href=")[^/;=]+(?=")' | xargs -n1 -I% echo $SITE/%	
}

(
    wget_ls $URL
#    wget_ls $URL/current
    wget_ls $URL/updates
) | parallel -j $JOBS --lb wget $WGET_FLAGS {} || exit 1

(
    cd $DIR
    (
        jq '.plugins | .[] | .url' update-center.actual.json -r; \
        jq '.plugins | .[].dependencies | .[] | { v: "http://updates.jenkins-ci.org/download/plugins/\(.name)/\(.version)/\(.name).hpi" } | .v' update-center.actual.json -r; \
        echo $URL/download/war/$(cat latestCore.txt)/jenkins.war;
    ) | sort -u | parallel -j $JOBS --lb wget $WGET_FLAGS -nH {}
) || exit 1
