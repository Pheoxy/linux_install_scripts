#!/bin/bash


##########################
## Start on boot Script ##
##########################

start() {
  echo "Starting ssh server..."
  systemctl start sshd
  sleep 1
  echo "Done!"
  echo
  echo "Displaying ip address..."
  ip addr | grep 192.168.*
  sleep 1
  echo "Done!"
  echo
  read -p "Autorun arch_install.sh script? (y/n):  " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo
      reboot
    else
      echo
      "Starting arch_install.sh script..."
      wget pheoxy.com/linux/arch_install.sh
      chmod u+x ./arch_install.sh
      ./arch_install.sh
  fi
  #nano /etc/netctl/eno1
}

reboot() {
  read -p "Reboot? (y/n):  " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      printf 'Done!\n'
      exit 0
    else
      echo
      echo "Rebooting..."
      sleep 3
      #reboot
  fi
}

start

exit 0
