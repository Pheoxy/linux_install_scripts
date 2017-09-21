#!/bin/bash


###################
## Configuration ##
###################
# VERSION=ALPHA
#
# title="Install Wizard"
# backtitle="Archlinux Installer $VERSION"

# config() {
# Distribution
DISTRO='Archlinux'

# Install disk location.
DISK='/dev/sda'

# Partitioning
# Boot
BOOT_PART=300M
# Root
ROOT_PART=20G
# Home
HOME_PART=

# Encrypt disk but leave boot parition (Yes/No).
ENCRYPTION='No'

# Download mirror location, use your country code.
MIRRORLIST='AU'

# Keymap.
KEYMAP='us'

# Locale.
LOCALE='LANG=en_AU.UTF-8'

# Hostname.
HOSTNAME='pheoxy-laptop'

# Timezone.
TIMEZONE='Australia/Perth'

# Main user to create (sudo permissions).
USER='pheoxy'

# Graphics drivers
#GRAPHICS="i915"
#GRAPHICS="nouveau"
#GRAPHICS="radeon"
GRAPHICS="virtualbox-guest-utils"

# Display Enviroment
DISPLAY='gnome'
#}

startup() {
  printf "\nChecking your Configuration... \n

==========================================================================================
Its recommened to run 'lsblk' to check disk location to prevent unintentional data loss.
==========================================================================================

  Distribution | $DISTRO
  Disk         | $DISK
  Encryption   | $ENCRYPTION
  Mirrorlist   | $MIRRORLIST
  Keymap       | $KEYMAP
  Hostname     | $HOSTNAME
  Timezone     | $TIMEZONE
  User         | $USER
  Graphics     | $GRAPHICS
  Display      | $DISPLAY
  \n"

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

setup() {
  parition
  echo 'Done!'
  echo 'Updating Mirrorlist...'
#  mirrorlist_update
  echo 'Done!'
# echo 'Setting Timezone...'
#  echo 'Done!'
  echo
  exit 0
}

configuration() {
  echoPartitioning...

}

set_timezone(){
  echo 'test Timezone'
}

mirrorlist_update() {
  wget https://www.archlinux.org/mirrorlist/?country=$MIRROR -O /etc/pacman.d/mirrorlist
  sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
}

parition() {
  echo 'Checking for efi...'
  efi_files="/sys/firmware/efi/efivars"
  if [ -f "$efi_files" ]
  then
  	echo "$efi_files found."
    efi_status='TRUE'
    echo
  else
  	echo "$efi_files not found."
  fi

  if [ $efi_status=TRUE ]
  then
    echo "Partitioning for BIOS..."
    #parted $DISK mklabel msdos
    # echo -e "n\np\n\n\n+$BOOT_PART\na\nw" | fdisk $DISK
    # sleep 1
    # echo -e "n\np\n\n\n+$ROOT_PART\na\nw" | fdisk $DISK
  else
    echo "Partitioning for EFI..."
    exit 1
  fi
}

startup
exit 0
