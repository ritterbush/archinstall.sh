#!/bin/sh
# Arch Linux Post install setup script
# After reboot and login enter startx to start dwm

password=password
username=username

# Update pkg list
echo "$password" | sudo -S pacman -Syu

# Xorg server, shell, terminal, editor, browser, varous packages my scripts use, and extras
(echo; echo; echo) | sudo pacman -S xorg xorg-xinit zsh git alacritty neovim firefox picom xwallpaper sxiv python-pywal neofetch htop

# Download Fall wallpaper from Pexels under CC0 license
mkdir -p ~/Pictures/Wallpapers
curl https://images.pexels.com/photos/33109/fall-autumn-red-season.jpg > ~/Pictures/Wallpapers/fall-autumn-red-season.jpg

# Generate py-wal cache files before building dwm and dmenu
wal -i ~/Pictures/Wallpapers/fall-autumn-red-season.jpg
sleep 2

# Directory for building programs from source
mkdir ~/Programs

# Get my dwm/dmenu desktop environment, various dotfiles, and scripts
git clone https://github.com/ritterbush/files ~/Programs/

# xinitrc
cp ~/Programs/.xinitrc ~/.xinitrc

# zshrc
cp ~/Programs/.zshrc ~/.zshrc

# change shell to zsh
(echo "$password"; echo /bin/zsh) | chsh 

# shell scripts, neovim config and plugins, alacritty config 
cp -r ~/Programs/.local ~/
cp -r ~/Programs/.config ~/

# picom compositor config
mkdir -p ~/.config/picom
cp /etc/xdg/picom.conf.example ~/.config/picom/picom.conf

# Setup colors and opacity, and these also build and install dwm and dmenu
# Run again with different numbers to change

~/.local/bin/alacritty-opacity.sh 70
#~/.local/bin/dwm-opacity.sh 70
sed -i "s/static const unsigned int baralpha = .*/static const unsigned int baralpha = 0xb3;/" ~/Programs/dwm/config.def.h
#~/.local/bin/wallpaper-and-colors.sh ~/Pictures/Wallpapers/fall-autumn-red-season.jpg
sed -i "5s|.*|filepath=/home/${username}/Pictures/Wallpapers/fall-autumn-red-season.jpg|" "$HOME"/.local/bin/wallpaper-and-colors.sh
xwallpaper --zoom ~/Pictures/Wallpapers/fall-autumn-red-season.jpg
sed -i "s/static const char norm_fg\[\] = .*/$(sed -n 1p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h
sed -i "s/static const char norm_bg\[\] = .*/$(sed -n 2p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h
sed -i "s/static const char norm_border\[\] = .*/$(sed -n 3p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h
sed -i "s/static const char sel_fg\[\] = .*/$(sed -n 5p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h
sed -i "s/static const char sel_bg\[\] = .*/$(sed -n 6p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h
sed -i "s/static const char sel_border\[\] = .*/$(sed -n 7p "$HOME"/.cache/wal/colors-wal-dwm.h)/" "$HOME"/Programs/dwm/config.def.h

sed -i "s/^.*\[SchemeNorm\].*/$(sed -n 3p "$HOME"/.cache/wal/colors-wal-dmenu.h)/" "$HOME"/Programs/dmenu/config.def.h
sed -i "s/^.*\[SchemeSel\].*/$(sed -n 4p "$HOME"/.cache/wal/colors-wal-dmenu.h)/" "$HOME"/Programs/dmenu/config.def.h
sed -i "s/^.*\[SchemeOut\].*/$(sed -n 5p "$HOME"/.cache/wal/colors-wal-dmenu.h)/" "$HOME"/Programs/dmenu/config.def.h
colorNewHighlight=$(sed -n 7p "$HOME"/.cache/wal/colors)
colorNewHighlight=$(echo "$colorNewHighlight" | sed "s/^/\"/")
colorNewHighlight=$(echo "$colorNewHighlight" | sed "s/$/\"/")
color2=$(grep "\[SchemeSel\] =" "$HOME"/Programs/dmenu/config.def.h)
color2=$(echo "$color2" | sed "s/^.*, //")
color2=${color2% \},}
color3=$(grep "\[SchemeNorm\] =" "$HOME"/Programs/dmenu/config.def.h)
color3=$(echo "$color3" | sed "s/^.*, //")
color3=${color3% \},}
sed -i "s/^.*\[SchemeSelHighlight\] =.*/        \[SchemeSelHighlight\] = \{ ${colorNewHighlight}, ${color2} \},/" "$HOME"/Programs/dmenu/config.def.h
sed -i "s/^.*\[SchemeNormHighlight\] =.*/        \[SchemeNormHighlight\] = \{ ${colorNewHighlight}, ${color3} \},/" "$HOME"/Programs/dmenu/config.def.h

cd "$HOME"/Programs/dwm/ && sudo make clean install
cd "$HOME"/Programs/dmenu/ && sudo make clean install

# Delete password given by archinstall.sh
sed -i "s/^password=.*/password=password/" /home/"$username"/archsetup.sh

systemctl reboot

echo done

