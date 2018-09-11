#!/bin/bash

PATH_SRC=/src
PATH_FEEDS=/feeds
PATH_OUTPUT=/output
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

for PACKAGE in $PACKAGES; do
  ./scripts/feeds install "$PACKAGE"
done;

make defconfig
echo "- Building packages: $PACKAGES"

MAKE="make"

[ ! -z $DEBUG ] && {
  MAKE="$MAKE V=s"
}

# Add CPUs
MAKE="$MAKE -j${CPUS}"

for PACKAGE in $PACKAGES; do
  $MAKE package/${PACKAGE}/compile
done;

echo "Building repository Packages"
$MAKE package/index
cp -vfR $PATH_SRC/bin/* /output

# Move bin/packages contents to the PATH_OUTPUT
# for package in $(find $PATH_SRC/bin | grep ".ipk$"); do
#   cp "$package" /output;
# done;

# Build packages.gz
# export PATH="$PATH:$PATH_SRC/staging_dir/host/bin/"
# cd $PATH_OUTPUT
# $PATH_SRC/scripts/ipkg-make-index.sh . > Packages
# gzip --keep Packages

echo "Finished!"
