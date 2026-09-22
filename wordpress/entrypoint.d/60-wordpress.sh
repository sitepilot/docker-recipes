#!/bin/sh

set -eu

# Required config
: "${WP_THEME:?WP_THEME is required}"
: "${WP_URL:?WP_URL is required}"

# Optional config
: "${WP_LOCALE:=en_US}"
: "${WP_TITLE:=WordPress}"
: "${WP_DB_HOST:=mariadb}"
: "${WP_DB_NAME:=wordpress}"
: "${WP_DB_USER:=wordpress}"
: "${WP_DB_PASSWORD:=secret}"
: "${WP_DB_WAIT_TIMEOUT:=60}"
: "${WP_ADMIN_USER:=admin}"
: "${WP_ADMIN_PASSWORD:=secret}"
: "${WP_ADMIN_EMAIL:=admin@example.com}"
: "${WP_THEME:-}"
: "${WP_PLUGINS:=}"
: "${WP_ACF_PRO_KEY:=}"

WP_PATH=${APACHE_DOCUMENT_ROOT}

log() {
    printf '\033[1;32m→ %s\033[0m\n' "$1"
}

wp() {
    command wp --path="$WP_PATH" "$@"
}

wait_for_db() {
    waited=0

    while ! wp db query "SELECT 1" >/dev/null 2>&1; do
        if [ "$waited" -ge "$WP_DB_WAIT_TIMEOUT" ]; then
            log "Database not reachable after ${WP_DB_WAIT_TIMEOUT}s"

            return 1
        fi

        [ "$waited" -eq 0 ] && log "Waiting for the database"

        sleep 2
        waited=$((waited + 2))
    done
}

if [ ! -f "${WP_PATH}/wp-load.php" ]; then
    log "Downloading WordPress core"
    wp core download --locale="${WP_LOCALE}"
fi

if ! wp config path >/dev/null 2>&1; then
    log "Creating wp-config.php"
    wp config create \
        --dbhost="${WP_DB_HOST}" \
        --dbname="${WP_DB_NAME}" \
        --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" \
        --skip-check
fi

wait_for_db

if ! wp core is-installed >/dev/null 2>&1; then
    log "Installing WordPress"
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
fi

log "Updating WP_DEVELOPMENT_MODE"
wp config set WP_DEVELOPMENT_MODE "theme" --type=constant

for plugin in ${WP_PLUGINS:-}; do
    case "$plugin" in
        advanced-custom-fields-pro)
            source="https://connect.advancedcustomfields.com/v2/plugins/download?p=pro&k=${WP_ACF_PRO_KEY:?advanced-custom-fields-pro requires WP_ACF_PRO_KEY}"
            ;;
        *)
            source="$plugin"
            ;;
    esac

    if wp plugin is-installed "$plugin" >/dev/null 2>&1; then
        wp plugin is-active "$plugin" >/dev/null 2>&1 || {
            log "Activating ${plugin}"
            wp plugin activate "$plugin"
        }
    else
        log "Installing ${plugin}"
        wp plugin install "$source" --activate
    fi
done

if [ -n "${WP_THEME}" ]; then
  log "Activating theme"
  wp theme activate ${WP_THEME}
fi

log "WordPress URL: $(wp option get home)"
