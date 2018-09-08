# OpenWRT Docker Builder

Docker images for building packages and firmware images

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

### OpenWRT Image/Firmware Builder

The Image Builder allows developers to build an Image/Firmware to deploy on
their devices without having to build all the packages from scratch.
This allows Continuous Delivery systems to be much more eficients since it is
just installing packages into newly file-systems.

## Why?

I've build this because of disadvantages that I found on not having this:

1. Setup - It takes some time to setup. And on Docker-based CI environments, 
in case things aren't cleared properly, it introduces errors in between of
build iterations. 

2. Disk usage - A full setup for a target really takes a lot of space. It's
better to have some setup where we have ephemeral changes between the build
iterations, but only if we can cache the initial setup. (which we can by
using docker)

## Architecture

### Base image
`cusspvz/openwrt-builder:base`

We have a base image where all the other images are based from. This image is
based on Debian and includes all the needed tools to the OpenWRT Builders.

### OpenWRT Package Builder
`cusspvz/openwrt-builder:package-builder_VERSION_TARGET[_SUBTARGET]`

Examples: `cusspvz/openwrt-builder:package-builder_18.0.1_brcm2708-bcm2710`
Examples: `cusspvz/openwrt-builder:package-builder_17.01.6_brcm2708-bcm2710`


### OpenWRT Image/Firmware Builder
`cusspvz/openwrt-builder:image-builder_VERSION_TARGET[_SUBTARGET]`

Examples: `cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-bcm2710`
Examples: `cusspvz/openwrt-builder:image-builder_17.01.6_brcm2708-bcm2710`

#### Docker Container folders:
`/src` - Builder Source
`/feeds` - folder to link custom feeds. The image detects mounted folders
automatically, so there's no need to tell us which feeds you want to build.
`/overlay` - folder with files and folders to overlay on the images root
`/output` - folder to output built images 

## Usage

### OpenWRT Package Builder

Builds `.opkg` files and a `Packages.gz`

```bash

docker run -ti --rm \
    -e PACKAGES="transmission openvpn node node-npm" \
    -v /path/to/custom-packages-feed:/feeds/mypackages:z \
    -v /path/to/output-dir:/output:z \
    cusspvz/openwrt-builder:package-builder_18.0.1_brcm2708-bcm2710

```

### OpenWRT Image/Firmware Builder

Builds all the target's images.

```bash

docker run -ti --rm \
    -e PACKAGES="-luci transmission openvpn node node-npm" \
    -e CUSTOM_FEEDS="mypackages" \
    -v /path/to/custom-packages-feed:/feeds/mypackages:z \
    -v /path/to/overlay-dir:/overlay:z \
    -v /path/to/output-dir:/output:z \
    cusspvz/openwrt-builder:image-builder_18.0.1_brcm2708-bcm2710

```


## Donate

Want to buy me a cup of coffee?

BTC: 3FyTUneEqXrpRyCjmXvH4kdmvg7Tomwc4j
LTC: MFyux9RBvgjy79iQDgtegYMkJbUqiC27i7
ETH: 0xa2b5Be27d03916E48Ae445A48d784B0E3cBD825a
ETC: 0xC4b531135a381d2A91F718249eb33a90f187B231
BTC-CASH: qpyme0065wt6c37jart8dn7fy8ldwua74spr2s7vy0

Thanks


## Credits

Thanks to the user [jandelgado](https://github.com/jandelgado) for his work on the
docker builder and the docker compiler.

This exists thanks to:
- @OpenWRT team on [OpenWRT](https://github.com/openwrt/openwrt)
- @jandelgado on [lede-dockercompiler](https://github.com/jandelgado/lede-dockercompiler)
- @jandelgado on [lede-dockerbuilder](https://github.com/jandelgado/lede-dockerbuilder)

