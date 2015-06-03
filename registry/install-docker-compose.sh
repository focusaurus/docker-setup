#!/bin/bash
set -o errexit    # always exit on error
set -o errtrace   # trap errors in functions as well
set -o pipefail   # don"t ignore exit codes when piping output
set -o posix      # more strict failures in subshells
# set -x          # enable debugging

IFS="$(printf "\n\t")"
destination=/usr/local/bin/docker-compose
curl \
  --write-out "${destination}" \
  "https://github.com/docker/compose/releases/download/1.1.0/docker-compose-$(uname  -s)-$(uname -m)"
chmod +x "${destination}"
