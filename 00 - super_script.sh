#!/bin/bash
set -euo pipefail

# -------------------- CONFIGURATION --------------------
SCRIPT_DIR="${HOME}/EndeavourOS"           # Dossier principal
LOGFILE="/var/log/arch-custom-$(date +%Y%m%d-%H%M%S).log"

# Chemins relatifs à SCRIPT_DIR (sous‑dossiers inclus)
SCRIPTS_SUDO=(
    "packages/01-officials.sh"
    "packages/02-aur.sh"
    "services/enable.sh"
)

SCRIPTS_USER=(
    "dotfiles/stow.sh"
    "themes/gtk.sh"
)
# ------------------------------------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

exec > >(tee -a "$LOGFILE") 2>&1

echo -e "${YELLOW}### Début de la personnalisation - $(date) ###${NC}"
echo "Log : $LOGFILE"
echo ""

sudo -v   # Validation du cache sudo

run_script() {
    local script_path="$1"
    local use_sudo="$2"

    echo -e "${GREEN}--- $(basename "$script_path") ---${NC}"
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}ERREUR : Fichier introuvable : $script_path${NC}" >&2
        exit 1
    fi
    if [[ "$use_sudo" == "yes" ]]; then
        sudo bash "$script_path"
    else
        bash "$script_path"
    fi
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}ERREUR : $script_path a échoué (code $exit_code).${NC}" >&2
        exit $exit_code
    fi
    echo -e "${GREEN}--- Ok ---${NC}"
    echo ""
}

# Phase utilisateur
echo -e "${YELLOW}== Scripts utilisateur ==${NC}"
for script in "${SCRIPTS_USER[@]}"; do
    run_script "${SCRIPT_DIR}/${script}" "no"
done

# Phase administrateur
echo -e "${YELLOW}== Scripts administrateur (sudo) ==${NC}"
for script in "${SCRIPTS_SUDO[@]}"; do
    run_script "${SCRIPT_DIR}/${script}" "yes"
done

echo -e "${YELLOW}### Terminé - $(date) ###${NC}"
