#!/bin/bash

set -e

# Set timezone
set_time_zone() {
  while true; do
    echo -n 'Please enter the timezone (press enter to use the default timezone "Asia/Shanghai"): '
    read -r timezone
    timezone=${timezone:-"Asia/Shanghai"}

    if timedatectl list-timezones | grep -q "^$timezone$"; then
      echo 'Setting timezone ......'
      timedatectl set-timezone "$timezone"
      echo 'Timezone is set to' "$timezone" '......'
      break
    else
      echo "Invalid timezone: $timezone. Please try again."
    fi
  done
}

main(){
    set_time_zone
}

main
