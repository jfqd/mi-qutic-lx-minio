# Default
TLS_HOME='/data/.minio/certs'

# Create folder if it doesn't exists
mkdir -p "${TLS_HOME}"
chmod 0750 "${TLS_HOME}"

# Use user certificate if provided
if mdata-get minio_tls 1>/dev/null 2>&1; then
  (
  umask 0077
  mdata-get nginx_ssl > "${TLS_HOME}/minio.pem"
  # Split files for nginx usage
  openssl pkey -in "${TLS_HOME}/minio.pem" -out "${TLS_HOME}/private.key"
  openssl crl2pkcs7 -nocrl -certfile "${TLS_HOME}/minio.pem" | \
    openssl pkcs7 -print_certs -out "${TLS_HOME}/public.crt"
  )
  chmod 0640 "${TLS_HOME}"/*
else
  /usr/local/bin/tls-selfsigned.sh -d ${TLS_HOME} -f minio
  mv "${TLS_HOME}/minio.key" "${TLS_HOME}/private.key"
  mv "${TLS_HOME}/minio.crt" "${TLS_HOME}/public.crt"
fi
