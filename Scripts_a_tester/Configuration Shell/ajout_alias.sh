#!/bin/bash

###############################################################################
# Script amélioré pour l'ajout de alias dans le fichier de configuration du shell
#
# Options :
#   -n, --dry-run     Affiche les commandes sans les exécuter
#   -i, --interactive Mode interactif pour choisir les alias
#   -a, --all-shells  Applique à tous les shells détectés
#   -r, --restore     Restaure depuis la dernière sauvegarde
#   -v, --validate    Valide la syntaxe des alias avant installation
#   -h, --help        Affiche cette aide
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: ajout_alias.sh
# 2. Rendez-le exécutable: chmod +x ajout_alias.sh
# 3. Exécutez-le: ./ajout_alias.sh
###############################################################################

ALIAS_FILE="$HOME/mes_alias_bashzsh.sh"
START_MARKER="# >>> ALIAS START <<<"
END_MARKER="# <<< ALIAS END <<<"
DRY_RUN=false
INTERACTIVE=false
ALL_SHELLS=false
RESTORE=false
VALIDATE=false
BACKUP_DIR="$HOME/.alias_backups"

# Fonction d'affichage d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --dry-run     Affiche les commandes sans les exécuter"
    echo "  -i, --interactive Mode interactif pour choisir les alias"
    echo "  -a, --all-shells  Applique à tous les shells détectés"
    echo "  -r, --restore     Restaure depuis la dernière sauvegarde"
    echo "  -v, --validate    Valide la syntaxe des alias avant installation"
    echo "  -h, --help        Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 --interactive  # Mode interactif"
    echo "  $0 --all-shells  # Applique à bash et zsh"
    echo "  $0 --restore     # Restaure la dernière sauvegarde"
}

# Fonction de logging (supprimée - remplacée par message simple)

# Fonction de gestion d'erreur
error_exit() {
    local message="$1"
    echo "❌ Erreur: $message" >&2
    exit 1
}

# Fonction de validation des alias
validate_aliases() {
    local file="$1"
    local errors=0
    
    echo "🔍 Validation de la syntaxe des alias..."
    
    while IFS= read -r line; do
        # Ignorer les commentaires et lignes vides
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Vérifier la syntaxe des alias
        if [[ "$line" =~ ^alias[[:space:]]+[^=]+= ]]; then
            echo "✅ $line"
        else
            echo "❌ Syntaxe invalide: $line"
            ((errors++))
        fi
    done < "$file"
    
    if [[ $errors -eq 0 ]]; then
        echo "✅ Tous les alias sont syntaxiquement corrects"
        return 0
    else
        echo "❌ $errors erreur(s) de syntaxe détectée(s)"
        return 1
    fi
}

# Fonction de détection des shells
detect_shells() {
    local shells=()
    
    if [[ -f "$HOME/.bashrc" ]]; then
        shells+=("bash")
    fi
    if [[ -f "$HOME/.zshrc" ]]; then
        shells+=("zsh")
    fi
    if [[ -f "$HOME/.config/fish/config.fish" ]]; then
        shells+=("fish")
    fi
    
    echo "${shells[@]}"
}

# Fonction de restauration
restore_backup() {
    local shell_type="$1"
    local rc_file
    
    case "$shell_type" in
        "bash") rc_file="$HOME/.bashrc" ;;
        "zsh") rc_file="$HOME/.zshrc" ;;
        "fish") rc_file="$HOME/.config/fish/config.fish" ;;
    esac
    
    if [[ -f "$rc_file.bak" ]]; then
        if cp "$rc_file.bak" "$rc_file"; then
            echo "✅ Restauration réussie pour $shell_type"
        else
            error_exit "Impossible de restaurer $rc_file"
        fi
    else
        echo "⚠️  Aucune sauvegarde trouvée pour $shell_type"
    fi
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -a|--all-shells)
            ALL_SHELLS=true
            shift
            ;;
        -r|--restore)
            RESTORE=true
            shift
            ;;
        -v|--validate)
            VALIDATE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Gestion du mode restauration
if $RESTORE; then
    echo "🔄 Mode restauration activé"
    detected_shells=($(detect_shells))
    for shell in "${detected_shells[@]}"; do
        restore_backup "$shell"
    done
    exit 0
fi

# Validation des alias si demandée
if $VALIDATE; then
    if [[ ! -f "$ALIAS_FILE" ]]; then
        error_exit "Le fichier d'alias '$ALIAS_FILE' n'existe pas pour la validation."
    fi
    validate_aliases "$ALIAS_FILE" || error_exit "Validation des alias échouée"
