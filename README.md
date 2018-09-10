![OpenWRT Logo](https://openwrt.org/lib/tpl/openwrt/images/logo.png)

# OpenWRT Docker Package and Firmware Builder
Docker images for building packages and firmware files


## What does it do?

OpenWRT Build System is really huge, and takes a lot of time to build up
things, so in order to make it easier to other Devs to use it, the Build
System outputs two other build systems: the OpenWRT Package Builder and the
OpenWRT Image/Firmware Builder.

### OpenWRT Package Builder 

The Package Builder allows developers to build up a specific set of packages
without having to build the entire packaging system. So this means that the
developers just need to plug-in their Package Feeds and set which packages
are meant to be built.

### OpenWRT Image/Firmware Builder

The Image Builder allows developers to build an Image/Firmware to deploy on
their devices without having to build all the packages from scratch.
This allows Continuous Delivery systems to be much more eficient since it is
just installing packages into lean file-systems.

## Why?

This project was developed this because of disadvantages found on legacy ones:

1. Setup - It takes some time to setup, and on Docker-based CI environments, 
if things aren't cleared properly, error are introduced between build iterations. 

2. Disk usage A full setup for a target takes a lot of space. It's much
more efficient to have a setup where there are ephemeral changes
between build iterations, assuming caching of the initial setup, which
can be achieved using docker.

## Architecture

### Base image
`cusspvz/openwrt-builder:base`

There is a base image from where all the other images are based. This image is
based on Debian and includes all the tools needed for the OpenWRT Builders.

### OpenWRT Package Builder
`cusspvz/openwrt-builder:package-builder_VERSION_TARGET[_SUBTARGET]`

Examples: `cusspvz/openwrt-builder:package-builder_18.0.1_brcm2708-bcm2710`
Examples: `cusspvz/openwrt-builder:package-builder_17.01.6_brcm2708-bcm2710`


### OpenWRT Image/Firmware Builder
`cusspvz/openwrt-builder:image-builder_VERSION_TARGET[_SUBTARGET]`

Examples: `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-bcm2710`
Examples: `cusspvz/openwrt-builder:image-builder_17.01.6_brcm2708-bcm2710`

#### Docker Container folders:
`/src` - Builder Source
`/feeds` - folder to link custom feeds. The image detects mounted folders
automatically, so there's no need to tell which feeds you want to build.
`/overlay` - folder with files and folders to overlay on the images root
`/output` - folder to output built images 

## Usage

### OpenWRT Package Builder

Builds `.opkg` files and a `Packages.gz`

```bash

docker run -ti --rm \
    -e GOSU_USER=`id -u`:`id -g` \
    -e PACKAGES="transmission openvpn node node-npm" \
    -v /path/to/custom-packages-feed:/feeds/mypackages:z \
    -v /path/to/output-dir:/output:z \
    cusspvz/openwrt-builder:package-builder_18.0.1_brcm2708-bcm2710

```

### OpenWRT Image/Firmware Builder

Builds all the target images.

```bash

docker run -ti --rm \
    -e GOSU_USER=`id -u`:`id -g` \
    -e PACKAGES="-luci transmission openvpn node node-npm" \
    -e CUSTOM_FEEDS="mypackages" \
    -v /path/to/custom-packages-feed:/feeds/mypackages:z \
    -v /path/to/overlay-dir:/overlay:z \
    -v /path/to/output-dir:/output:z \
    cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-bcm2710

```

## Available docker tags

### 18.0.1

#### brcm2708-brcm2708
- Image Builder - `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2708`
- Package Builder - `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2708`

##### Compatible Devices:
- Raspberry Pi 1
- Raspberry Pi Zero
- Raspberry Pi Zero W

#### brcm2708-brcm2709
- Image Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2709`
- Package Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2709`

##### Compatible Devices:
- Raspberry Pi 2

#### brcm2708-brcm2710
- Image Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2710`
- Package Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-brcm2710`

##### Compatible Devices:
- Raspberry Pi 3
- Raspberry Pi 3B+

#### omap-generic
- Image Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_omap-generic`
- Package Builder -> `cusspvz/openwrt-builder:image-builder_18.0.1_omap-generic`

##### Compatible Devices:
- BeagleBone Black

## Development

Want to build your own images or help us out?

```
git clone https://github.com/cusspvz/openwrt-builder.docker openwrt-builder
cd openwrt-builder/
DOCKER_USERNAME=yourusername ./docker-images-builder.sh
```

NOTE: The `DOCKER_USERNAME` variable is required so the builder can check which
images are already built and available on the registry. It also sets the image
base.

### `docker-images-builder.sh` Environment Variables

Usage example: `DOCKER_USE_SUDO=1 FORCE=1 ./docker-images-builder.sh`

#### `VERBOSIFY`
Description: Shows all the underlaying command's outputs

Example: `VERBOSIFY=1`

#### `TARGETS`
Description: List of versions and targets that are meant to be built by the
image builder. Each list item should contain each version and target concatened
with an underscore. [ `$VERSION_$TARGET` ]
Default: Defaults to all versions and targets 

Example: `TARGETS="18.0.1_omap-generic 18.0.1_brcm2708-brcm2708"`

#### `FORCE`
Description: This script checks if the images already exists on the registry.
If this environment variable is set, it will always build and push all the 
version's targets.

This should be used whenever there's a change on the base image.

Example: `FORCE=1`

#### `DOCKER_USE_SUDO`
Description: If you need `sudo` to run docker on your system, this should be
set.
Example: `DOCKER_USE_SUDO=1`

#### `DOCKER`
Description: This is needed in case you need to change your docker binary path.
Example: `DOCKER=/path/to/docker`

#### `DOCKER_USERNAME`
Description: Sets the docker username in order to check if the image is already
present on the registry. This also is used to prefix the image name.

#### `DOCKER_IMAGE`
Description: Allows to change the docker image name.
Note: If this needs to be altered, you still have to set `DOCKER_USERNAME` so
the caching check works properly. Unless you're setting `FORCE`.

## Donate

Want to buy me a cup of coffee?

BTC: 3FyTUneEqXrpRyCjmXvH4kdmvg7Tomwc4j

LTC: MFyux9RBvgjy79iQDgtegYMkJbUqiC27i7

ETH: 0xa2b5Be27d03916E48Ae445A48d784B0E3cBD825a

ETC: 0xC4b531135a381d2A91F718249eb33a90f187B231

BTC-CASH: LOL

## Credits

Thanks to [jandelgado](https://github.com/jandelgado) for his work on the
docker builder and the docker compiler.

This exists thanks to:
- @OpenWRT team on [OpenWRT](https://github.com/openwrt/openwrt)
- @jandelgado on [lede-dockercompiler](https://github.com/jandelgado/lede-dockercompiler)
- @jandelgado on [lede-dockerbuilder](https://github.com/jandelgado/lede-dockerbuilder)

## License
