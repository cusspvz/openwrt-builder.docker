#!/bin/bash

DOCKER_USE_SUDO=${DOCKER_USE_SUDO:-0}
DOCKER_USERNAME=${DOCKER_USERNAME:-cusspvz}
DOCKER_PASSWORD=${DOCKER_PASSWORD}
DOCKER_IMAGE=${DOCKER_IMAGE:-$DOCKER_USERNAME/openwrt-builder}

DOCKER="${DOCKER:-docker}"

CLOSE_EXEC="/dev/null"
# CLOSE_EXEC=">/dev/null 2>&1"
if [ ! -z DEBUG ]; then
  CLOSE_EXEC="/dev/null"
fi

function safeexit () {
  echo "$1"
  [ ! -z $2 ] && exit $2 || exit 0
}

if [ -z $DOCKER_USERNAME ] || [ -z $DOCKER_PASSWORD ]; then
  safeexit "Please make sure that you've specified the DOCKER_USERNAME and DOCKER_PASSWORD envs" 1
fi


if [ "$DOCKER_USE_SUDO" != "0" ]; then
  DOCKER="sudo ${DOCKER}"
fi

function docker_tag_exists() {
  curl --silent -f -lSL https://index.docker.io/v1/repositories/$1/tags/$2 &>$CLOSE_EXEC;
}

function generate_dockerfile_based_on() {
  echo "FROM $1:base"
  cat $2
}

# MAIN - this is where it starts

echo "BASE - Building/Fetching base image"

# Lets pull up the base image
$DOCKER pull "$DOCKER_IMAGE:base" &>$CLOSE_EXEC;

# Now that we have it in cache, lets build the base image to ensure
# that it has the same output
$DOCKER build -t "$DOCKER_IMAGE:base" ./base-image &>$CLOSE_EXEC;

# Push the docker base in case it gets changed
$DOCKER push "$DOCKER_IMAGE:base" &>$CLOSE_EXEC;

# Now it's time to do the same
for VERSION in $(ls targets/); do
for TARGET in $(ls targets/${VERSION}/); do
  echo "${VERSION} ${TARGET} - Loading up target configs"
  eval "$(cat targets/${VERSION}/${TARGET})"

  DOCKER_PACKAGE_BUILDER_TAG="package-builder_${VERSION}_${TARGET}"
  DOCKER_IMAGE_BUILDER_TAG="image-builder_${VERSION}_${TARGET}"

  # Handle Package builder
  if docker_tag_exists "$DOCKER_IMAGE" "$DOCKER_PACKAGE_BUILDER_TAG"; then
    echo "${VERSION} ${TARGET} - Package Builder already exists"
  else
    echo "${VERSION} ${TARGET} - Building Package Builder ..."
    generate_dockerfile_based_on $DOCKER_IMAGE ./package-builder/Dockerfile | $DOCKER build -f - -t "$DOCKER_IMAGE:$DOCKER_PACKAGE_BUILDER_TAG" ./package-builder &>$CLOSE_EXEC;

    echo "${VERSION} ${TARGET} - Pushing Package Builder ..."
    $DOCKER push "$DOCKER_IMAGE:$DOCKER_PACKAGE_BUILDER_TAG" &>$CLOSE_EXEC;
  fi

  # Handle Image builder
  if docker_tag_exists "$DOCKER_IMAGE" "$DOCKER_IMAGE_BUILDER_TAG"; then
    echo "${VERSION} ${TARGET} - Image Builder already exists"
  else
    echo "${VERSION} ${TARGET} - Building Image Builder ..."
    generate_dockerfile_based_on $DOCKER_IMAGE ./image-builder/Dockerfile | $DOCKER build -f - -t "$DOCKER_IMAGE:$DOCKER_IMAGE_BUILDER_TAG" ./image-builder &>$CLOSE_EXEC;

    echo "${VERSION} ${TARGET} - Pushing Image Builder ..."
    $DOCKER push "$DOCKER_IMAGE:$DOCKER_IMAGE_BUILDER_TAG" &>$CLOSE_EXEC;
  fi

done;
done;

echo "Builder is now going to rest ..."
