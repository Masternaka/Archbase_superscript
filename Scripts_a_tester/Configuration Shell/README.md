# Configuration des alias Bash/Zsh (À vérifier s'il fonctionne)

Ce dossier contient deux fichiers:
- `ajout_alias.sh`: script d’installation et de gestion d’un bloc d’alias pour vos shells.
- `mes_alias_bashzsh.sh`: fichier d’alias prêt à l’emploi, sourcé par vos fichiers de configuration (`.bashrc`, `.zshrc`).

## Objectifs
- Installer proprement un bloc d’alias dans votre shell.
- Centraliser les alias dans un fichier unique, facile à versionner.
- Permettre la restauration et la validation de la configuration.

## Prérequis
- Environnement utilisateur Unix-like (Arch/EndeavourOS, etc.).
- Droits d’écriture sur `~/.bashrc` ou `~/.zshrc`.
- Outils standard: `bash`, `sed`, `awk`.

## Installation
1. Rendre exécutable le script d’installation:
```bash
chmod +x ajout_alias.sh
```
2. Vérifier/éditer vos alias dans `~/mes_alias_bashzsh.sh` (le chemin par défaut utilisé par le script).

## Utilisation rapide
- Mode par défaut (ajoute les alias au premier shell détecté):
```bash
./ajout_alias.sh
```
- Mode interactif (choix des shells à configurer):
```bash
./ajout_alias.sh --interactive
```
- Appliquer à tous les shells détectés (bash, zsh):
```bash
./ajout_alias.sh --all-shells
```
- Restauration depuis la dernière sauvegarde:
```bash
./ajout_alias.sh --restore
```
- Validation de la syntaxe des alias avant installation:
```bash
./ajout_alias.sh --validate
```
- Simulation sans appliquer de changements (dry-run):
```bash
./ajout_alias.sh --dry-run
```

## Options de `ajout_alias.sh`
- `-n, --dry-run` : affiche ce qui serait fait sans modifier les fichiers.
- `-i, --interactive` : permet de choisir pour quels shells installer.
- `-a, --all-shells` : installe pour tous les shells détectés.
- `-r, --restore` : restaure les fichiers `rc` depuis la sauvegarde la plus récente.
- `-v, --validate` : vérifie la syntaxe du fichier d’alias avant installation.
- `-h, --help` : affiche l’aide.

## Détails de fonctionnement
- Le script détecte la présence de `~/.bashrc` et `~/.zshrc`.
- Il crée un dossier de sauvegardes `~/.alias_backups` puis sauvegarde le fichier `rc` ciblé avant modification.
- Il supprime tout ancien bloc d’alias délimité par:
  - `# >>> ALIAS START <<<` et `# <<< ALIAS END <<<`
- Il insère en tête du fichier `rc` un bloc qui `source` `~/mes_alias_bashzsh.sh` s’il existe.
- En mode `--validate`, il scanne chaque ligne non vide/non commentée du fichier d’alias et vérifie la forme `alias nom=...`.

## Fichier d’alias: `mes_alias_bashzsh.sh`
Le fichier fournit un ensemble d’alias organisés par thèmes:
- **Système et navigation**: `ls`, `la`, `ll`, `lt`, `rg`, `find`, etc.
- **Pacman/Yay/Flatpak**: installation, recherche, mise à jour, nettoyage.
- **Monitoring**: `htop`, `free`, `df`, `du`, infos CPU/Mémoire.
- **Réseau**: `ping`, `netstat`, `myip`, `speedtest`.
- **Édition de configuration**: alias `n...` ouvrant des fichiers système avec `$EDITOR`.
- **Systemd**: `sysstart`, `sysenable`, `jctl`, etc.
- **Utilitaires**: historique des paquets, logs, permissions, sessions.
- **Développement**: alias Git/Docker.

Ces alias supposent la présence de certains outils (`yay`, `flatpak`, `htop`, `neofetch`, `expac`, `bat`, etc.). Si un outil est absent, supprimez ou ajustez l’alias correspondant.

## Personnalisation
- Éditez `~/mes_alias_bashzsh.sh` pour ajouter/retirer des alias.
- Modifiez le chemin utilisé par `ajout_alias.sh` en ajustant la variable `ALIAS_FILE` si nécessaire.
- Ajoutez vos alias spécifiques par thème pour rester organisé.

## Restauration
Relancez le script avec `--restore` pour chaque shell détecté. Les sauvegardes sont stockées dans `~/.alias_backups/` avec horodatage.

## Recharger le shell
Après installation ou modification:
```bash
# bash
source ~/.bashrc
# zsh
source ~/.zshrc
```

## Dépannage
- "Le fichier d'alias n'existe pas" ➜ créez `~/mes_alias_bashzsh.sh` ou ajustez `ALIAS_FILE`.
- "Aucun shell détecté" ➜ vérifiez la présence de vos fichiers `rc`.
- "Validation des alias échouée" ➜ corrigez les lignes signalées, relancez avec `--validate`.
- Un alias utilise un outil manquant ➜ installez l’outil ou retirez l’alias.

## Avertissements
- Le script modifie vos fichiers `rc`. Vérifiez les sauvegardes dans `~/.alias_backups` avant toute restauration.
- Si vous utilisez un gestionnaire de dotfiles, alignez cette procédure avec votre workflow.
