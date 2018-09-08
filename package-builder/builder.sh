#!/bin/bash

PATH_SRC=/src
PATH_FEEDS=/feeds
CUSTOM_FEEDS=$(ls $PATH_FEEDS)
CPUS=${CPUS:-2}
CLEAN=${CLEAN:-0}

## Verify if we have packages to build
[ -z "$PACKAGES" ] && {
    echo "Please provide a list of packages for us to build"
    exit 1
}

## HANDLE FEEDS
cp $PATH_SRC/feeds.conf.default $PATH_SRC/feeds.conf
for CUSTOM_FEED in $CUSTOM_FEEDS; do
    echo "src-link ${CUSTOM_FEED} ${PATH_FEEDS}/${CUSTOM_FEED}" >> $PATH_SRC/feeds.conf
done;

./scripts/feeds update -a
for CUSTOM_FEED in $CUSTOM_FEEDS; do
    ./scripts/feeds install -a -p $CUSTOM_FEED
done;

make defconfig

for PACKAGE in $PACKAGES; do
    [ "$CLEAN" != "0" ] && {
        make package/${PACKAGE}/clean
    }

    make package/${PACKAGE}/compile
done
