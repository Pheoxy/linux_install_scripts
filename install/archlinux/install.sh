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
# Root 100% or 20G
ROOT_PART=10G
# Home
#HOME_PART="Not supported yet"

# Encrypt disk but leave boot parition (Yes/No).
ENCRYPTION='No'

# Download mirror location, use your country code.
MIRROR='AU'

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

==============================================
Its recommened to run 'lsblk' to check disk
location to prevent unintentional data loss.
==============================================

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

setup() {
  parition
  format_partition
  mount_partition
  mirrorlist_update
  install_base
  chroot
#  set_timezone
}

configuration() {
  echo "Installing..."
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
    parted -s "$DISK" \
    mklabel msdos \
    mkpart primary ext4 1 $BOOT_PART \
    mkpart primary ext4 $BOOT_PART $ROOT_PART \
    set 1 boot on
    echo "Done!"

  else
    echo "Partitioning for EFI..."
    echo "Error 1: Work in progress..."
    exit 1
  fi
}

format_partition() {
  echo
  echo "Formatting partitions..."
  echo
  if [ $efi_status=TRUE ]
    then
      yes | mkfs.ext4 /dev/sda1
      yes | mkfs.ext4 /dev/sda2
    else
      echo
      mkfs.fat -F32 /dev/sda1
      y
      mkfs.ext4 /dev/sda2
      y
  fi
  echo 'Done!'
}

mount_partition() {
  echo
  echo "Mounting disks..."
  echo
  mount /dev/sda2 /mnt
  mkdir /mnt/boot
  mount /dev/sda1 /mnt/boot
  echo
  echo "Partition mount successful!"
}

mirrorlist_update() {
  echo
  echo 'Updating Mirrorlist...'
  rm /etc/pacman.d/mirrorlist
  wget https://www.archlinux.org/mirrorlist/?country=$MIRROR -O /etc/pacman.d/mirrorlist
  sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
  echo 'Done!'
}

set_timezone(){
  echo
  echo 'Setting Timezone...'
  ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime
  hwclock --systohc
#  nano /etc/locale.gen
#  nano /etc/locale.conf
#  LANG=en_AU.UTF-8
#  locale-gen
  echo 'Done!'
}

install_base() {
  pacstrap /mnt base base-devel
  genfstab -U /mnt >> /mnt/etc/fstab
}

chroot() {
  arch-chroot /mnt
}

# Is root running.
if [ "`id -u`" -ne 0 ]
then
  echo -e "\n\nRun as root!\n\n"
  exit -1
fi

startup
exit 0
