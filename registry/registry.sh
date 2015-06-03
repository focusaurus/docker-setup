#!/bin/bash
set -o errexit    # always exit on error
set -o errtrace   # trap errors in functions as well
set -o pipefail   # don"t ignore exit codes when piping output
set -o posix      # more strict failures in subshells
# set -x          # enable debugging

IFS="$(printf "\n\t")"

hostname="$1"

if [[ -z "${hostname}" ]]; then
  echo "Usage $0 <hostname>" 1>&2
  exit 1
fi

cd /tmp
if [[ -e ./distribution ]]; then
  rm -rf ./distribution
fi

git clone https://github.com/docker/distribution.git
cd distribution
git checkout v2.0.1
mkdir certs
project="docker-registry"
cat <<EOF > "./openssl.config"
[req]
prompt=no
distinguished_name=${project}

[${project}]
C=US
ST=Colorado
O=${project}
OU=${project}
CN=${hostname}
EOF
openssl req \
  -newkey rsa:2048 \
  -nodes \
  -keyout certs/domain.key \
  -x509 \
  -days 365 \
  -out certs/domain.crt \
  -config ./openssl.config

cat <<EOF > ./cmd/registry/config.yml
version: 0.1
log:
  level: debug
  fields:
    service: registry
    environment: development
storage:
    cache:
        blobdescriptor: redis
    filesystem:
        rootdirectory: /tmp/registry-dev
    maintenance:
        uploadpurging:
            enabled: false
http:
    addr: :5000
    secret: RfWZtyba6gqFD9
    debug:
        addr: localhost:5001
    tls:
      certificate: /go/src/github.com/docker/distribution/certs/domain.crt
      key: /go/src/github.com/docker/distribution/certs/domain.key
redis:
  addr: localhost:6379
  pool:
    maxidle: 16
    maxactive: 64
    idletimeout: 300s
  dialtimeout: 10ms
  readtimeout: 10ms
  writetimeout: 10ms
notifications:
    endpoints:
        - name: local-8082
          url: http://localhost:5003/callback
          headers:
             Authorization: [Bearer <an example token>]
          timeout: 1s
          threshold: 10
          backoff: 1s
          disabled: true
        - name: local-8083
          url: http://localhost:8083/callback
          timeout: 1s
          threshold: 10
          backoff: 1s
          disabled: true
EOF
docker build -t secure_registry .

docker run \
  --name=secure_registry \
  --publish=5000:5000 \
  --detach \
  --restart=always \
  secure_registry:latest
