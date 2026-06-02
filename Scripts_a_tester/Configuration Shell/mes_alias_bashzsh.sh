# =============================================================================
# ALIAS SYSTÈME ET NAVIGATION
# =============================================================================

# Navigation et listing améliorés
alias ls='ls --color=auto --group-directories-first'
alias la='ls -la'
alias ll='ls -lh'
alias l='ls -CF'
alias lt='ls -laht'  # Tri par date
alias lr='ls -lahR'  # Récursif
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Recherche et filtrage
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rg='rg --sort path --color=auto'
alias find='find 2>/dev/null'

# =============================================================================
# ALIAS PACMAN ET GESTIONNAIRE DE PAQUETS
# =============================================================================

# Pacman de base
alias pacinstall='sudo pacman -S'
alias pacsearch='pacman -Ss'
alias pacremove='sudo pacman -R'
alias pacinfo='pacman -Si'
alias paclist='pacman -Q'
alias pacfiles='pacman -Ql'

# Mises à jour
alias update='sudo pacman -Syyu'
alias upall='yay -Syu --noconfirm'
alias upmax='sudo pacman -Syu && yay -Syu && flatpak update'
alias pacup='sudo pacman -Syu'
alias pacupd='sudo pacman -Syy'

# AUR et yay
alias yayinstall='yay -S'
alias yaysearch='yay -Ss'
alias yayremove='yay -R'
alias yayupdate='yay -Syu'
alias yayclean='yay -Sc'

# Flatpak
alias flatinstall='flatpak install'
alias flatsearch='flatpak search'
alias flatremove='flatpak uninstall'
alias flatupdate='flatpak update'
alias flatlist='flatpak list'

# Nettoyage et maintenance
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanorphans='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanpkg='sudo pacman -Sc'
alias cleanall='sudo pacman -Scc'
alias pacdiff='sudo pacdiff'

# =============================================================================
# ALIAS SYSTÈME ET MONITORING
# =============================================================================

# Mémoire et processus
alias freemem="free -mt"
alias meminfo='cat /proc/meminfo'
alias ps='ps aux'
alias top='htop'
alias cpuinfo='cat /proc/cpuinfo'
alias df='df -h'
alias du='du -h'
alias dus='du -sh'

# Système
alias hw="hwinfo --short"
alias ff="fastfetch"
alias neofetch='neofetch'
alias audio="pactl info | grep 'Server Name'"
alias kernel="ls /usr/lib/modules"
alias uptime='uptime -p'

# Réseau
alias ping='ping -c 5'
alias ports='netstat -tuln'
alias myip='curl -s ifconfig.me'
alias speedtest='speedtest-cli'

# =============================================================================
# ALIAS CONFIGURATION ET ÉDITION
# =============================================================================

# Éditeurs de configuration système
alias npacman="sudo $EDITOR /etc/pacman.conf"
alias nmakepkg="sudo $EDITOR /etc/makepkg.conf"
alias nmirrorlist="sudo $EDITOR /etc/pacman.d/mirrorlist"
alias nfstab="sudo $EDITOR /etc/fstab"
alias nnsswitch="sudo $EDITOR /etc/nsswitch.conf"
alias nsamba="sudo $EDITOR /etc/samba/smb.conf"
alias nhosts="sudo $EDITOR /etc/hosts"
alias nhostname="sudo $EDITOR /etc/hostname"
alias nenvironment="sudo $EDITOR /etc/environment"

# Configuration shell
alias nb="$EDITOR ~/.bashrc"
alias nz="$EDITOR ~/.zshrc"
alias nf="$EDITOR ~/.config/fish/config.fish"

# Configuration applications
alias nneofetch="$EDITOR ~/.config/neofetch/config.conf"
alias nfastfetch="$EDITOR ~/.config/fastfetch/config.jsonc"
alias nalacritty="$EDITOR ~/.config/alacritty/alacritty.toml"
alias nkitty="$EDITOR ~/.config/kitty/kitty.conf"
alias nvim="$EDITOR ~/.config/nvim/init.lua"

# =============================================================================
# ALIAS GESTION DES SERVICES ET SYSTÈME
# =============================================================================

# Systemd
alias jctl="journalctl -p 3 -xb"
alias sysfailed="systemctl list-units --failed"
alias sysstatus="systemctl status"
alias sysrestart="sudo systemctl restart"
alias sysstop="sudo systemctl stop"
alias sysstart="sudo systemctl start"
alias sysenable="sudo systemctl enable"
alias sysdisable="sudo systemctl disable"

# Mirrors et optimisation
alias mirrors="sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrors-fast="sudo reflector --latest 20 --number 5 --sort rate --save /etc/pacman.d/mirrorlist"

# =============================================================================
# ALIAS UTILITAIRES ET RACCOURCIS
# =============================================================================

# Historique des paquets
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl"

# Logs
alias lpacman="bat /var/log/pacman.log"
alias lsystem="journalctl -f"

# Permissions et sécurité
alias fix-permissions="sudo chown -R $USER:$USER ~/.config ~/.local"
alias fix-home="sudo chown -R $USER:$USER $HOME"

# Sessions et environnements
alias xd="ls /usr/share/xsessions"
alias xdw="ls /usr/share/wayland-sessions"

# Changement de shell
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Maintenant déconnectez-vous.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Maintenant déconnectez-vous.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Maintenant déconnectez-vous.'"

# Sauvegarde et restauration
alias bupskel='cp -Rf /etc/skel ~/.skel-backup-$(date +%Y.%m.%d-%H.%M.%S)'
alias cb='cp /etc/skel/.bashrc ~/.bashrc && exec bash'
alias cz='cp /etc/skel/.zshrc ~/.zshrc && echo "Copié."'
alias cf='cp /etc/skel/.config/fish/config.fish ~/.config/fish/config.fish && echo "Copié."'

# Arrêt et redémarrage
alias ssn="sudo shutdown now"
alias sr="reboot"
alias reboot="sudo reboot"
alias shutdown="sudo shutdown"

# =============================================================================
# ALIAS GESTION DES PROCESSUS ET APPLICATIONS
# =============================================================================

# Tuer des processus
alias kc='killall conky'
alias kp='killall polybar'
alias kpi='killall picom'
alias killall='killall -v'

# Fonts
alias update-font='sudo fc-cache -fv'
alias list-fonts='fc-list'

# =============================================================================
# ALIAS LISTES ET INFORMATIONS
# =============================================================================

# Listes de paquets
alias list="pacman -Qqe"
alias listt="pacman -Qqet"
alias listaur="pacman -Qqem"
alias listexplicit="pacman -Qqe"
alias listforeign="pacman -Qqm"

# =============================================================================
# ALIAS DE DÉVELOPPEMENT (optionnels)
# =============================================================================

# Git (si installé)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Docker (si installé)
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

### Fin Mes Alias améliorés ###

