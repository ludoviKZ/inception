# Inception

## Description

Inception is a small, isolated web infrastructure built with Docker Compose. Its
goal is to teach service decomposition, container networking, persistent storage,
TLS termination, process management, and operational documentation.

The stack contains three custom-built services:

* **NGINX** is the only public entry point and serves HTTPS on port 443.
* **WordPress** runs PHP-FPM and shares website files through a named volume.
* **MariaDB** stores WordPress data in a separate named volume.

The images are built from Debian Bookworm Slim rather than pulled from a
pre-configured application image. The services communicate on a private
Docker bridge network and restart automatically after a crash.

### Design choices

| Topic | Choice in this project |
|---|---|
| Virtual machine vs Docker | A VM emulates a complete machine and has stronger isolation but more overhead. Docker isolates processes using the host kernel, starts faster, and makes each service reproducible. |
| Secrets vs environment variables | Non-sensitive settings such as the domain and database name are in `srcs/.env`. Passwords are Docker secrets mounted as files, so they are not embedded in images or compose environment values. |
| Docker network vs host network | The user-defined bridge network gives services DNS names and private connectivity. Host networking would remove that isolation and expose container ports directly on the host network. |
| Docker volumes vs bind mounts | Named volumes are managed by Docker and persist independently of containers. Bind mounts depend on a host path and are useful for development, but are forbidden for the two required persistent stores in this exercise. |

## Instructions

### Prerequisites

* A Linux virtual machine with Docker Engine, Docker Compose v2, and Make.
* DNS or `/etc/hosts` configured so `lzorzit.42.fr` resolves to the VM.
* A local TLS certificate and private key in `secrets/`.

Create the ignored configuration and secrets:

```sh
cp srcs/.env.example srcs/.env
mkdir -p secrets
chmod 700 secrets
printf '%s\n' 'change-this-root-password' > secrets/db_root_password.txt
printf '%s\n' 'change-this-database-password' > secrets/db_password.txt
printf '%s\n' 'change-this-wordpress-admin-password' > secrets/wp_admin_password.txt
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout secrets/tls.key -out secrets/tls.crt \
  -subj '/CN=lzorzit.42.fr'
chmod 600 secrets/*
```

The sample values are for setup only; replace them before using the stack.

### Build and run

```sh
make
make ps
make logs
```

Open `https://lzorzit.42.fr/` and accept the locally generated certificate.
The WordPress administration panel is at `/wp-admin/`.

Useful lifecycle commands are `make stop`, `make start`, `make restart`, and
`make down`. `make fclean` removes containers, project volumes, and unused
Docker data; use it only when you intentionally want to delete persistent data.

## Project structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                         # local, ignored credentials and TLS files
└── srcs/
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/www.conf
            └── tools/entrypoint.sh
```

## Resources

* [Docker Compose documentation](https://docs.docker.com/compose/)
* [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
* [NGINX documentation](https://nginx.org/en/docs/)
* [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
* [MariaDB Docker image documentation](https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/)
* [WordPress installation documentation](https://developer.wordpress.org/advanced-administration/before-install/howto-install/)

The implementation and documentation were written and reviewed as part of the
exercise.

### AI usage

AI tools were used for studying on the core concepts before starting work on the project, to double-check compliance with subject and to help write the README.md file.
All other project files, configuration, commands, and implementation decisions were written, reviewed
and tested by me.