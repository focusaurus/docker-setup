#!/bin/bash
set -o errexit    # always exit on error
set -o errtrace   # trap errors in functions as well
set -o pipefail   # don"t ignore exit codes when piping output
set -o posix      # more strict failures in subshells
# set -x          # enable debugging
IFS="$(printf "\n\t")"
cd "$(dirname "$0")"

hostname="$1"
available="/etc/nginx/sites-available"
enabled="/etc/nginx/sites-enabled"
creds="${available}/${hostname}.htpasswd"

if [[ -z "${hostname}" ]]; then
  echo "Usage $0 <hostname>" 1>&2
  exit 1
fi

apt-get --quiet --assume-yes install nginx apache2-utils
install \
  --owner root \
  --group root \
  --mode 600 \
  ./docker-registry.conf "${available}"

if [[ -f "${creds}" ]]; then
  echo "Credentials are already set up"
else
  echo "Setting up credentials"
  htpasswd -c "${creds}" docker-registry
fi

cat <<EOF > "${available}/${hostname}"
upstream docker-registry {
  server localhost:5000;
}

# uncomment if you want a 301 redirect for users attempting to connect
# on port 80
# NOTE: docker client will still fail. This is just for convenience
# server {
#   listen *:80;
#   server_name my.docker.registry.com;
#   return 301 https://$server_name$request_uri;
# }

server {
  listen 443;
  server_name ${hostname};

  ssl on;
  ssl_certificate sites-available/${hostname}.crt;
  ssl_certificate_key sites-available/${hostname}.key;
  charset utf-8;
  ssl_dhparam sites-available/${hostname}.dhparam.pem;
  #https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_Ciphersuite
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK';
  ssl_session_timeout 5m;
  ssl_protocols TLSv1.2 TLSv1.1 TLSV1;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:50m;
  client_max_body_size 0; # disable any limits to avoid HTTP 413 for large image uploads

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
  chunked_transfer_encoding on;

  location / {
    auth_basic            "Restricted";
    auth_basic_user_file  sites-available/${hostname}.htpasswd;
    include               sites-available/docker-registry.conf;
  }

  location /_ping {
    auth_basic off;
    include               sites-available/docker-registry.conf;
  }

  location /v1/_ping {
    auth_basic off;
    include               sites-available/docker-registry.conf;
  }
}
EOF
ln -nsf "${available}/${hostname}" "${enabled}/${hostname}"
if [[ -f "${enabled}/default" ]]; then
  rm "${enabled}/default"
fi
nginx -t
service nginx reload
echo nginx installed and configured
