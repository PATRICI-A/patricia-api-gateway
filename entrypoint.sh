#!/bin/sh
envsubst < /usr/local/kong/declarative/kong.yml.template > /usr/local/kong/declarative/kong.yml
echo "=== PATRICIA API Gateway URLs ==="
grep "url:" /usr/local/kong/declarative/kong.yml
exec /docker-entrypoint.sh kong docker-start
