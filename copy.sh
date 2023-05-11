#!/bin/bash
export PAPER=$(pwd)
pushd $PAPER/script/data

REVIEWER=$1

if [ -z $REVIEWER ]; then
    REVIEWER=author
fi

cp $PAPER/../client-script/data/*.stat .
scp ae@amd-server:~/$REVIEWER/client-script/data/*.stat .
popd
