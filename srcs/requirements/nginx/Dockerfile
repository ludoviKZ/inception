FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
RUN chmod 755 /usr/local/bin/nginx-entrypoint.sh

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]
