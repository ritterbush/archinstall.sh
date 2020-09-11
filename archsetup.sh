#!/bin/sh
# Arch Linux Post install setup script
# After reboot and login enter startx to start dwm

password=password
username=username

# Update pkg list
echo "$password" | sudo pacman -Syu

# Xorg server, shell, terminal, editor, browser, varous packages my scripts use, and extras
(echo; echo; echo) | sudo pacman -S xorg xorg-xinit zsh git alacritty neovim firefox picom xwallpaper sxiv python-pywal neofetch htop

# Download Fall wallpaper from Pexels under CC0 license
mkdir -p ~/Pictures/Wallpapers
curl https://images.pexels.com/photos/33109/fall-autumn-red-season.jpg > ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

# Generate py-wal cache files before building dwm and dmenu
wal -i ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

# Directory for building programs from source
mkdir ~/Programs

# Get my dwm/dmenu desktop environment, various dotfiles, and scripts
git clone https://github.com/ritterbush/files ~/Programs/

# Move dwm and dmenu so colors will be set with py-wal before building
mv ~/Programs/files/dwm ~/Programs/
mv ~/Programs/files/dmenu ~/Programs/

# xinitrc
cp -f ~/Programs/files/.xinitrc ~/

# zshrc
cp -f ~/Programs/files/.zshrc ~/

# change shell to zsh
(echo "$password"; echo /bin/zsh) | chsh 

# shell scripts, neovim config and plugins, alacritty config 
cp -rf ~/Programs/files/.local ~/
cp -rf ~/Programs/files/.config ~/

# picom compositor config
mkdir -p ~/.config/picom
cp /etc/xdg/picom.conf.example ~/.config/picom/picom.conf

# Setup colors and opacity, and these also build and install dwm and dmenu
# Run again with different numbers to change

~/.local/bin/alacritty-opacity.sh 70
~/.local/bin/dwm-opacity.sh 70
~/.local/bin/wallpaper-and-colors.sh ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

# Delete password given by archinstall.sh
sed -i "s/password=.*/password=password/" /home/"$username"/archsetup.sh


systemctl reboot

echo done

