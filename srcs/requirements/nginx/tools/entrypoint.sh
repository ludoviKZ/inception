#!/bin/sh
set -eu

mkdir -p /etc/nginx/ssl
cp /run/secrets/tls_crt /etc/nginx/ssl/tls.crt
cp /run/secrets/tls_key /etc/nginx/ssl/tls.key
chmod 600 /etc/nginx/ssl/tls.key

exec nginx -g 'daemon off;'
