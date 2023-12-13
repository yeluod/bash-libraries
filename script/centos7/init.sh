#!/bin/bash

set -e

# Set timezone
set_time_zone() {
  while true; do
    echo -n 'Please enter the timezone (press enter to use the default timezone "Asia/Shanghai"): '
    read -r timezone
    timezone=${timezone:-"Asia/Shanghai"}

    if timedatectl list-timezones | grep -q "^${timezone}$"; then
      echo 'Setting timezone ......'
      timedatectl set-timezone "${timezone}"
      echo 'Timezone is set to' "${timezone}" '......'
      break
    else
      echo "Invalid timezone: ${timezone}. Please try again."
    fi
  done
}

# Set scheduled time synchronization
set_scheduled_sync_time(){
  echo -n 'Please enter the cron expression (press enter to use the default expression "0 */1 * * *"): '
  read -r cron_expr
  cron_expr=${cron_expr:-"0 */1 * * *"}

  while true; do
    echo -n 'Please enter the NTP server (press enter to use the default server "ntp1.aliyun.com"): '
    read -r ntp_server
    ntp_server=${ntp_server:-"ntp1.aliyun.com"}

    if ping -c 1 "${ntp_server}" &> /dev/null; then
      echo "${ntp_server} is reachable. Setting up scheduled time synchronization ..."
      break
    else
      echo "Cannot reach ${ntp_server}. Please try again."
    fi
  done

  yum -y install ntp ntpdate crontab

  /usr/sbin/ntpdate "${ntp_server}"
  (crontab -l ; echo "${cron_expr} /usr/sbin/ntpdate ${ntp_server}") | crontab -
  systemctl restart crond && systemctl enable crond --now
  systemctl status crond
}

main(){
    set_time_zone
    set_scheduled_sync_time
}

main
