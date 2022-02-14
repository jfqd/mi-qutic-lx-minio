#!/bin/bash

if /native/usr/sbin/mdata-get minio_access_key 1>/dev/null 2>&1; then
  MINIO_UID=$(/native/usr/sbin/mdata-get minio_access_key)
else
  MINIO_UID="minio-admin"
fi

if /native/usr/sbin/mdata-get minio_secret_key 1>/dev/null 2>&1; then
  MINIO_PWD=$(/native/usr/sbin/mdata-get minio_secret_key)
else
  MINIO_PWD=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c24)
fi

if /native/usr/sbin/mdata-get minio_storage_path 1>/dev/null 2>&1; then
  MINIO_STORAGE=$(/native/usr/sbin/mdata-get minio_storage_path)
else
  MINIO_STORAGE="/data"
fi

# use new data folder (filesystem or delegate)
if [[ ! -d "${MINIO_STORAGE}" ]]; then
  mkdir "${MINIO_STORAGE}"
fi

echo "* Setup minio user"
addgroup minio
adduser --disabled-password --system --quiet --home "${MINIO_STORAGE}" --shell /bin/bash minio
adduser minio minio
chown -R minio:minio "${MINIO_STORAGE}"

echo "* Setup minio config"
cat >> /etc/default/minio  << EOF
MINIO_VOLUMES="${MINIO_STORAGE}"
MINIO_OPTS="--address :9000 -console-address :8080"
MINIO_ROOT_USER=${MINIO_UID}
MINIO_ROOT_PASSWORD=${MINIO_PWD}

EOF

echo "* Setup minio service"
cp /usr/local/var/tmp/minio_service /etc/systemd/system/minio.service

sed -i \
    "s#WorkingDirectory=/usr/local/#WorkingDirectory=${MINIO_STORAGE}#" \
    /etc/systemd/system/minio.service

systemctl daemon-reload
systemctl start minio

echo "* Cleanup"
rm -rf /usr/local/var/tmp/
