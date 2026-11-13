#!/bin/sh
set -eu

datadir=/var/lib/mysql
root_password=$(cat /run/secrets/db_root_password)
db_password=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "$datadir/mysql" ]; then
    mariadb-install-db --user=mysql --datadir="$datadir" >/dev/null
    mariadbd --user=mysql --datadir="$datadir" --skip-networking &
    bootstrap_pid=$!

    i=0
    until mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -lt 30 ] || { kill "$bootstrap_pid"; exit 1; }
        sleep 1
    done

    mariadb --socket=/run/mysqld/mysqld.sock <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_password}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
    mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"$root_password" shutdown
    wait "$bootstrap_pid"
fi

exec mariadbd --user=mysql --datadir="$datadir" --bind-address=0.0.0.0
