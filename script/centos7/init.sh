#!/bin/bash

set -e

log() {
  local msg_type="$1"
  local msg="$2"
  case "${msg_type}" in
    info)
      echo -e "\e[32m[INFO] ${msg}\e[0m"  # Green
      ;;
    warning)
      echo -e "\e[33m[WARNING] ${msg}\e[0m"  # Yellow
      ;;
    error)
      echo -e "\e[31m[ERROR] ${msg}\e[0m"  # Red
      ;;
    *)
      echo "[UNKNOWN] ${msg}"
      ;;
  esac
}

# Set file descriptor limit
set_fd_limit() {
  local proc_limit
  local fd_limit
  local mem_limit
  proc_limit=$(ulimit -u)
  fd_limit=$(ulimit -n)
  mem_limit=$(ulimit -l)

  if [ "${proc_limit}" = '65535' ] && [ "${fd_limit}" = '65535' ] && [ "${mem_limit}" = 'unlimited' ]; then
    log 'info' 'System limits are already set as expected.'
    return 0
  fi

  log 'info' 'Setting file descriptor limit to 65535 ......'
  ulimit -n 65535
  if [ "$(ulimit -n)" = '65535' ]; then
    log 'info' 'File descriptor limit is set to 65535.'
  else
    log 'error' 'Failed to set file descriptor limit to 65535.'
  fi

  log 'info' 'Setting system limits in /etc/security/limits.conf ......'

  for limit in noproc nofile memlock; do
    for type in soft hard; do
      if grep -q "^* ${type} ${limit}" /etc/security/limits.conf; then
        # If the line exists, modify it
        sed -i "/^* ${type} ${limit}/c\\* ${type} ${limit} $(if [ "${limit}" = 'memlock' ]; then echo 'unlimited'; else echo '65535'; fi)" /etc/security/limits.conf
      else
        # If the line does not exist, add it
        echo "* ${type} ${limit} $(if [ "${limit}" = 'memlock' ]; then echo 'unlimited'; else echo '65535'; fi)" >> /etc/security/limits.conf
      fi
    done
  done

  log 'info' 'Reloading system parameters with sysctl ......'
  sudo sysctl --system

  log 'info' 'Verifying the system limits ......'
  proc_limit=$(ulimit -u)
  fd_limit=$(ulimit -n)
  mem_limit=$(ulimit -l)

  if [ "${proc_limit}" = '65535' ] && [ "${fd_limit}" = '65535' ] && [ "${mem_limit}" = 'unlimited' ]; then
    log 'info' 'System limits are set as expected.'
  else
    log 'error' "Failed to set system limits as expected. Current limits are: process='${proc_limit}', file descriptor='${fd_limit}', memory='${mem_limit}'."
  fi
}

# Set timezone
set_time_zone() {
  log 'info' 'Starting to set timezone ......'
  while true; do
    echo -n 'Please enter the timezone (press enter to use the default timezone "Asia/Shanghai"): '
    read -r timezone
    timezone=${timezone:-"Asia/Shanghai"}

    if timedatectl list-timezones | grep -q "^${timezone}$"; then
      log 'info' 'Setting timezone ......'
      timedatectl set-timezone "${timezone}"
      log 'info' "Timezone is set to ${timezone} ......"
      break
    else
      log 'error' "Invalid timezone: ${timezone}. Please try again."
    fi
  done
}

# Set scheduled time synchronization
set_scheduled_sync_time(){
  log 'info' 'Starting to set up time synchronization task ......'

  echo -n 'Please enter the cron expression (press enter to use the default expression "0 */1 * * *"): '
  read -r cron_expr
  cron_expr=${cron_expr:-"0 */1 * * *"}

  while true; do
    echo -n 'Please enter the NTP server (press enter to use the default server "ntp1.aliyun.com"): '
    read -r ntp_server
    ntp_server=${ntp_server:-"ntp1.aliyun.com"}

    if ping -c 1 "${ntp_server}" &> /dev/null; then
      log 'info' "${ntp_server} is reachable. Setting up scheduled time synchronization ..."
      break
    else
      log 'error' "Cannot reach ${ntp_server}. Please try again."
    fi
  done

  yum -y install ntp ntpdate crontab

  log 'info' 'Starting to synchronize time ......'
  /usr/sbin/ntpdate "${ntp_server}"

  log 'info' 'Writing time synchronization task ......'
  (crontab -l ; echo "${cron_expr} /usr/sbin/ntpdate ${ntp_server}") | crontab -
  systemctl restart crond && systemctl enable crond --now
  systemctl status crond
}

main(){
    set_fd_limit
    set_time_zone
    set_scheduled_sync_time
}

main
