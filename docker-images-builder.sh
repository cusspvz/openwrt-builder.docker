#!/bin/bash

### BEGIN - HELPERS ###
function safeexit() {
  echo "$1" && [ ! -z $2 ] && exit $2 || exit 0
}

function docker_tag_exists() {
  [ ! -z $FORCE ] && return 1;
  curl --silent -f -lSL "https://index.docker.io/v1/repositories/${1}/tags/${2}" &> $CLOSE_EXEC;
}

function generate_dockerfile_from() {
  echo "FROM $1"

  # Print the Dockerfile, but without the FROM header
  cat $2 | grep -v ^FROM
}

function should_build_target () {
  [ -z $TARGETS ] && return 0;

  # lets compare the targets
  for x in $TARGETS; do
    # If it was specified to be built, lets return true (0)
    if [ "$x" == "$1" ]; then
      return 0
    fi;
  done;

  # we haven't found a match, return falsy (1)
  return 1
}
### END - HELPERS ###


### BEGIN - VARIABLES ###
DOCKER_USE_SUDO=${DOCKER_USE_SUDO:-0}
DOCKER_USERNAME=${DOCKER_USERNAME:-cusspvz}
DOCKER_IMAGE=${DOCKER_IMAGE:-$DOCKER_USERNAME/openwrt-builder}
DOCKER="${DOCKER:-docker}"
FORCE="${FORCE}"
CLOSE_EXEC="/dev/null"
[ ! -z $VERBOSIFY ] && CLOSE_EXEC=`tty`
### END - ARIABLES ###

### BEGIN - VALIDATION ###
if [ -z $DOCKER_USERNAME ]; then
  safeexit "Please make sure that you've specified the DOCKER_USERNAME env" 1
fi

if [ "$DOCKER_USE_SUDO" != "0" ]; then
  DOCKER="sudo ${DOCKER}"
fi
### END - VALIDATION ###

### BEGIN - SPIT CONFIGS ###
echo "########################################"
echo "##  CONFIGS                           ##"
echo "########################################"
echo "# TARGETS: $TARGETS"
echo "# DOCKER: $DOCKER"
echo "# VERBOSIFY: $([ -z $VERBOSIFY ] && echo "No" || echo "Yes")"
echo "# FORCE: $([ -z $FORCE ] && echo "No" || echo "Yes")"
echo
echo
### END - SPIT CONFIGS ###

### BEGIN - BASE IMAGE BUILDING ###
echo "BASE - Building/Fetching base image"

# Lets pull up the base image
$DOCKER pull "${DOCKER_IMAGE}:base" &> $CLOSE_EXEC;

# Now that we have it in cache, lets build the base image to ensure
# that it has the same output
$DOCKER build -t "${DOCKER_IMAGE}:base" ./base-image &> $CLOSE_EXEC;

# Push the docker base in case it gets changed
$DOCKER push "${DOCKER_IMAGE}:base" &> $CLOSE_EXEC;
### END - BASE IMAGE BUILDING ###

### BEGIN - TARGETS PER VERSION BUILDING ###
for VERSION in $(ls targets/); do
for TARGET in $(ls targets/${VERSION}/); do

  # Check if we should build this target
  if ! should_build_target "${VERSION}_${TARGET}"; then
    echo "${VERSION} ${TARGET} X Skipping this build..."
    continue
  else
    echo "${VERSION} ${TARGET} > Starting build ..."
  fi

  echo "${VERSION} ${TARGET} -> Loading up target configs"
  source targets/${VERSION}/${TARGET}

  DOCKER_PACKAGE_BUILDER_TAG="package-builder_${VERSION}_${TARGET}"
  DOCKER_IMAGE_BUILDER_TAG="image-builder_${VERSION}_${TARGET}"

  # Handle Package builder
  if docker_tag_exists "${DOCKER_IMAGE}" "${DOCKER_PACKAGE_BUILDER_TAG}"; then
    echo "${VERSION} ${TARGET} -> Package Builder already exists"
  else
    echo "${VERSION} ${TARGET} -> Building Package Builder ..."
    generate_dockerfile_from "${DOCKER_IMAGE}:base" ./package-builder/Dockerfile | \
      $DOCKER build \
        -f - \
        --build-arg INSTALL_SRC="$INSTALL_PACKAGE_BUILDER" \
        -t "${DOCKER_IMAGE}:${DOCKER_PACKAGE_BUILDER_TAG}" \
        ./package-builder &> $CLOSE_EXEC \
      || safeexit "${VERSION} ${TARGET} -X Error Building Package Builder" 2;

    echo "${VERSION} ${TARGET} -> Pushing Package Builder ..."
    $DOCKER push "${DOCKER_IMAGE}:${DOCKER_PACKAGE_BUILDER_TAG}" &> $CLOSE_EXEC;
  fi

  # Handle Image builder
  if docker_tag_exists "${DOCKER_IMAGE}" "${DOCKER_IMAGE_BUILDER_TAG}"; then
    echo "${VERSION} ${TARGET} -> Image Builder already exists"
  else
    echo "${VERSION} ${TARGET} -> Building Image Builder ..."
    generate_dockerfile_from "${DOCKER_IMAGE}:base" ./image-builder/Dockerfile | \
      $DOCKER build \
        -f - \
        --build-arg INSTALL_SRC="$INSTALL_IMAGE_BUILDER" \
        -t "${DOCKER_IMAGE}:${DOCKER_IMAGE_BUILDER_TAG}" \
        ./image-builder &> $CLOSE_EXEC \
      || safeexit "${VERSION} ${TARGET} -X Error Building Image Builder" 2;

    echo "${VERSION} ${TARGET} -> Pushing Image Builder ..."
    $DOCKER push "${DOCKER_IMAGE}:${DOCKER_IMAGE_BUILDER_TAG}" &> $CLOSE_EXEC;
  fi

done;
done;
### END - TARGETS PER VERSION BUILDING ###

echo "Builder is now going to rest ..."
