#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL=https://raw.githubusercontent.com/Simounet/ProxmoxVED/feature/leed
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: simounet
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://codeberg.com/LeedRSS/Leed

APP="leed"
var_tags="${var_tags:-RSS}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_leed_user_name="${var_leed_user_name:leed}"
export var_leed_user_password="${var_leed_user_password:leed}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/leed ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_codeberg_release "leed" "LeedRSS/Leed"; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    msg_info "Backing up leed"
    mv /opt/leed /opt/leed-backup
    msg_ok "Backup Created"

    fetch_and_deploy_codeberg_release "leed" "LeedRSS/Leed" "tarball"

    msg_info "Restoring config and configuration"
    cp -a /opt/leed-backup/constant.php /opt/leed/constant.php
    if [[ -d /opt/leed-backup/plugins ]]; then
      cp -a /opt/leed-backup/plugins/. /opt/leed/plugins/
    fi
    msg_ok "Data Restored"

    msg_info "Setting permissions"
    chown -R www-data:www-data /opt/leed
    chmod -R g+rX /opt/leed
    chmod -R g+w /opt/leed/plugins/
    msg_ok "Permissions Set"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Cleaning up backup"
    rm -rf /opt/leed-backup
    msg_ok "Cleaned up backup"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Leed Username: ${var_leed_user_name}${CL}"
echo -e "${INFO}${YW}Leed Password: ${var_leed_user_password}${CL}"
