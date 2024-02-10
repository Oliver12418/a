#!/bin/bash

# Interactive user prompts
read -p "Enter the target disk (e.g., /dev/sdX): " TARGET_DISK
read -p "Enter the EFI partition size (e.g., 512M): " EFI_PARTITION_SIZE
read -p "Enter the desired hostname: " HOSTNAME
read -p "Enter the locale (e.g., en_US.UTF-8): " LOCALE
read -p "Enter the timezone (e.g., Region/City): " TIMEZONE
read -s -p "Enter the root password: " ROOT_PASSWORD
echo # Add a new line for better formatting

# Set the keyboard layout
loadkeys us

# Verify the boot mode (UEFI or BIOS)
if [ -d "/sys/firmware/efi/efivars" ]; then
  echo "UEFI mode detected."
else
  echo "This script supports UEFI mode only. Please adjust for BIOS systems."
  exit 1
fi

# Connect to the internet
ping -c 3 google.com || {
  echo "Please ensure you have an active internet connection."
  exit 1
}

# Update the system clock
timedatectl set-ntp true

# Create partitions
(
  echo g
  echo n
  echo 1
  echo
  echo +$EFI_PARTITION_SIZE
  echo t
  echo 1
  echo 1
  echo n
  echo 2
  echo
  echo
  echo w
) | fdisk $TARGET_DISK

# Format the partitions
mkfs.fat -F32 ${TARGET_DISK}1
mkfs.ext4 ${TARGET_DISK}2

# Mount the partitions
mount ${TARGET_DISK}2 /mnt
mkdir -p /mnt/boot
mount ${TARGET_DISK}1 /mnt/boot

# Install essential packages
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the installed system
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Uncomment your preferred locale in /etc/locale.gen and generate the locale
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Set the hostname
echo "$HOSTNAME" > /etc/hostname

# Set the root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Install and configure bootloader (replace 'grub' with your preferred bootloader)
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot environment and unmount partitions
exit
umount -R /mnt

echo "Installation complete. You can now reboot into your new Arch Linux system."
