#!/usr/bin/env bash

set -euo pipefail

# Chemin fixe du fichier d'alias
ALIASES_FILE="$HOME/dotfiles/bash/.bash_aliases"
BASHRC="$HOME/.bashrc"

# Ligne de chargement (avec le chemin exact)
SOURCE_LINE="[ -f \"$ALIASES_FILE\" ] && source \"$ALIASES_FILE\""
MARKER="# >>> bash_aliases activé par enable-bash-aliases.sh"

echo "=== Activation du fichier d'alias : $ALIASES_FILE ==="

# ---- Vérifications d'existence ----
if [ ! -f "$ALIASES_FILE" ]; then
    echo "ERREUR : le fichier '$ALIASES_FILE' n'existe pas." >&2
    echo "Veuillez le créer avant d'exécuter ce script." >&2
    exit 1
fi

if [ ! -f "$BASHRC" ]; then
    echo "ERREUR : $BASHRC n'existe pas. Impossible de le modifier." >&2
    exit 1
fi

# ---- Ajout du chargement dans .bashrc si absent ----
if grep -qF "$SOURCE_LINE" "$BASHRC"; then
    echo "Le chargement est déjà présent dans $BASHRC."
else
    # Sauvegarde
    cp "$BASHRC" "$BASHRC.backup.$(date +%Y%m%d_%H%M%S)"
    echo "$MARKER" >> "$BASHRC"
    echo "if [ -f \"$ALIASES_FILE\" ]; then source \"$ALIASES_FILE\"; fi" >> "$BASHRC"
    echo "✓ Ajout effectué dans $BASHRC (sauvegarde créée)."
fi

echo ""
echo "=== Terminé ==="
echo "Le fichier $ALIASES_FILE sera chargé automatiquement."
echo "Pour appliquer : source ~/.bashrc"
