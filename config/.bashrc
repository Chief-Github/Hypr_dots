#
# ~/.bashrc
# Made by Chief-Github
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias wbb='nohup setsid waybar >> /dev/null 2>&1 &'
# PS1='[\u@\h \W]\$ '
fastfetch --config ~/.config/fastfetch/fastneofetch.jsonc #A smaller fastfetch for normal terminal usage
eval "$(starship init bash)"
alias ls='lsd -a'
# alias cat='bat'
alias wpe='linux-wallpaperengine --screen-root eDP-1 --scaling fill'
alias vwp='mpvpaper -vs -o "panscan=1.0 loop-playlist no-audio" eDP-1'
eval "$(thefuck --alias)"
alias pkexec='pkexec env XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY GTK_THEME=Adwaita:dark'
alias mon='sudo airmon-ng start wlan0'
alias monstop='sudo airmon-ng stop wlan0mon'
alias monoff='sudo airmon-ng stop wlan0mon && sudo systemctl restart NetworkManager'
alias monhelp='echo mon = start - monstop = stop - monoff = restart NM and stop'
export PATH="$HOME/.local/bin:$PATH"
alias ccc='cd ~/scratch && claude'
#alias gen=$'matugen image "$(swww query | grep -oP \'(?<=image: ).*\')"' && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg /dev/null 2>&1
#alias gen='matugen image "$(swww query | grep -oP '"'"'(?<=image: ).*'"'"')" && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg'
alias gen='~/.config/hypr/scripts/gen_paper_images.sh'
alias lsl="lsd -al"
alias vencord="bash ~/Downloads/vencord.sh"
alias tor-start="sudo systemctl start tor"
alias tor-stop="sudo systemctl stop tor"
alias radioEV="rtl_433 -f 433.92M -f 868M -H 60 -M level -F kv -F json:street_haul_$(date +%F).json"
alias firebox="firejail --noprofile --private=~/firejail-dl --dbus-user=none --dbus-system=none firefox -no-remote"
alias server="ssh server"
alias hlab="ssh hlab"

ask() {
  claude -p --append-system-prompt "$(cat ~/Documents/shh.md)" "$*"
}

# Arch
archbox() {
  docker run -it --rm -h archbox --name archbox \
    -v "$HOME/docker-files/arch-box/shared:/share" \
    archlinux bash -c "pacman -Sy; exec bash"
}

# Debian
debianbox() {
  docker run -it --rm -h debianbox --name debianbox \
    -v "$HOME/docker-files/debian-box/shared:/share" \
    debian bash
}

# Ubuntu
ubuntubox() {
  docker run -it --rm -h ubuntubox --name ubuntubox \
    -v "$HOME/docker-files/ubuntu-box/shared:/share" \
    ubuntu bash
}

# Fedora
fedorabox() {
  docker run -it --rm -h fedorabox --name fedorabox \
    -v "$HOME/docker-files/fedora-box/shared:/share" \
    fedora bash
}

# Alpine
alpinebox() {
  docker run -it --rm -h alpinebox --name alpinebox \
    -v "$HOME/docker-files/alpine-box/shared:/share" \
    alpine sh
}

# Claude
claudebox() {
	docker run -it --rm -h claude \
	 -v ~/docker-files/claude-docker/.claude:/home/chief/.claude \
	 -v ~/docker-files/claude-docker/shared:/home/chief/shared \
	claudebox
}
export PATH="$HOME/go/bin:$PATH"
