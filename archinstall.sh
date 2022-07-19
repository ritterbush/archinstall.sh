#!/bin/sh

show_usage() {
    printf "Usage:\n\n  %s [options [parameters]]\n" "$0"
    printf "\n"
    printf "Installs Arch Linux on UEFI systems. See Checklist after Options.\n"
    printf "\n"
    printf "Options [parameters]:\n"
    printf "\n"
    printf "  -u|--username [username]   Specify username; if special characters are
                             used use single quotes.\n"
    printf "  -p|--password [password]   Specify password; if special characters are
                             used use single quotes.\n"
    printf "  -o|--hostname [hostname]   Specify hostname:~ the name of the computer 
                             of this operating system.\n"
    printf "  -t|--timezone [timezone]   Specify timezone; use single quotes.
                             To see options: ls /usr/share/zoneinfo\n"
    printf "  -s|--staticip [staticip]   Specify local static ip address (setup with
                             your router). Do not use if no local static 
                             ip address has been set up. Use single quotes.\n"
    printf "  -f|--full                  Install ComfyOS setup after basic Arch 
                             installation.\n"
    printf "  -a|--amdcpu                Use amd cpu microcode.\n"
    printf "  -i|--intelcpu              Use intel cpu microcode.\n"
    printf "  --wipe-disk                Wipes the disk (ALL DATA ERASED!) of
                             /dev/--diskname specified by -d|--diskname\n"
    printf "  -d|--diskname [diskname]   Specify diskname to be wiped; e.g.
                             'sdc'. Do not include /dev/. \n"
    printf "  -h|--help                  Print this help.\n"
    printf "\n"
    printf "Checklist:\n"
    printf "        -Download latest Arch ISO from https://archlinux.org/download/
        -Verify PGP Signature and/or Checksums of downloaded Arch ISO
        -Create bootable
        -Boot into UEFI live environment
        -Set keyboard layout if it is not US
        -Confirm UEFI mode with: ls /sys/firmware/efi/efivars
        -Use ping to ensure internet connection
        -Configure network router if desired (e.g. to assign a static IP)
                    set static ip option -s accordingly, if so
        -Get this script with curl (if reading this somewhere else):
                    curl https://raw.githubusercontent.com/ritterbush/archinstall.sh/master/archinstall.sh > archinstall.sh
        -Alternatively, plug in a USB device with this script, and mkdir and
                    mount it to /mnt/usb (use lsblk to see USB device path)
        -Give the script executable permissions with:
                    chmod +x mnt/usb/path/to/archinstall.sh
        -If using --wipe-disk, run lsblk and confirm the correct disk to wipe.
                    This option will make an efi partition of 512M, a root
                    partition of 32G, and a home partition with the remaining
                    space
        -If not using --wipe-disk, mount the root partition to /mnt then
                    mkdir -p /mnt/efi and mount the efi drive to that location;
                    create further directories and mount drives to them if
                    needed
        -View the script with the less command and install a text editor
                    (pacman -S nano vim) to edit it
        -Run the script with the proper options and arguments with:
                    ./archinstall.sh options [arguments]"
exit
}

username=newuser # Change with -u
password=password # Change with -p
timezone=America/Los_Angeles # Change with -t. To see options: ls /usr/share/zoneinfo
hostname=arch # Change with -o
staticip=127.0.1.1 # Change with -s
mirrors=default # Change with --usa-sw-mirrors (My preference mirrors; hidden)
full=false # If -f option used, fully install ComfyOS desktop, otherwise do a basic installation 
cpu=other # Must be other or amd or intel
wipe=false # If -w option is used, wipes disk clean and makes partitions according to the below variables
disk=none # Wipes the disk '/dev/disk', can be changed with -d; use the letters that follow /dev/ and that specify the disk to wipe
efipart="$disk"1 # Same name as disk above but with 1 at the end
rootpart="$disk"2 # Same name as disk above but 2 instead of 1 at the end
homepart="$disk"3 # Same name as disk above but 3 instead of 2 at the end

