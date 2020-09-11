#!/bin/sh

# Arch Linux Post install setup script

# Update pkg list
(echo "$password"; echo) | sudo pacman -Syu

# Xorg server, shell, terminal, editor, browser, varous packages my scripts use, and extras
(echo; echo; echo) | sudo pacman -S xorg xorg-xinit zsh git alacritty neovim firefox picom xwallpaper sxiv python-pywal neofetch htop

# Directory for building programs from source
mkdir ~/Programs
cd ~/Programs

# Get my dwm/dmenu desktop environment, various dotfiles, and scripts
git clone https://github.com/ritterbush/files

# Move dwm and dmenu so colors will be set with py-wal before building
mv ~/Programs/files/dwm ~/Programs/dwm
mv ~/Programs/files/dmenu ~/Programs/dmenu

# Download Fall wallpaper from Pexels under CC0 license
mkdir -p ~/Pictures/Wallpapers
curl https://images.pexels.com/photos/33109/fall-autumn-red-season.jpg > ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

# xinitrc
cp ~/Programs/files/.xinitrc ~/.xinitrc

# zshrc
cp ~/Programs/files/.zshrc ~/.zshrc

# change shell to zsh
(echo "$password"; echo /bin/zsh) | chsh 

# shell scripts, neovim config and plugins, alacritty config 
cp -r ~/Programs/files/.local ~/.local
cp -r ~/Programs/files/.config ~/.config

# picom compositor config
mkdir -p ~/.config/picom
cp /etc/xdg/picom.conf.example ~/.config/picom/picom.conf

# Setup colors and opacity, and these also build and install dwm and dmenu
# Run again with different numbers or wallpaper to change
~/.local/bin/alacritty-opacity.sh 70
~/.local/bin/dwm-opacity.sh 70
~/.local/bin/wallpaper-and-colors.sh ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

startx

echo done

