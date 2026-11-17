#!/bin/sh
set -eu

if [ ! -f /var/www/html/wp-load.php ]; then
    curl -fsSL "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz" | tar -xz --strip-components=1 -C /var/www/html
fi

db_password=$(cat /run/secrets/db_password)
if [ ! -f /var/www/html/wp-config.php ]; then
    cat > /var/www/html/wp-config.php <<PHP
<?php
define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${db_password}');
define('DB_HOST', 'mariadb:3306');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
PHP
    chown www-data:www-data /var/www/html/wp-config.php
fi

until runuser -u www-data -- wp db check --path=/var/www/html >/dev/null 2>&1; do
    sleep 2
done

if ! runuser -u www-data -- wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
    runuser -u www-data -- wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
fi

if ! runuser -u www-data -- wp user get "${WP_SECOND_USER}" --path=/var/www/html >/dev/null 2>&1; then
    runuser -u www-data -- wp user create "${WP_SECOND_USER}" "${WP_SECOND_EMAIL}" \
        --role=editor \
        --user_pass="$(cat /run/secrets/wp_admin_password)" \
        --path=/var/www/html
fi

chown -R www-data:www-data /var/www/html/wp-content
exec php-fpm8.2 -F
