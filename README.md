# Docker Setup

Scripts to install/configure a docker server and secure private docker registry.

This project is essentially a scripting of the [docker installation instructions for Ubuntu](https://docs.docker.com/installation/ubuntulinux/#installing-docker-on-ubuntu) and the [docker registry installation article](https://docs.docker.com/registry/deploying).

## Supported Platforms

- Ubuntu 14.04 x64 (trusty64)
  - Will probably work on similar Ubuntu or Debian versions too, but it's untested

## How to Install the Setup Scripts

1. Get yourself an Ubuntu server, ssh access and sudo permissions
1. Log into your target server and become root
1. Clone this repo to the target server by copying the contents of `git.sh` and paste into a root shell on the target server.
1. Run ./nginx.sh <hostname>

## How to install docker

1. become root
1. cd into the directory where these scripts are checked out
1. run `./docker/install-docker.sh`
