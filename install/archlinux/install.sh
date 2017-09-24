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
  Distribution | $DISTRO
  Disk         | $DISK
  Encryption   | $ENCRYPTION
  Mirrorlist   | $MIRROR
  Keymap       | $KEYMAP
  Hostname     | $HOSTNAME
  Timezone     | $TIMEZONE
  User         | $USER
  Graphics     | $GRAPHICS
  Display      | $DISPLAY
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

setup() {
  parition
  format_partition
  mount_partition
  mirrorlist_update
  set_timezone
#  set_locale
#  set_hostname
  install_base
  chroot
  install_network
  install_boot
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
      yes | mkfs.fat -F32 /dev/sda1
      yes | mkfs.ext4 /dev/sda2
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
  echo 'Updating mirrorlist...'
  rm /etc/pacman.d/mirrorlist
  wget https://www.archlinux.org/mirrorlist/?country=$MIRROR -O /etc/pacman.d/mirrorlist
  sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
  echo 'Done!'
}

set_timezone(){
  echo
  echo 'Setting timezone...'
  ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
  hwclock --systohc
  echo 'Done!'
}

set_locale() {
  echo
  echo 'Setting locale...'
  sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
#  nano /etc/locale.conf
#  echo -e "LANG=$LOCALE"
  locale-gen
  echo "Done!"
}

set_hostname() {
  echo
  echo 'Setting hostname...'
#  nano /etc/hostname
#  $HOSTNAME
#  echo -e "#
# /etc/hosts: static lookup table for host names
#

#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.localdomain   localhost
::1             localhost.localdomain   localhost
127.0.0.1       $HOSTNAME.localdomain   $HOSTNAME

# End of file" >> /etc/hosts
  echo "Done!"
}


install_base() {
  echo
  echo 'Installing base...'
  pacstrap /mnt base base-devel
  genfstab -U /mnt >> /mnt/etc/fstab
  echo
  echo "Done!"
}

chroot() {
  echo
  echo 'Entering chroot...'
  arch-chroot /mnt
}

install_network() {
  echo
  echo 'Installing network...'
  pacman -S networkmanager
  systemctl enable NetworkManager.service
  echo
  echo "Done!"
}

install_boot() {
  echo
  echo 'Installing boot...'
  pacman -Sy grub
  grub-install --target=i386-pc $DISK
  grub-mkconfig -o /boot/grub/grub.cfg
  echo
  echo "Done!"
}

# Is root running.
if [ "`id -u`" -ne 0 ]
then
  echo -e "\n\nRun as root!\n\n"
  exit -1
fi

startup

echo
printf "\n==============================================
          Install finished, restarting in 5 seconds...
          ==============================================\n"
echo "5"
wait 1
echo "4"
wait 1
echo "3"
wait 1
echo "2"
wait 1
echo "1"
wait 1
reboot
