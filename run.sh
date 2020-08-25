#!/bin/bash -e

# This mirrors updates.jenkins-ci.org
# but gets only what that is needed
# and only the latest versions of the plugins
# with the latest .war file of the jenkins (not sure even needed)
# not mirroring blindly since their server is super slow
# and no reason to have older versions

URL=http://updates.jenkins-ci.org
DIR=$(basename $URL)
JOBS=$((`nproc` * 2))
WGET_FLAGS="-c -e robots=off -U mozilla -N -x"

function wget_ls
{
    local SITE=$1
    wget -O- $SITE 2>/dev/null | grep -Po '(?<=href=")[^/;=]+(?=")' | xargs -n1 -I% echo $SITE/%	
}

(
    # wget_ls $URL - They've changed it so can't list dir
    echo $URL/latestCore.txt
    echo $URL/plugin-documentation-urls.json
    echo $URL/plugin-versions.json
    echo $URL/release-history.json
    echo $URL/update-center.actual.json
    echo $URL/update-center.json
    echo $URL/update-center.json.html
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
