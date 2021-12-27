#!/bin/sh

# Options: -u username -p password -h -hostname -d disk -t timezone -s staticip
# Any options not specified will use the defaults below
# Option -w will wipe "disk", create new partitions on "disk", and install on "disk" .
# Without -w, it is assumed that you have already partitioned and mounted your drives correctly according to a uefi system
# Options -a or -i will install AMD or Intel cpu microcode (pick one or neither to install no microcode)

show_usage(){
    printf "Usage:\n\n  $0 [options [parameters]]\n"
    printf "\n"
    printf "Installs Arch Linux on UEFI systems.\n"
    printf "\n"
    printf "Options [parameters]:\n"
    printf "\n"
    printf "  -u|--username [username]   Specify username; if special characters are\n                             used use single quotes.\n"
    printf "  -p|--password [password]   Specify password; if special characters are\n                             used use single quotes.\n"
    printf "  -o|--hostname [hostname]   Specify hostname:~ the name of the computer\n                             of this operating system.\n"
    printf "  -t|--timezone [timezone]   Specify timezone; use single quotes.\n"    printf "  -s|--staticip [staticip]   Specify local static ip address (setup with\n                             your router). Do not use if no local static\n                             ip address has been set up. Use single quotes.\n"
    printf "  -f|--full                  Install ComfyOS setup after basic Arch\n                             installation.\n"
    printf "  -a|--amdcpu                Use amd cpu microcode.\n"  
    printf "  -i|--intelcpu              Use intel cpu microcode.\n"
    printf "  --wipe-disk                Wipes the disk (ALL DATA ERASED!) of\n                             /dev/--diskname specified by -d|--diskname\n"
    printf "  -d|--diskname [diskname]   Specify diskname to be wiped; e.g.\n                             'sdc'. Do not include /dev/. \n"  
    printf "  -h|--help                  Print this help.\n"
exit
}

username=newuser # Change with -u
password=password # Change with -p
timezone=America/Los_Angeles # Change with -t. To see options: ls /usr/share/zoneinfo
hostname=arch # Change with -o
staticip=127.0.1.1 # Change with -s
full=false # If -f option used, fully install ComfyOS desktop, otherwise do a basic installation 
cpu=other # Must be other or amd or intel
wipe=false # If -w option is used, wipes disk clean and makes partitions according to the below variables
disk=none # Wipes the disk '/dev/disk', can be changed with -d; use the letters that follow /dev/ and that specify the disk to wipe
efipart="$disk"1 # Same name as disk above but with 1 at the end
rootpart="$disk"2 # Same name as disk above but 2 instead of 1 at the end
homepart="$disk"3 # Same name as disk above but 3 instead of 2 at the end

# My own personal preference options
mirrors=default

<<COMMENT
        This script installs Arch Linux while making several assumptions: one, it installs only for UEFI systems. 
        It also provides USA specific repository mirrors (I will probably change this to something more general). 
        It also assumes that a network is connected and in use and that an Arch live environment is already booted into.
        
        It no longer assumes that the disk will be wiped clean and partitions created and mounted. For this, which makes only
        an efi partition of 512M, a root partition of 32G, and a home partition for the rest, you need to specify the -w (for wipe clean)
        option. Otherwise, it is assumeed that the partitions are created, that root is mounted to /mnt, and that any needed additional 
        folders are created therein with their respective partition mounts. From there it installs a very minimal base, base-devel, linux, 
        linux-firmware Arch Linux install, or a full install (via the -f option) of my own setup of ComfyOS
        
        I've added rudimentary getopts support, so now you can use any or all of the following options to change the above starting variables: 
        
        -u username -p password -h -hostname -d disk -t timezone -s staticip
         
        Also use -a, or -i, or -o alone (at the end is fine) for AMD, Intel or other cpu support.
        

        Checklist:
        Verify Signature/Checksums of downloaded Arch ISO;
        Create bootable;
        Boot into live environment;
        Set keyboard layout if it is not US;
        Confirm UEFI mode with: ls /sys/firmware/efi/efivars;
        Use lsblk to confirm that the disk variable set above matches;
        Use ping to ensure internet connection;
        Configure network router if desired (e.g. to assign a static IP--set static ip variable accordingly if so);
        Curl this script with the full https address to the raw file (curl https://raw.githubusercontent.com/ritterbush/archinstall.sh/master/archinstall.sh > archinstall.sh), 
        or, alternatively, mkdir and then mount a USB device with this script to /mnt/usb (use lsblk to see device paths);
        Give the script executable permissions with chmod +x /path/to/archinstall.sh (type pwd to see current directory);
        
        You can view the script with the less command (vim keys to navigate), and
        change any initial variables with sed -i--e.g., sed -i 's/password=password/password=supersecret' /path/to/archinstall.sh  , 
        or you could edit it first with a text editor like a sane person, and even copy it to your own site and curl it.
        
        LICENSE: MIT, GPLv3, or Abandonware, whichever you prefer
        WARRANTY: Zero, and I am sorry about what that did there
        
        Run script:
        /path/to/archinstall.sh

COMMENT

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
        --hostname|-h)
            if [ -n "$2"  ]
            then
                hostname="$2"
                shift 2
            else
                echo "-h option requires a hostname"
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
                shift 2
            else
                echo "-d option requires a diskname"
                exit
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        --usa-sw-mirrors)
            mirrors='usa-sw'
            shift
            ;;
        *)
            echo "Unknown option $1"
            show_usage
            ;;
    esac