fi

# Vérification de l'existence du fichier d'alias
if [[ ! -f "$ALIAS_FILE" ]]; then
    error_exit "Le fichier d'alias '$ALIAS_FILE' n'existe pas. Veuillez le créer d'abord."
fi

# Création du dossier de sauvegarde
mkdir -p "$BACKUP_DIR"

# Détection des shells
detected_shells=($(detect_shells))
if [[ ${#detected_shells[@]} -eq 0 ]]; then
    error_exit "Aucun shell détecté (.bashrc, .zshrc, ou config.fish)"
fi

echo "🔍 Shells détectés: ${detected_shells[*]}"

# Fonction pour traiter un shell spécifique
process_shell() {
    local shell_type="$1"
    local rc_file
    local alias_block
    
    case "$shell_type" in
        "bash") 
            rc_file="$HOME/.bashrc"
            alias_block="$START_MARKER
# Chargé automatiquement depuis $ALIAS_FILE
if [ -f \"$ALIAS_FILE\" ]; then
    source \"$ALIAS_FILE\"
fi
$END_MARKER"
            ;;
        "zsh") 
            rc_file="$HOME/.zshrc"
            alias_block="$START_MARKER
# Chargé automatiquement depuis $ALIAS_FILE
if [ -f \"$ALIAS_FILE\" ]; then
    source \"$ALIAS_FILE\"
fi
$END_MARKER"
            ;;
        "fish") 
            rc_file="$HOME/.config/fish/config.fish"
            alias_block="$START_MARKER
# Chargé automatiquement depuis $ALIAS_FILE
if test -f \"$ALIAS_FILE\"
    source \"$ALIAS_FILE\"
end
$END_MARKER"
            ;;
    esac
    
    if $DRY_RUN; then
        echo "--- DRY RUN pour $shell_type ---"
        echo "Fichier ciblé : $rc_file"
        echo "Fichier d'alias : $ALIAS_FILE"
        echo "Bloc qui serait inséré :"
        echo "$alias_block"
        echo "(aucune modification écrite)"
        return 0
    fi
    
    # Sauvegarde avec timestamp
    local backup_file="$BACKUP_DIR/${shell_type}_$(date +%Y%m%d_%H%M%S).bak"
    if ! cp "$rc_file" "$backup_file"; then
        error_exit "Impossible de créer la sauvegarde de $rc_file"
    fi
    echo "💾 Sauvegarde créée: $backup_file"
    
    # Supprime section existante
    if ! sed -i "/$START_MARKER/,/$END_MARKER/d" "$rc_file"; then
        error_exit "Impossible de supprimer la section existante dans $rc_file"
    fi
    
    # Insertion en tête
    if ! { echo "$alias_block"; echo; cat "$rc_file"; } > "$rc_file.tmp" || ! mv "$rc_file.tmp" "$rc_file"; then
        error_exit "Impossible d'insérer le bloc d'alias dans $rc_file"
    fi
    
    echo "✅ Aliases ajoutés à $rc_file ($shell_type)"
}

# Mode interactif
if $INTERACTIVE; then
    echo "🎯 Mode interactif activé"
    echo "Shells détectés: ${detected_shells[*]}"
    echo ""
    for shell in "${detected_shells[@]}"; do
        read -p "Installer les alias pour $shell ? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            process_shell "$shell"
        fi
    done
elif $ALL_SHELLS; then
    echo "🌐 Installation sur tous les shells détectés"
    for shell in "${detected_shells[@]}"; do
        process_shell "$shell"
    done
else
    # Mode par défaut - premier shell détecté
    process_shell "${detected_shells[0]}"
fi

# Messages de succès finaux
echo ""
echo "🎉 Installation terminée !"
echo "📁 Fichier d'alias source : $ALIAS_FILE"
echo "🔁 Pour appliquer les changements, rechargez votre shell avec:"
for shell in "${detected_shells[@]}"; do
    case "$shell" in
        "bash") echo "   source ~/.bashrc" ;;
        "zsh") echo "   source ~/.zshrc" ;;
        "fish") echo "   source ~/.config/fish/config.fish" ;;
    esac
done
echo "   ou redémarrez votre terminal"
echo ""
echo "📝 Installation terminée avec succès !"
echo "💾 Sauvegardes disponibles dans $BACKUP_DIR"
