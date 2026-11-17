# Debian virtual machine setup guide

This guide prepares a Debian VM for the Inception project. The commands below
assume the VM user is `lzorzit`, matching the current repository configuration.
If your 42 login is different, replace `lzorzit` in commands, `/home/lzorzit`,
and the `DOMAIN_NAME` and `DATA_ROOT` values in `srcs/.env`.

## 1. Create the VM

Install VirtualBox (or another hypervisor) on the host and create a VM with the
following lightweight settings:

* Debian 12 (Bookworm) 64-bit netinst ISO
* At least 2 CPU cores
* 2 GB RAM minimum; 4 GB is preferable if the host has enough memory
* At least 20 GB dynamically allocated disk space
* Two network adapters:
  * **Adapter 1: NAT**, for downloading packages
  * **Adapter 2: Host-only Adapter**, for reaching the VM from the host

Download the **amd64 netinst ISO** from the official Debian Bookworm installer
page. Do not download a Live ISO, DVD image, desktop image, ARM64 image, or
cloud image. The netinst image downloads the small base system and retrieves
only the packages selected during installation.

### Debian installer choices

Boot the VM from the ISO and use these choices:

1. Select **Graphical install** or **Install**. The installed system is the
   same; **Install** uses less memory during setup.
2. Select your language, location, keyboard, and network settings.
3. Give the machine a simple hostname, such as `inception-vm`.
4. Create the normal user with the same login as the project. In this example,
   the login is `lzorzit`.
5. Use guided partitioning with **one partition for `/` and a swap partition**.
   The default guided layout is sufficient.
6. At **Software selection**, clear every desktop environment and clear
   **GNOME**, **KDE Plasma**, **Xfce**, and other graphical desktops. Keep only:
   * **standard system utilities**
   * **SSH server**, only if you want to administer the VM through SSH
7. Install GRUB to the VM's virtual disk and reboot, removing the ISO when
   prompted.

This produces a command-line-only Debian system. It is the lightest practical
installation for this project; Docker containers do not require a graphical
desktop inside the VM.

After the first boot, update Debian:

```sh
su -
apt update
apt full-upgrade -y
apt install -y ca-certificates curl git make openssl sudo
usermod -aG sudo lzorzit
reboot
```

Log in again after reboot. Verify the VM's host-only address:

```sh
ip -br address
```

Use the address on the host-only interface (for example, `192.168.56.10`) in
the host machine's `/etc/hosts` file:

```text
192.168.56.10 lzorzit.42.fr
```

The hostname must resolve to the VM because the subject requires
`<login>.42.fr`. Test it from the host:

```sh
ping -c 1 lzorzit.42.fr
```

## 2. Install Docker Engine and Compose

Run these commands inside the Debian VM:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Log out and back in so the group change takes effect, then verify:

```sh
docker run --rm hello-world
docker compose version
make --version
```

The project builds its own service images. Do not replace its Dockerfiles with
ready-made WordPress, NGINX, or MariaDB images.

## 3. Copy the project into the VM

Clone the repository in the VM, or copy it from the host. For example:

```sh
cd ~
git clone https://github.com/ludoviKZ/inception.git
cd inception
```

Keep the repository under the VM user's home directory. The subject requires
the persistent data to be under `/home/<login>/data`.

## 4. Configure the project

Create the ignored environment file and the required local secrets:

```sh
cp srcs/.env.example srcs/.env
mkdir -p secrets
chmod 700 secrets

printf '%s\n' 'replace-with-a-root-password' > secrets/db_root_password.txt
printf '%s\n' 'replace-with-a-database-password' > secrets/db_password.txt
printf '%s\n' 'replace-with-a-wordpress-password' > secrets/wp_admin_password.txt

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout secrets/tls.key \
  -out secrets/tls.crt \
  -subj '/CN=lzorzit.42.fr'
chmod 600 secrets/*
```

Review `srcs/.env` and confirm these values:

```dotenv
DOMAIN_NAME=lzorzit.42.fr
DATA_ROOT=/home/lzorzit/data
```

Create the host directories required by the bind-backed named Docker volumes:

```sh
mkdir -p /home/lzorzit/data/mariadb /home/lzorzit/data/wordpress
```

Do not commit `srcs/.env` or anything in `secrets/`. Passwords and private keys
must remain local.

## 5. Build and start the stack

From the repository root:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config --quiet
make
make ps
```

The stack contains three containers:

* `nginx`: the only public service, on HTTPS port 443
* `wordpress`: PHP-FPM, private on the Docker network
* `mariadb`: the database, private on the Docker network

Open this URL from the host machine:

```text
https://lzorzit.42.fr/
```

Because the certificate is self-signed, the browser will display a warning.
The WordPress administration page is `/wp-admin/`. The administrator username
is `site_owner` unless you changed `WP_ADMIN_USER` in `.env`.

## 6. Check and manage the installation

```sh
make ps
make logs
curl -kI https://lzorzit.42.fr/
docker volume ls
docker network inspect inception
```

Normal lifecycle commands are:

```sh
make stop       # stop containers and keep data
make start      # start existing containers
make restart    # restart containers
make down       # remove containers and keep data
make            # rebuild if needed and start
```

The persistent data is stored at:

```text
/home/lzorzit/data/mariadb
/home/lzorzit/data/wordpress
```

Do not run `make fclean` unless you intentionally want to delete the project
volumes and Docker data. If the site returns `502`, inspect the WordPress and
NGINX logs and verify that all three containers are running.

## 7. Final subject checklist

Before evaluation, verify that:

* the project runs inside the Debian VM;
* only NGINX publishes port 443;
* the hostname is `lzorzit.42.fr` (or your own login's equivalent);
* the two persistent stores are named Docker volumes backed by
  `/home/<login>/data`;
* TLS is enabled and limited to TLS 1.2 and TLS 1.3;
* no password is present in a Dockerfile or committed to Git;
* the administrator username does not contain `admin`;
* all containers have their own Dockerfile and restart policy.
