#!/bin/bash
##### worker/helper functions #####
set_perms() {
  chown root:root "${1}"
  chmod 400 "${1}"
}

dhparam() {
  local OUT="${1-$prefix.dhparam.pem}"
  local LINK="${2-$hostname.dhparam.pem}"
  if [[ -f "${OUT}" ]]; then
    return
  fi
  openssl dhparam -out "${OUT}" 2048
  set_perms "${OUT}"
  ln -nsf "${OUT}" "${LINK}"
}

key() {
  local OUT="${1-$prefix.key}"
  if [[ -f "${OUT}" ]]; then
    return
  fi
  openssl genrsa -out "${OUT}" 2048
  set_perms "${OUT}"
  ln -nsf "${OUT}" "${hostname}.key"
}

csr() {
  local OUT="${1-$prefix.csr}"
  local KEY="${2-$hostname.key}"
  if [[ -f "${OUT}" ]]; then
    return
  fi
  cat <<EOF > "${OUT}.openssl.config"
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
  openssl req -new -nodes -key "${KEY}" -out "${OUT}" \
    -config "${OUT}.openssl.config"
  set_perms "${OUT}"
}

sign() {
  local OUT="${1-$prefix.selfsigned.crt}"
  local KEY="${2-$hostname.key}"
  local CSR="${3-$prefix.csr}"
  local LINK="${4-$hostname.crt}"
  if [[ -f "${OUT}" ]]; then
    return
  fi
  openssl x509 -req -days 365 -in "${CSR}" -signkey "${KEY}" -out "${OUT}"
  set_perms "${OUT}"
  ln -nsf "${OUT}" "${LINK}"
}

main() {
  set -o errexit    # always exit on error
  set -o errtrace   # trap errors in functions as well
  set -o pipefail   # don"t ignore exit codes when piping output
  set -o posix      # more strict failures in subshells
  # set -x          # enable debugging
  IFS="$(printf "\n\t")"
  PATH=/usr/bin:/bin:$PATH
  hostname="${1-example.com}"
  project=docker-registry
  output_dir="${2-/etc/nginx/sites-available}"
  year=$(date +%Y)
  prefix="${hostname}-${year}"

  if [[ -e "${output_dir}/${prefix}.crt" ]]; then
    #already exists. Exit without doing anything
    exit
  fi
  cd "${output_dir}"
  dhparam
  key
  csr
  sign
}

main "$@"
