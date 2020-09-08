#!/bin/sh

password=password

# Arch Linux Post install setup script
(echo "$password"; echo) | sudo pacman -Syu

# Xorg server, terminal, editor, browser, varous packages my scripts use, and whatever
(echo; echo; echo) | sudo pacman -S xorg xorg-init zsh git alacritty neovim firefox picom xwallpaper sxiv python-pywal neofetch htop

# Directory for building programs from source
mkdir ~/Programs
cd ~/Programs

# Get my dwm/dmenu desktop environment, various dotfiles, and scripts
git clone https://github.com/ritterbush/files

# Build and install dwm and dmenu
mv ~/Programs/files/dwm ~/Programs/dwm
mv ~/Programs/files/dmenu ~/Programs/dmenu
cd ~/Programs/dwm
(echo) | sudo make clean install
cd ~/Programs/dmenu
(echo) | sudo make clean install

# xinitrc
cp ~/Programs/files/.xinitrc ~/.xinitrc

# zshrc
cp ~/Programs/files/.zshrc ~/.zshrc

# shell scripts, neovim config and plugins, alacritty config 
cp -r ~/Programs/files/.local ~/.local
cp -r ~/Programs/files/.config ~/.config

# picom compositor config
mkdir -p ~/.config/picom
cp /etc/xdg/picom.conf.example ~/.config/picom/picom.conf

echo done

