*This project has been created as part of the 42 curriculum by ludoviKZ.*
# User documentation

## What is provided?

The infrastructure exposes one HTTPS website. NGINX terminates TLS and forwards
PHP requests to WordPress. WordPress provides the site and `/wp-admin/`, while
MariaDB stores its content and account data. MariaDB and PHP-FPM are private;
only NGINX publishes port 443.

## Start and stop

From the repository root:

```sh
make
make ps
make stop
make start
make down
```

`make down` removes containers but keeps named volumes. Do not use `make fclean`
unless deleting all WordPress and database data is intended.

## Access

Visit `https://lzorzit.42.fr/`. The administration panel is
`https://lzorzit.42.fr/wp-admin/`.

If the hostname does not resolve, add the VM address to `/etc/hosts`, for example:

```text
192.168.56.10 lzorzit.42.fr
```

## Credentials

Passwords are stored locally in the ignored `secrets/` directory:

* `db_root_password.txt`: MariaDB root password.
* `db_password.txt`: WordPress database user's password.
* `wp_admin_password.txt`: WordPress administrator password.

The administrator username is `site_owner`, deliberately avoiding the forbidden
`admin` naming. Change credentials by editing the files and recreating the
database volume; existing MariaDB accounts are not overwritten on restart.

## Health checks and troubleshooting

```sh
make ps
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb
curl -kI https://lzorzit.42.fr/
```

All three containers should be `running`. If the site returns `502`, inspect the
WordPress and NGINX logs and confirm that `wordpress:9000` is reachable on the
private network.
