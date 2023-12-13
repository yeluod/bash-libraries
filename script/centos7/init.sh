#!/bin/bash

set -e

log() {
  local msg_type="$1"
  local msg="$2"
  case "$msg_type" in
    info)
      echo -e "\e[32m[INFO] $msg\e[0m"  # Green
      ;;
    warning)
      echo -e "\e[33m[WARNING] $msg\e[0m"  # Yellow
      ;;
    error)
      echo -e "\e[31m[ERROR] $msg\e[0m"  # Red
      ;;
    *)
      echo "[UNKNOWN] $msg"
      ;;
  esac
}

# Set timezone
set_time_zone() {
  log "info" 'Starting to set timezone ......'
  while true; do
    log "info" 'Please enter the timezone (press enter to use the default timezone "Asia/Shanghai"): '
    read -r timezone
    timezone=${timezone:-"Asia/Shanghai"}

    if timedatectl list-timezones | grep -q "^${timezone}$"; then
      log "info" 'Setting timezone ......'
      timedatectl set-timezone "${timezone}"
      log "info" 'Timezone is set to' "${timezone}" '......'
      break
    else
      log "error" "Invalid timezone: ${timezone}. Please try again."
    fi
  done
}

# Set scheduled time synchronization
set_scheduled_sync_time(){
  log "info" 'Starting to set up time synchronization task ......'

  log "info" 'Please enter the cron expression (press enter to use the default expression "0 */1 * * *"): '
  read -r cron_expr
  cron_expr=${cron_expr:-"0 */1 * * *"}

  while true; do
    log "info" 'Please enter the NTP server (press enter to use the default server "ntp1.aliyun.com"): '
    read -r ntp_server
    ntp_server=${ntp_server:-"ntp1.aliyun.com"}

    if ping -c 1 "${ntp_server}" &> /dev/null; then
      log "info" "${ntp_server} is reachable. Setting up scheduled time synchronization ..."
      break
    else
      log "error" "Cannot reach ${ntp_server}. Please try again."
    fi
  done

  yum -y install ntp ntpdate crontab

  log "info" 'Starting to synchronize time ......'
  /usr/sbin/ntpdate "${ntp_server}"

  log "info" 'Writing time synchronization task ......'
  (crontab -l ; echo "${cron_expr} /usr/sbin/ntpdate ${ntp_server}") | crontab -
  systemctl restart crond && systemctl enable crond --now
  systemctl status crond
}

main(){
    set_time_zone
    set_scheduled_sync_time
}

main
