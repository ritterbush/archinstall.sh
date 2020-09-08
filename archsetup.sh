#!/bin/sh

# Arch Linux Post install setup script

password=password

# Update pkg list
(echo "$password"; echo) | sudo pacman -Syu

# Xorg server, shell, terminal, editor, browser, varous packages my scripts use, and extras
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

# change shell to zsh
(echo /bin/zsh) | chsh 

# shell scripts, neovim config and plugins, alacritty config 
cp -r ~/Programs/files/.local ~/.local
cp -r ~/Programs/files/.config ~/.config

# picom compositor config
mkdir -p ~/.config/picom
cp /etc/xdg/picom.conf.example ~/.config/picom/picom.conf

echo done

