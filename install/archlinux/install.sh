#!/bin/bash


###################
## Configuration ##
###################
VERSION="BETA1"
#
# title="Install Wizard"
# backtitle="Archlinux Installer $VERSION"

# Distribution
DISTRO='Archlinux'

# Install disk location.
DISK='/dev/sda'

# Partitioning
# Boot 100M or more
BOOT_PART=300M
# Root 20G or 100%
ROOT_PART=100%
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

setup() {
  parition
  format_partition
  mount_partition
  mirrorlist_update
  set_keymap
  install_base
  chroot
}

setup_systemclock() {
  echo
  echo "Update the system clock..."
  echo
  timedatectl set-ntp true
  echo
  echo "Done!"
}

parition() {
  echo 'Checking for efi...'
  efi_files="/sys/firmware/efi/efivars"
  if [[ -f $efi_files ]]
  then
  	echo "$efi_files found."
    efi_status="TRUE"
    echo
  else
  	echo "$efi_files not found."
  fi

  if [[ $efi_status == TRUE ]]
  then
    echo "Partitioning for EFI..."
    echo "Error 1: Work in progress..."
    exit 1
  else
    echo "Partitioning for BIOS..."
    parted -s "$DISK" \
    mklabel msdos \
    mkpart primary ext4 1 $BOOT_PART \
    mkpart primary ext4 $BOOT_PART $ROOT_PART \
    set 1 boot on
    echo "Done!"
  fi
}

format_partition() {
  echo
  echo "Formatting partitions..."
  echo
  if [[ $efi_status == TRUE ]]
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

set_keymap() {
  echo
  echo 'Setting keymap...'
  echo -e "KEYMAP=$KEYMAP" > /etc/vconsole.conf
  echo
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
  echo 'Copying script to chroot...'
  cp install.sh /mnt/root/install.sh
  chmod +x /mnt/root/install.sh
  echo
  echo "Done!"
  echo
  echo 'Entering chroot...'
  arch-chroot /mnt /root/install.sh setupchroot
}

set_timezone() {
  echo
  echo 'Setting timezone...'
  ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
  hwclock --systohc
  echo
  echo 'Done!'
}

set_locale() {
  echo
  echo 'Setting locale...'
  sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
  locale-gen
  echo
  echo "Done!"
}

set_hostname() {
  echo
  echo 'Setting hostname...'
  echo -e "$HOSTNAME" >> /etc/hostname
  echo
  echo "Done!"
}

setup_pacman() {
  echo
  echo 'Initialize pacman...'
  pacman-key --init
  pacman-key --populate archlinux
  echo
  echo "Done!"
}

setup_user() {
  echo
  echo 'Add sudoers user...'
  useradd -m -G wheel -s /bin/bash $USER
  sed -i "s/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
  echo
  echo "Done!"
}

install_network() {
  echo
  echo 'Installing network...'
  pacman -Sy --noconfirm networkmanager
  systemctl enable NetworkManager.service
  echo
  echo "Done!"
}

install_graphics() {
  echo
  echo 'Installing graphics...'
  pacman -Sy --noconfirm $GRAPHICS
  if [[ $GRAPHICS == virtualbox-guest-utils ]]
  then
    pacman -Sy --noconfirm linux-headers
    systemctl enable vboxservice.service
  fi
  echo
  echo "Done!"
}

install_desktop() {
  echo
  echo "Installing $DISPLAY..."
  pacman -Sy --noconfirm $DISPLAY
  if [[ $DISPLAY == gnome ]]
  then
    systemctl enable gdm.service
  fi
  echo
  echo "Done!"
}

install_boot() {
  echo
  echo 'Installing boot...'
  mkinitcpio -p linux
  pacman -Sy --noconfirm grub
  grub-install --target=i386-pc $DISK
  grub-mkconfig -o /boot/grub/grub.cfg
  echo
  echo "Done!"
}

_reboot() {
  printf "\n
======================
 Install finished...
======================\n"
  read -p "Reboot? (y/n):  " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      printf 'Done!\n'
      exit 0
    else
      echo
      echo "Restarting in 3 seconds..."
      sleep 3
      reboot
  fi
}

# Is root running.
if [ "`id -u`" -ne 0 ]
then
  echo -e "\n\nRun as root!\n\n"
  exit -1
fi

# Check if chroot before startup.
if [[ $1 == setupchroot ]]
then
  echo "Starting chroot setup..."
  set_timezone
  set_locale
  set_hostname
  setup_pacman
  setup_user
  install_network
  install_graphics
  install_desktop
  install_boot
  exit 0
else
  startup
fi

_reboot
