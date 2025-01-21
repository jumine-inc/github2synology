#!/bin/sh
# A script to backup Github repositories to a Synology.
# By Richard Bairwell. http://www.bairwell.com
# MIT Licenced. https://github.com/bairwell/github2synology

# token from https://github.com/settings/tokens
OAUTH_TOKEN="[PUT YOUR TOKEN HERE BETWEEN THE QUOTES]"
# where should the files be saved
BACKUP_PATH="/volume1/Github-backup/backup-files"
ORG_NAME="jumine-inc"

# you shouldn't need to change anything below here - unless you have over 100 repos: in which case, see the bottom.
COUNTER=100
TOTALCOUNTER=0
PAGE=1
GIT="c//volume1/@appstore/git/bin/git"
fetch_fromUrl() {
	COUNTER=0
    API_URL="https://api.github.com/orgs/${ORG_NAME}/repos?type=all&per_page=100&page=${PAGE}"
    echo "Fetching from ${API_URL}"
    REPOS=`curl -H "Authorization: token ${OAUTH_TOKEN}" -s "${API_URL}" | jq -r 'values[] | "\(.full_name),\(.private),\(.git_url)"'`
    for REPO in $REPOS
    do
        let COUNTER++
        let TOTALCOUNTER++
        REPONAME=`echo ${REPO} | cut -d ',' -f1`
        PRIVATEFLAG=`echo ${REPO} | cut -d ',' -f2`
        ORIGINALGITURL=`echo ${REPO} | cut -d ',' -f3`
        GITURL="${ORIGINALGITURL/git:\/\/github.com\//git@github.com:}"
        mkdir "${BACKUP_PATH}/${REPONAME}" -p
        REPOPATH="${BACKUP_PATH}/${REPONAME}/code"
        if [ -d "$REPOPATH" ]; then
            echo "PULLING Repo URL: ${REPONAME} from url ${GITURL} to ${REPOPATH}"
            cd ${REPOPATH}
            ${GIT} pull
        else
            echo "CLONING Repo URL: ${REPONAME} from url ${GITURL} to ${REPOPATH}"
            ${GIT} clone ${GITURL} ${REPOPATH}
            if [ "true"===${PRIVATEFLAG} ]; then
                `touch ${BACKUP_PATH}/${REPONAME}/private`
            fi
        fi
    done
}
until [ $COUNTER -lt 100 ]; do
    fetch_fromUrl
    let PAGE++
done
echo $((TOTALCOUNTER)) repositories updated