if [ $# -eq 0 ]; then
    show_usage
fi

while [ -n "$1" ]; do
    case "$1" in
        --username|-u)
            if [ -n "$2"  ]
            then
                username="$2"
                shift 2
            else
                echo "-u flag requires a username"
                exit
            fi
            ;;
        --password|-p)
            if [ -n "$2"  ]
            then
                password="$2"
                shift 2
            else
                echo "-p option requires a password"
                exit
            fi
            ;;
        --hostname|-o)
            if [ -n "$2"  ]
            then
                hostname="$2"
                shift 2
            else
                echo "-o option requires a hostname"
                exit
            fi
            ;;
        --timezone|-t)
            if [ -n "$2"  ]
            then
                timezone="$2"
                shift 2
            else
                echo "-t option requires a timezone"
                exit
            fi
            ;;
        --staticip|-s)
            if [ -n "$2"  ]
            then
                staticip="$2"
                shift 2
            else
                echo "-s option requires a static ip address"
                exit
            fi
            ;;
        --full|-f)
            full=true
            shift
            ;;
        --amdcpu|-a)
            cpu=amd
            shift
            ;;
        --intelcpu|-i)
            cpu=intel
            shift
            ;;
        --wipe-disk)
            wipe=true
            shift
            ;;
        --diskname|-d)
            if [ -n "$2"  ]
            then
                disk="$2"
                efipart="$disk"1 # Same name as disk above but with 1 at the end
                rootpart="$disk"2 # Same name as disk above but 2 instead of 1 at the end
                homepart="$disk"3 # Same name as disk above but 3 instead of 2 at the end
                shift 2
            else
                echo "-d option requires a diskname"
                exit
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        --usa-sw-mirrors) # My preference mirrors; hidden
            mirrors="usa-sw"
            shift
            ;;
        *)
            echo "Unknown option $1"
            show_usage
            ;;
    esac
done

# If wipe disk option used, check a diskname has been given
[ "$wipe" = true ] && [ "$disk" = none ] && { echo "Specify diskname with -d|--diskname when using --wipe-disk option"; exit; }

# Update System Clock
timedatectl set-ntp true
sleep 1 # Allow a moment to syncronize

if [ $wipe = true ] # --wipe-disk option
then
    # Wipe the disk, and in particular wipe the partitions previously made first, if this script has been already run 
    ls /dev/"$homepart" > /dev/null 2>&1 && wipefs --all --force /dev/"$homepart"
    sleep 1
    ls /dev/"$rootpart" > /dev/null 2>&1 && wipefs --all --force /dev/"$rootpart"
    sleep 1
    ls /dev/"$efipart" > /dev/null 2>&1 && wipefs --all --force /dev/"$efipart"
    sleep 1
    ls /dev/"$disk" > /dev/null 2>&1 && wipefs --all --force /dev/"$disk"
    sleep 1

    # Create GPT partition table
    (echo g; echo w) | fdisk /dev/"$disk"
    sleep 2

    # Create efi, root, and home partitions; efi is 512MB, root 32GB, and home is rest of drive
    (echo n; echo; echo; echo +512M; echo t; echo 1; echo n; echo; echo; echo +32G; echo n; echo; echo; echo; echo p; echo w) | fdisk /dev/"$disk"
    sleep 2

    # Make file systems and mount
    mkfs.fat -F32 /dev/"$efipart"
    mkfs.ext4 /dev/"$rootpart"
    mkfs.ext4 /dev/"$homepart"

    mount /dev/"$rootpart" /mnt # For a proper fstab entry, mount root partition first and then create additional files and mount any needed partitions to them
    mkdir -p /mnt/efi
    mkdir -p /mnt/home
    mount /dev/"$efipart" /mnt/efi # "Tip: /efi is a replacement . . ." See reference: https://wiki.archlinux.org/index.php/EFI_system_partition#Mount_the_partition
    mount /dev/"$homepart" /mnt/home
