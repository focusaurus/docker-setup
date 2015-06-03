#!/bin/bash
set -o errexit    # always exit on error
set -o errtrace   # trap errors in functions as well
set -o pipefail   # don"t ignore exit codes when piping output
set -o posix      # more strict failures in subshells
# set -x          # enable debugging

IFS="$(printf "\n\t")"
if [[ -x /usr/bin/docker ]]; then
  version=$(/usr/bin/docker --version)
  if [[ $? -eq 0 ]]; then
    echo "✓ docker version ${version} is already installed."
    exit 0
  fi
fi

echo "installing docker…"
apt-get --quiet --assume-yes update
apt-get --quiet --assume-yes install curl
curl --silent --location --fail https://get.docker.com/ | sh
