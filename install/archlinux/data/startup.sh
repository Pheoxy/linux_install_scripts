#!/bin/bash

startup() {
  printf "\nChecking your Configuration... \n

==============================================
 Script Version | $VERSION
----------------------------------------------
 Distribution   | $DISTRO
 Disk           | $DISK
 Encryption     | $ENCRYPTION
 Mirrorlist     | $MIRROR
 Keymap         | $KEYMAP
 Hostname       | $HOSTNAME
 Timezone       | $TIMEZONE
 User           | $USER
 Graphics       | $GRAPHICS
 Display        | $DISPLAY
==============================================
  \n"
  lsblk
  echo
  read -p "Is this correct? (y/n):  " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      printf 'Please fix your Configuration at the start of the script.\n'
      exit 1
    else
      echo
      setup
  fi
}