done

[ $wipe = true ] && [ $disk = none ] && echo "Specify diskname with -d|--diskname when using --wipe-disk option"; exit

echo "Past wipefs + disk check"
exit 0
exit 1
exit 0
exit;exit;exit
# Update System Clock
timedatectl set-ntp true

if [ $wipe = true ] # -w option
then

    exit 0	

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
fi #end of -w option

pacman -Syy
echo Y | pacman -S archlinux-keyring

# Personal preference with --usa-sw-mirrors flag: Send good USA sites to the top of the  mirrorlist
[ $mirrors = 'usa-sw' ] && sed -i '6i\Server = http://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = https://mirror.arizona.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch\nServer = http://arch.mirror.constant.com/$repo/os/$arch\nServer = https://arch.mirror.constant.com/$repo/os/$arch\nServer = http://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = https://mirrors.kernel.org/archlinux/$repo/os/$arch\nServer = http://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rit.edu/archlinux/$repo/os/$arch\nServer = http://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = https://mirrors.rutgers.edu/archlinux/$repo/os/$arch\nServer = http://ca.us.mirror.archlinux-br.org/$repo/os/$arch' /etc/pacman.d/mirrorlist

# Install just the bare minimum until chroot
pacstrap /mnt base

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Create the chroot script that executes inside the new Arch system 
cat > /mnt/chrootfile.sh <<End-of-message
# Set Timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc

# Localization
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Sets LANG=en_US.UTF-8 as the BASH keyboard
#export LANG=en_US.UTF-8

# Create hostname file with hostname
echo "$hostname" > /etc/hostname

# Create hosts file
echo -e '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n'"$staticip\t""$hostname"'.localdomain\t'"$hostname" | cat >> /etc/hosts

# Give root a password, add username to wheel, audio, etc. groups and give username same password as root
(echo "$password"; echo "$password") | passwd
useradd -m -G wheel,audio,optical,disk,storage,video "$username"
(echo "$password"; echo "$password") | passwd "$username"

# Update available packages list
pacman -Syy

# Grab more base packages and cpu specific microcode
[ "$cpu" == amd ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware amd-ucode
[ "$cpu" == intel ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware intel-ucode
[ "$cpu" == other ] && (echo; echo; echo Y) | pacman -S base-devel linux linux-firmware

# Give the wheel group root priviledges
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Add Pacman the videogame character to the pacman progress bar, make pacman more colorful, and see pkg versions
sed -i "/^#VerbosePkgLists/aILoveCandy" /etc/pacman.conf
sed -i "s/^#Color/Color/" /etc/pacman.conf
sed -i "s/^#VerbosePkgLists/VerbosePkgLists/" /etc/pacman.conf

# Enable 32-bit library support
sed -i "/^#\[multilib\]/aQQ" /etc/pacman.conf
sed -i -z "s/QQ\n#Include/Include/" /etc/pacman.conf
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
#mkdir /efi
#mount /dev/$efipart /efi #https://wiki.archlinux.org/index.php/EFI_system_partition#Mount_the_partition
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB #https://wiki.archlinux.org/index.php/GRUB#UEFI_systems
grub-mkconfig -o /boot/grub/grub.cfg

# Clean up
rm -f /chrootfile.sh

if [ $full = true ] # -f option
then
	# Grab post-install setup script (to run after verifying that things are basically working)
	curl https://raw.githubusercontent.com/ritterbush/ComfyOS/master/setup-arch-based.sh > setup-arch-based.sh
	mv /setup-arch-based.sh /home/"$username"/setup-arch-based.sh
	chown "$username":"$username" /home/"$username"/setup-arch-based.sh
	chmod +x /home/"$username"/setup-arch-based.sh

	# Running it as username
	echo "$password" | sudo -S su - "$username" -c "sh /home/"$username"/setup-arch-based.sh -c -p ${password}"

fi # End of -f option

# Good idea to unmount drives before exiting chroot
umount -a
exit
End-of-message

# Make that script executable
chmod +x /mnt/chrootfile.sh

# Execute it
arch-chroot /mnt ./chrootfile.sh

echo done
