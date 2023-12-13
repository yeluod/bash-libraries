#!/bin/bash

set -e

# Set timezone
set_time_zone() {
  echo -n 'Please enter the timezone (press enter to use the default timezone "Asia/Shanghai"):'
  read -r timezone
  timezone=${timezone:-"Asia/Shanghai"}

  echo 'Setting timezone ......'
  timedatectl set-timezone "$timezone"
  echo 'Timezone is set to' "$timezone" '......'
}

main(){
    set_time_zone
}

main