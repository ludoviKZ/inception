FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY tools/init-db.sh /usr/local/bin/init-db.sh
RUN chmod 755 /usr/local/bin/init-db.sh

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
