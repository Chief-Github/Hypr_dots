#!/usr/bin/env bash
########################################
#  Chief-Github's dotfiles installer!! #
########################################
### https://github.com/Chief-Github ####
########################################

set -euo pipefail

trap 'echo -e "\n\033[31m✖ Error on line $LINENO. Aborting.\033[0m"; exit 1' ERR


# ────────────────────────────────
#  🎨 COLORS + STYLES
# ────────────────────────────────
BOLD=$(printf '\033[1m')
DIM=$(printf '\033[2m')
RED=$(printf '\033[31m')
GRN=$(printf '\033[32m')
YEL=$(printf '\033[33m')
BLU=$(printf '\033[34m')
CYN=$(printf '\033[36m')
RST=$(printf '\033[0m')

ok()   { printf "${GRN}✔${RST} %s\n" "$*"; }
warn() { printf "${YEL}▲${RST} %s\n" "$*"; }
err()  { printf "${RED}✖${RST} %s\n" "$*"; }
msg()  { printf "${CYN}›${RST} %s\n" "$*"; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_CONFIG_DIR="${SCRIPT_DIR}/config"


if ! command -v pacman >/dev/null 2>&1; then
  err "This script is for Arch-based systems (pacman)."; exit 1
fi

# sanity check
if [[ ! -d "$REPO_CONFIG_DIR" ]]; then
  err "Config dir not found: $REPO_CONFIG_DIR"
  exit 1
fi

ts="$(date +%Y%m%d_%H-%M)"

DOTFILES_DIR="$HOME/.config"

show_banner() {
  clear
  cat <<EOF
${RED}┌──────────────────────────────────────────────┐${RST}
${RED}│${RST}   🧠  ${BOLD}Chief's Dotfile Installer v1.2 ${RST}       ${RED}│${RST}
${RED}└──────────────────────────────────────────────┘${RST}
EOF
  echo
}


show_banner

read -rp "${BOLD}This script is still being developed, but it should work :) do you want to continue?${RST} (y/n) " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo ""
else
    exit 1
fi 
sleep 1
sudo -v

sleep 1
echo -e "${BOLD}${BLU}✨ Starting Dotfile Installation ✨${RST}"
sleep 1
show_banner
echo "----------------------------------------------------"
echo "Updating system...."
echo "----------------------------------------------------"
sudo pacman -Syu --noconfirm


core_fonts=(
  fontconfig
  libfontenc
  libxfont2
  gsfonts
  gnu-free-fonts
  noto-fonts
  noto-fonts-emoji
  ttf-nerd-fonts-symbols
  ttf-nerd-fonts-symbols-mono
  ttf-nerd-fonts-symbols-common
  otf-font-awesome
  xorg-fonts-encodings
  # adwaita-fonts           (not in all repos)
)

apps=(
  hyprland
  hyprpaper
  hypridle
  hyprlock
  xdg-desktop-portal-hyprland
  xdg-desktop-portal
  grim
  slurp
  brightnessctl
  gvfs
  pipewire 
  pipewire-alsa 
  pipewire-pulse 
  wireplumber
  waybar
  swaync
  kitty
  fastfetch
  firefox
  thunar
  swayosd
  code
  conky
  rofi
  wofi
  git
  base-devel
  pavucontrol
  cava
  nano
  bluez
  blueman
  bluez-utils
  cool-retro-term
  obsidian
  starship
  ark
  nwg-look
  hyprshot
  hyprpolkitagent
  swappy
  network-manager-applet
  gnome-weather
  playerctl
  spotify-launcher
  btop
  htop
  swww
  thefuck
  mako
  lsd
  inter-font
  mpv
)

config_files=(
    "hypr"
    "kitty"
    "waybar"
    "wofi"
    "Thunar"
    "neofetch"
    "starship.toml"
    "eww"
    "swaync"
    "btop"
    "rofi"
    "cava"
    "wlogout"
    "swayosd"
    "waypaper"
    "conky"
    "fastfetch"
    "quickshell"
)

aur_apps=(
  waypaper
  eww-git
  qdiskinfo
  tty-clock
  wlogout
  neofetch
  matugen
  quickshell
)


show_banner
echo "----------------------------------------------------"
echo "Installing fonts...."
echo "----------------------------------------------------"
sudo pacman -S --needed --noconfirm "${core_fonts[@]}"
fc-cache -fv

show_banner
echo "----------------------------------------------------"
echo "Installing pacman apps"
echo "----------------------------------------------------"
sudo pacman -S --needed --noconfirm "${apps[@]}"

sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service || true


show_banner
echo "----------------------------------------------------"
echo Installing AUR apps
echo "----------------------------------------------------"
if command -v yay >/dev/null 2>&1; then
  ok "yay already installed."
  else
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

yay -S --needed --noconfirm "${aur_apps[@]}"



show_banner
warn "!!!current configs will be deleted!!!"
read -rp "Do you want to back up current config files? (y/n): " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    backup_dir="$HOME/config_backup_${ts}"
    mkdir -p "$backup_dir"
    echo "Backing "$DOTFILES_DIR/*" up to $backup_dir …"
    sleep 2
    cp -r "$DOTFILES_DIR"/* "$backup_dir/"

    echo "---- Finished backing up! ----"
    sleep 2
else
    echo "---- Skipping backup ----"    
fi

# before copying
mkdir -p -- "$DOTFILES_DIR"
show_banner
echo "----------------------------------------------------"
echo Adding configs
echo "----------------------------------------------------"
for config in "${config_files[@]}"; do
#    # Deleting old versions
    rm -rf "$DOTFILES_DIR/$config"
#    # Copying new verison to ~/.config
#    cp -r "./config/$config" "$DOTFILES_DIR/"
#    echo "copying "./config/$config" to "$DOTFILES_DIR/""
done

# copy contents
cp -a -- "$REPO_CONFIG_DIR"/. "$DOTFILES_DIR"/


show_banner

echo "----------------------------------------------------"
echo "What theme do you want? (check GitHub for previews!)"
echo "1 = purple"
echo "2 = holiday"
echo "3 = sunset"
echo "----------------------------------------------------"

read -rp ": " choice

case "$choice" in
  1) theme="purple" ;;
  2) theme="holiday" ;;
  3) theme="sunset" ;;
  *) theme="purple" ;;
esac

mkdir -p ~/wallpaper
cp -a -- "${SCRIPT_DIR}/wallpaper/." ~/wallpaper/

# ---------------- Theme symlinks ----------------
ln -sf ~/.config/conky/themes/conky_$theme.conf ~/.config/conky/conky.conf
ln -sf ~/.config/kitty/themes/kitty_$theme.conf ~/.config/kitty/kitty.conf
ln -sf ~/.config/waybar/themes/waybar_$theme.css ~/.config/waybar/style.css
ln -sf ~/.config/starship-themes/starship_$theme.toml ~/.config/starship.toml
ln -sf ~/.config/eww/themes/eww_$theme.scss ~/.config/eww/eww.scss
ln -sf ~/.config/rofi/themes/rofi_$theme.rasi ~/.config/rofi/config.rasi
ln -sf ~/.config/swaync/themes/swaync_$theme.css ~/.config/swaync/style.css
ln -sf ~/.config/wlogout/themes/wlogout_$theme.css ~/.config/wlogout/style.css
ln -sf ~/.config/swayosd/themes/swayosd_$theme.css ~/.config/swayosd/style.css
mv ~/.config/.bashrc ~/
warn "Remember to log out and back in to apply system changes!"
warn "Also, make sure to check out ~/.config/hypr/hyprland.conf and alter your scaling"
echo "${BLU}┌──────────────────────────────────────────────┐${RST}
${BLU}│${RST}     ${BOLD}All installed!${RST}                           ${BLU}│${RST}
${BLU}│${RST}     ${BOLD}!Enjoy! :D${RST}                               ${BLU}│${RST}
${BLU}└──────────────────────────────────────────────┘${RST}"