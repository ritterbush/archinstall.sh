!/bin/sh

disk=sda
efipart=sda1
rootpart=sda2
timezone=America/Los_Angeles
cpu=amd #Must be amd or intel or other
hostname=arch
staticip=127.0.1.1
username=paul
password=password

<<COMMENT
        This script installs Arch Linux while making several assumptions: one, it assumes that the disk named in the disk variable above will be WIPED CLEAN.
        It also installs only for UEFI systems. It also provides USA specific repository mirrors. It also assumes that a network is connected and in use 
        once booted into the live environment.

        Checklist:
        Verify Signature/Checksums of downloaded Arch ISO;
        Create bootable;
        Boot into live environment;
        Set keyboard layout if it is not US;
        Confirm UEFI mode with: ls /sys/firmware/efi/efivars;
        Use lsblk to confirm that the disk variable set above matches;
        Use ping to ensure internet connection;
        Configure network router if desired (e.g. to assign a static IP);
        Curl this script with the full https address to the raw file (curl https://link/to/raw/file.sh > archinstall.sh), 
        or, alternatively, mkdir and then mount a USB device with this script to /mnt/usb (use lsblk to help see devices);
        Give the script executable permissions with chmod +x /path/to/archinstall.sh (type pwd to see current directory);
        
        You can view the script with the less command (vim keys to navigate), and
        change any initial variables with sed -i--e.g., sed -i 's/password=password/password=supersecret' /path/to/archinstall.sh  , 
        or you could edit it first with a text editor like a sane person, and even copy it to your own site and curl it.
        
        LICENSE: MIT or Abandonware, whichever you prefer
        Warranty: Zero, but I am sorry about what that did there
        
        Run script:
        /path/to/archinstall.sh

COMMENT


#Update System Clock
timedatectl set-ntp true

#Wipes the disk, and in particular it wipes the partitions previously made first, if this script was already run 
ls /dev/"$rootpart" > /dev/null 2>&1 && wipefs --all --force /dev/"$rootpart"
sleep 1
ls /dev/"$efipart" > /dev/null 2>&1 && wipefs --all --force /dev/"$efipart"
sleep 1
ls /dev/"$disk" > /dev/null 2>&1 && wipefs --all --force /dev/"$disk"
sleep 1

#Create GPT partition table
(echo g; echo w) | fdisk /dev/"$disk"
sleep 2

#Create efi and root partitions
(echo n; echo; echo; echo +512M; echo t; echo; echo 1; echo n; echo; echo; echo; echo p; echo w) | fdisk /dev/"$disk" #setsup disk partitions to use: part1 is 512MB of type EFI and part2 is the rest of type Linux File System;

sleep 2

#(echo p; echo q) | fdisk /dev/"$disk"

#sleep 2

#Make file systems for and mount partitions
mkfs.fat -F32 /dev/"$efipart"
mkfs.ext4 /dev/"$rootpart"
mkdir -p /mnt/efi
#mkdir -p /mnt/boot
#mount /dev/"$efipart" /mnt/boot
mount /dev/"$efipart" /mnt/efi
mount /dev/"$rootpart" /mnt

pacman -Syy
echo Y | pacman -S archlinux-keyring

#Send good USA sites to the top of the  mirrorlist
sed -i '6i\Server = http://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = https://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = http://arch.mirror.constant.com/$repo/os/$arch\nServer = https://arch.mirror.constant.com/$repo/os/$arch\nServer = http://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = https://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = http://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = http://ca.us.mirror.archlinux-br.org/$repo/os/$arch' /etc/pacman.d/mirrorlist

#Install just the bare minimum until chroot
pacstrap /mnt base

#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#Create the chroot script that executes inside the new Arch system 
cat > /mnt/chrootfile.sh <<End-of-message

#Set Timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc

#Localization
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

#Sets LANG=en_US.UTF-8 as the BASH keyboard
#export LANG=en_US.UTF-8

#Create hostname file and set it
echo "$hostname" > /etc/hostname

echo -e '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n'"$staticip\t""$hostname"'.localdomain\t'"$hostname" | cat >> /etc/hosts

(echo "$password"; echo "$password") | passwd
useradd -m -G wheel,audio,video "$username"
(echo "$password"; echo "$password") | passwd "$username"

[ "$cpu" == amd ] && (echo; echo; echo Y) | pacman -S linux linux-firmware amd-ucode
[ "$cpu" == intel ] && (echo; echo; echo Y) | pacman -S linux linux-firmware intel-ucode
[ "$cpu" == other ] && (echo; echo; echo Y) | pacman -S linux linux-firmware

#Old included:base-devel lvm2


#Old steps related to LVM--not used here, and maybe old info
#Enable mkinitcpio hooks for busybox-based initramfs
#sed -i '52s&block&block lvm2&' /etc/mkinitcpio.conf
#The systemd version was not found as a valid hook
#See below for more on busybox vs. systemd hooks:
#https://wiki.archlinux.org/index.php/Talk:Mkinitcpio#Improvements_for_the_Common_hooks_table_and_section_about_systemd_hook
#https://wiki.archlinux.org/index.php/LVM#Configure_mkinitcpio
#should not need to do this
#mkinitcpio -P



#Will include this once we specify installing sudo above
#Give the wheel group root priviledges
#sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers #Not advised; don't make typos here, or use visudo

#pacman -Syy
echo Y | pacman -S networkmanager
systemctl enable NetworkManager
#systemctl start NetworkManager

#echo Y | pacman -S openssh
#systemctl enable sshd.service
#systemctl start sshd.service

echo Y | pacman -S grub efibootmgr #OLD:os-prober amd-ucode dosfstools; os-prober is for detecting multiple OSs on the drive for dual+ boot purposes, amd-ucode is for getting the latest CPU firmware microcode, dosfstools is for using FAT and FAT32 filesystems, and exfat-utiles is for using the ExFAT file system (Update, xfat support is now native with kernel 5.4 and up, so this is removed).


#Other programs that were once in base or that may be worth getting: sysfsutils usbutils e2fsprogs dosfstools mtools inetutils netctl dhcpcd device-mapper cryptsetup less lvm2 openssh vim zsh man-db man-pages

mkdir /efi
#mkdir -p /boot/efi
mount /dev/$efipart /efi #https://wiki.archlinux.org/index.php/EFI_system_partition#Mount_the_partition
#mount /dev/$efipart /boot/efi
grub-install --target=x86_64-efi --efi-directory=efi --bootloader-id=GRUB #https://wiki.archlinux.org/index.php/GRUB#UEFI_systems
#grub-install --target=x86_64-efi --efi-directory=boot/efi --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg

# mkinitcpio -P is not needed, according to the wiki, and verified that it generates the same files on linux installation

#Clean up
rm -f /chrootfile.sh

# Good idea to unmount the USB drive before exiting chroot
umount -a
exit

End-of-message

#Make that script executable
chmod +x /mnt/chrootfile.sh

#Execute it
arch-chroot /mnt ./chrootfile.sh

echo done
