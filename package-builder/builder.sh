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
    echo "src-link ${CUSTOM_FEED} file://${PATH_FEEDS}/${CUSTOM_FEED}" >> $PATH_SRC/feeds.conf
done;

./scripts/feeds update -a
for CUSTOM_FEED in $CUSTOM_FEEDS; do
    ./scripts/feeds install -a -p $CUSTOM_FEED
done;

make defconfig
echo "- Building packages $PACKAGES..."

COMMANDS=""
[ "$CLEAN" != "0" ] && {
  for PACKAGE in $PACKAGES; do
    COMMANDS="$COMMANDS package/${PACKAGE}/clean"
  done
}
for PACKAGE in $PACKAGES; do
  COMMANDS="$COMMANDS package/${PACKAGE}/download"
}
for PACKAGE in $PACKAGES; do
  COMMANDS="$COMMANDS package/${PACKAGE}/compile"
}

make -j ${CPUS} ${COMMANDS} \
  BIN_DIR="$PATH_OUTPUT"

# Move bin/packages contents to the PATH_OUTPUT
echo "- Moving built packages to output dir..."
mv -v bin/packages/* $PATH_OUTPUT