fi # End of --wipe-disk option

pacman -Syy
echo Y | pacman -S archlinux-keyring

# Personal preference with --usa-sw-mirrors flag: Send good USA sites to the top of the mirrorlist (edit with your favorites)
[ $mirrors = "usa-sw" ] && sed -i '6i\Server = http://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = https://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = http://arch.mirror.constant.com/$repo/os/$arch\nServer = https://arch.mirror.constant.com/$repo/os/$arch\nServer = http://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = https://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = http://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = http://ca.us.mirror.archlinux-br.org/$repo/os/$arch' /etc/pacman.d/mirrorlist

# Install just the bare minimum until chroot
pacstrap /mnt base

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Create the chroot script that executes inside the new Arch system 
cat > /mnt/chrootfile.sh <<"End-of-message"
# Set Timezone
ln -sf /usr/share/zoneinfo/"$3" /etc/localtime
hwclock --systohc

# Localization
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
sed -i "s/#en_US ISO-8859-1/en_US ISO-8859-1/" /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Create hostname file with hostname
echo "$4" > /etc/hostname

# Create hosts file
printf "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n%s\t%s.localdomain\t%s\n" "$5" "$4" "$4" >> /etc/hosts

# Give root a password, add username to wheel, audio, etc. groups and give username same password as root
(echo "$2"; echo "$2") | passwd
useradd -m -G wheel,audio,optical,disk,storage,video "$1"
(echo "$2"; echo "$2") | passwd "$1"

# Update available packages list
pacman -Syy

# Grab more base packages and cpu specific microcode
[ "$7" = amd ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware amd-ucode
[ "$7" = intel ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware intel-ucode
[ "$7" = other ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware

# Give the wheel group root priviledges
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

# Add Pacman the videogame character to the pacman progress bar, make pacman more colorful, and see pkg versions
sed -i "/^#VerbosePkgLists/aILoveCandy" /etc/pacman.conf # Note lack of 's' at start; 'a' to insert line after, 'i' before 
sed -i "s/^#Color/Color/" /etc/pacman.conf
sed -i "s/^#VerbosePkgLists/VerbosePkgLists/" /etc/pacman.conf

# Enable 32-bit library support
sed -i "/^#\[multilib\]/aQQ" /etc/pacman.conf # Mark correct #Include for below; note again lack of 's' at start
sed -i -z "s/QQ\n#Include/Include/" /etc/pacman.conf # -z separate lines by NUL chars
sed -i "s/^#\[multilib\]/[multilib]/" /etc/pacman.conf

# Use all cores when compiling from source
sed -i "s/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf

# Download database file for 32-bit (multilib) libraries
pacman -Sy

# Network Manager
echo Y | pacman -S networkmanager
systemctl enable NetworkManager

# Bootloader install and setup
echo Y | pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB #https://wiki.archlinux.org/index.php/GRUB#UEFI_systems
grub-mkconfig -o /boot/grub/grub.cfg

if [ "$6" = true ] # -f option
then
	# Download ComfyOS setup script and run it as the user
	curl https://raw.githubusercontent.com/ritterbush/ComfyOS/master/setup-arch-based.sh > /home/"$1"/setup-arch-based.sh
	chown "${1}:$1" /home/"$1"/setup-arch-based.sh
	chmod +x /home/"$1"/setup-arch-based.sh

	# Run it as the user
	echo "$2" | sudo -S su - "$1" -c "sh /home/${1}/setup-arch-based.sh -c -p $2"
fi # End of -f option

# Clean up
# Can't do this outside of script since it will complain about being read-only
rm -f /chrootfile.sh

# Exit chroot
exit
End-of-message

# Make that script executable
chmod +x /mnt/chrootfile.sh

# Execute it
arch-chroot /mnt ./chrootfile.sh "$username" "$password" "$timezone" "$hostname" "$staticip" "$full" "$cpu"

echo "$0 Completed Successfully"
