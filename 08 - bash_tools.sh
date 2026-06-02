#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---- Mise à jour de pacman ----
echo -e "${CYAN}>>> Mise à jour de pacman...${NC}"
sudo pacman -Syu --noconfirm

# ---- Liste des outils (dépôts officiels uniquement) ----
PACMAN_TOOLS=(
    bat            # cat avec coloration syntaxique
    eza            # ls moderne (fork de exa)
    ripgrep        # grep ultra-rapide (rg)
    fd             # find simplifié
    fzf            # fuzzy finder
    zoxide         # cd intelligent
    duf            # df moderne
    starship       # prompt cross-shell
)

# ---- Installation des paquets ----
echo -e "${CYAN}>>> Installation des outils depuis les dépôts officiels...${NC}"
sudo pacman -S --needed --noconfirm "${PACMAN_TOOLS[@]}"

# ---- Sauvegarde du .bashrc ----
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ]; then
    cp "$BASHRC" "$BASHRC.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}Sauvegarde de .bashrc effectuée.${NC}"
fi

# ---- Configuration à ajouter ----
MODERN_CONF="
# ============================================================
#  Configuration moderne du shell (ajoutée par le script)
# ============================================================

# ---- Alias modernes ----
alias ls='eza --icons --color=auto --group-directories-first'
alias ll='eza -la --icons --color=auto --group-directories-first'
alias la='eza -a --icons --color=auto'
alias tree='eza --tree --icons'
alias cat='bat --paging=never --style=plain'
alias grep='rg --color=auto'
alias find='fd'
alias df='duf'
alias cd='z'   # Remplace cd par zoxide (mettez 'z' en alias si vous voulez garder cd intact)

# ---- Initialisation des outils ----
# Starship prompt
eval \"\$(starship init bash)\"

# Zoxide (remplacez '--cmd cd' par '--cmd z' si vous préférez utiliser 'z' sans écraser cd)
eval \"\$(zoxide init bash --cmd cd)\"

# FZF : configuration par défaut (source: /usr/share/fzf/key-bindings.bash)
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash

# ---- Options utiles ----
# Meilleur historique
shopt -s histappend
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups

# Autocomplétion améliorée
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
"

# ---- Ajout de la configuration (sans duplication) ----
if ! grep -q "Configuration moderne du shell" "$BASHRC" 2>/dev/null; then
    echo -e "\n$MODERN_CONF" >> "$BASHRC"
    echo -e "${GREEN}Configuration ajoutée à ${BASHRC}.${NC}"
else
    echo -e "${YELLOW}La configuration moderne est déjà présente dans ${BASHRC}.${NC}"
fi

# ---- Résumé final ----
echo -e "\n${GREEN}=== Installation terminée ===${NC}"
echo -e "Pour appliquer les changements, ouvrez un nouveau terminal ou lancez :"
echo -e "  ${CYAN}source ~/.bashrc${NC}"
echo -e "\nQuelques commandes à essayer :"
echo -e "  ${YELLOW}ls${NC}   -> eza avec icônes"
echo -e "  ${YELLOW}cat${NC}  -> bat (coloration)"
echo -e "  ${YELLOW}z${NC}    -> zoxide (apprentissage automatique de vos dossiers)"
echo -e "  ${YELLOW}Ctrl+R${NC} -> historique interactif via fzf"
echo -e "  ${YELLOW}Ctrl+T${NC} -> recherche de fichiers via fzf"
echo -e "  ${YELLOW}df${NC}   -> duf (affichage moderne de l'espace disque)"
