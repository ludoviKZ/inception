# Developer documentation

## Prerequisites and setup

Use a Linux VM with Docker Engine, Docker Compose v2, Make, and OpenSSL. Copy
`srcs/.env.example` to `srcs/.env`, review the values, and create the files
listed in the README under `secrets/`. The `.env` and secret files are ignored
by Git and must never be committed.

The compose file reads non-sensitive configuration from `.env` and mounts
passwords and TLS material as read-only Docker secrets.

## Build and launch

```sh
make build
make up
make ps
make logs
```

`make up` builds all three Dockerfiles and starts the services in dependency
order. `docker compose config` is useful for checking interpolation before a
build:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config
```

## Service implementation

* `mariadb/Dockerfile` installs only MariaDB. `init-db.sh` initializes the
  datadir on first boot, creates the WordPress database and two application
  users, then replaces itself with `mariadbd`.
* `wordpress/Dockerfile` installs PHP-FPM and WordPress's required PHP
  extensions. Its entrypoint downloads WordPress only when the volume is empty,
  writes `wp-config.php`, and starts PHP-FPM as PID 1.
* `nginx/Dockerfile` installs NGINX. Its entrypoint copies the mounted TLS
  certificate and key into the expected paths, then starts NGINX in the
  foreground. `nginx.conf` permits TLS 1.2 and 1.3 only.

## Useful operations

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec wordpress sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec mariadb mariadb -u root -p
docker volume ls
docker network inspect inception
```

The two named volumes are configured with bind-backed Docker volume drivers:
`/home/lzorzit/data/wordpress` stores website files and
`/home/lzorzit/data/mariadb` stores the database. Containers can be replaced
without losing either dataset.

## Verification

Run `docker compose ... config --quiet`, inspect `docker compose ps`, and check
the HTTPS response with `curl -kI`. Inside the NGINX container, verify the
enabled protocols with `nginx -T`; only TLS 1.2 and TLS 1.3 appear in the
configuration.
