#!/bin/bash

DOCKER_USE_SUDO=${DOCKER_USE_SUDO:-0}
DOCKER_USERNAME=${DOCKER_USERNAME:-cusspvz}
DOCKER_PASSWORD=${DOCKER_PASSWORD}
DOCKER_IMAGE=${DOCKER_IMAGE:-$DOCKER_USERNAME/openwrt-builder}

DOCKER="${DOCKER:-docker}"

FORCE=${FORCE:-0}
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
  [ "$FORCE" != "0" ] && return 1;
  curl --silent -f -lSL https://index.docker.io/v1/repositories/$1/tags/$2;
}

function generate_dockerfile_from() {
  echo "FROM $1"

  # Print the Dockerfile, but without the FROM header
  cat $2 | grep -v ^FROM
}

# MAIN - this is where it starts

echo "BASE - Building/Fetching base image"

# Lets pull up the base image
$DOCKER pull "${DOCKER_IMAGE}:base";

# Now that we have it in cache, lets build the base image to ensure
# that it has the same output
$DOCKER build -t "${DOCKER_IMAGE}:base" ./base-image;

# Push the docker base in case it gets changed
$DOCKER push "${DOCKER_IMAGE}:base";

# Now it's time to do the same
for VERSION in $(ls targets/); do
for TARGET in $(ls targets/${VERSION}/); do
  echo "${VERSION} ${TARGET} - Loading up target configs"
  source targets/${VERSION}/${TARGET}

  DOCKER_PACKAGE_BUILDER_TAG="package-builder_${VERSION}_${TARGET}"
  DOCKER_IMAGE_BUILDER_TAG="image-builder_${VERSION}_${TARGET}"

  # Handle Package builder
  if docker_tag_exists "${DOCKER_IMAGE}" "${DOCKER_PACKAGE_BUILDER_TAG}"; then
    echo "${VERSION} ${TARGET} - Package Builder already exists"
  else
    echo "${VERSION} ${TARGET} - Building Package Builder ..."
    generate_dockerfile_from "${DOCKER_IMAGE}:base" ./package-builder/Dockerfile | \
      $DOCKER build \
        -f - \
        --build-arg INSTALL_SRC="$INSTALL_PACKAGE_BUILDER" \
        -t "${DOCKER_IMAGE}:${DOCKER_PACKAGE_BUILDER_TAG}" \
        ./package-builder;

    echo "${VERSION} ${TARGET} - Pushing Package Builder ..."
    $DOCKER push "${DOCKER_IMAGE}:${DOCKER_PACKAGE_BUILDER_TAG}";
  fi

  # Handle Image builder
  if docker_tag_exists "${DOCKER_IMAGE}" "${DOCKER_IMAGE_BUILDER_TAG}"; then
    echo "${VERSION} ${TARGET} - Image Builder already exists"
  else
    echo "${VERSION} ${TARGET} - Building Image Builder ..."
    generate_dockerfile_from "${DOCKER_IMAGE}:base" ./image-builder/Dockerfile | \
      $DOCKER build \
        -f - \
        --build-arg INSTALL_SRC="$INSTALL_IMAGE_BUILDER" \
        -t "${DOCKER_IMAGE}:${DOCKER_IMAGE_BUILDER_TAG}" \
        ./image-builder;

    echo "${VERSION} ${TARGET} - Pushing Image Builder ..."
    $DOCKER push "${DOCKER_IMAGE}:${DOCKER_IMAGE_BUILDER_TAG}";
  fi

done;
done;

echo "Builder is now going to rest ..."
