#!/bin/bash
set -o errexit    # always exit on error
set -o errtrace   # trap errors in functions as well
set -o pipefail   # don"t ignore exit codes when piping output
set -o posix      # more strict failures in subshells
# set -x          # enable debugging

IFS="$(printf "\n\t")"

cd /tmp
if [[ -e ./distribution ]]; then
  rm -rf ./distribution
fi

git clone https://github.com/docker/distribution.git
cd distribution
git checkout 1f015478a035c68982843754d1442baad76f3cf0
cd contrib/compose/nginx
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
CN=localhost
EOF

openssl req \
  -newkey rsa:2048 \
  -nodes \
  -keyout domain.key \
  -x509 \
  -days 365 \
  -out domain.crt \
  -config ./openssl.config

#Keep this file handy since you'll need it to connect with curl or docker
cp domain.crt /etc/ssl/certs/docker-registry.crt.pem
cat <<EOF >> Dockerfile
COPY domain.crt /etc/nginx/domain.crt
COPY domain.key /etc/nginx/domain.key
EOF

cat <<EOF > registry.conf
# Docker registry proxy for api versions 1 and 2

upstream docker-registry {
  server registryv1:5000;
}

upstream docker-registry-v2 {
  server registryv2:5000;
}

# No client auth or TLS
server {
  listen 5000;
  ssl on;
  ssl_certificate /etc/nginx/domain.crt;
  ssl_certificate_key /etc/nginx/domain.key;
  server_name localhost;
  charset utf-8;
  #https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_Ciphersuite
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK';
  ssl_session_timeout 5m;
  ssl_protocols TLSv1.2 TLSv1.1 TLSV1;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:50m;
  # disable any limits to avoid HTTP 413 for large image uploads
  client_max_body_size 0;

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
  chunked_transfer_encoding on;

  location /v2/ {
    # Do not allow connections from docker 1.5 and earlier
    # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
    if (\$http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*\$" ) {
      return 404;
    }

    # The docker client expects this header from the /v2/ endpoint.
    add_header 'Docker-Distribution-Api-Version:' 'registry/2.0' always;
    include               docker-registry-v2.conf;
  }

  location / {
    include               docker-registry.conf;
  }
}
EOF

cd ..
docker pull registry:0.9.1
docker-compose build
docker-compose up -d
