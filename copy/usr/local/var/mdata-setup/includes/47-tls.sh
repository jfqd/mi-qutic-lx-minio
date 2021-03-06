#!/usr/bin/bash

TLS_HOME='/etc/nginx/ssl'

# Create folder if it doesn't exists
mkdir -p "${TLS_HOME}"
chmod 0750 "${TLS_HOME}"

if [[ ! -f "${TLS_HOME}/minio.pem" ]]; then
  # Use user certificate if provided
  if mdata-get minio_tls 1>/dev/null 2>&1; then
    (
    umask 0077
    mdata-get nginx_ssl > "${TLS_HOME}/minio.pem"
    # Split files for nginx usage
    openssl pkey -in "${TLS_HOME}/minio.pem" -out "${TLS_HOME}/minio.key"
    openssl crl2pkcs7 -nocrl -certfile "${TLS_HOME}/minio.pem" | \
      openssl pkcs7 -print_certs -out "${TLS_HOME}/minio.crt"
    )
  else
    /usr/local/bin/tls-selfsigned.sh -d ${TLS_HOME} -f minio
  fi
  cp "${TLS_HOME}/minio.key" "/home/minio/.minio/certs/private.key"
  cp "${TLS_HOME}/minio.crt" "/home/minio/.minio/certs/public.crt"
  chmod 0640 "${TLS_HOME}"/*
  chmod 0640 /home/minio/.minio/certs/*
  chown -R minio:minio /home/minio/.minio/certs
  
  systemctl restart nginx || true
fi