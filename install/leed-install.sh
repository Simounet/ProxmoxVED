#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: simounet
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://codeberg.org/LeedRSS/Leed

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="mysqli,gd,curl,mbstring,xml,zip" setup_php
setup_mariadb
MARIADB_DB_NAME="leed_db" MARIADB_DB_USER="leed_user" setup_mariadb_db

fetch_and_deploy_gh_release "leed" "LeedRSS/Leed" "tarball"

msg_info "Configuring Leed"
cd /opt/leed
chown -R www-data:www-data /opt/leed
chmod -R g+rX /opt/leed
msg_ok "Configured Leed"

msg_info "Setting up cron job for feed refresh"
cat <<EOF >/etc/cron.d/leed-action
* * * * * www-data /bin/php -f /opt/leed/action.php > /tmp/leed.log 2>&1
EOF
chmod 644 /etc/cron.d/leed-action
msg_ok "Set up Cron - if you need to modify the timing edit the file /etc/cron.d/leed-action"

msg_info "Creating VHOST"
cat <<EOF >/etc/apache2/sites-available/leed.conf
<VirtualHost *:80>
    ServerName leed
    DocumentRoot /opt/leed

    <Directory /opt/leed>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/leed_error.log
    CustomLog /var/log/apache2/leed_access.log combined

    AllowEncodedSlashes On
</VirtualHost>
EOF

$STD a2ensite leed
$STD a2enmod rewrite deflate expires headers mime setenvif
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

msg_info "Creating constant.php and new user"
curl -fsS "http://${LOCAL_IP}/install.php" \
   -o /tmp/leed-install-response.txt \
  -X POST \
  -H 'User-Agent: Mozilla/5.0 (Linux; x64; rv:161.0) Gecko/20100101 Firefox/161.0' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
  -H 'Accept-Language: fr,fr-FR;q=0.9,en-US;q=0.8,en;q=0.7' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Sec-GPC: 1' \
  -H 'Connection: keep-alive' \
  --data-raw "install_changeLngLeed=fr&root=http%3A%2F%2F${LOCAL_IP}&mysqlHost=127.0.0.1&mysqlLogin=${MARIADB_DB_USER}&mysqlMdp=${MARIADB_DB_PASS}&mysqlBase=${MARIADB_DB_NAME}&mysqlPrefix=leed__&login=${var_leed_user_login}&password=${var_leed_user_password}&installButton="

motd_ssh
customize
cleanup_lxc
