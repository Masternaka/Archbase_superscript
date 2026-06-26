# 📊 Analyse complète des scripts d'installation et de configuration

Ce document présente une analyse détaillée de tous les scripts présents à la racine du dépôt (à l'exclusion du dossier `Scripts_a_tester`). Il identifie les forces de l'implémentation actuelle, les bugs critiques pouvant affecter la stabilité du système, et propose des améliorations concrètes pour rendre l'ensemble plus robuste, cohérent et modulaire.

> [!NOTE]
> Dernière mise à jour : 2026-06-26 — Révision v2 (analyse étendue)

---

## 🔍 Synthèse générale de l'architecture

Le projet est conçu comme une suite d'outils modulaires de post-installation pour **Arch Linux** ou **EndeavourOS**.

```mermaid
graph TD
    A["00 - super_script.sh (Orchestrateur)"] --> B["01 - systemd_services.sh"]
    A --> C["02 - zram_settings.sh"]
    A --> D["03 - pacman_settings.sh"]
    A --> E["04 - chaotic_install.sh (User context)"]
    A --> F["05 - pacman_install.sh"]
    A --> G["06 - yay_install.sh"]
    A --> H["07 - flatpak_install.sh"]
    
    subgraph Non orchestrés (Manuels ou oubliés)
        I["08 - bash_tools.sh"]
        J["09 -install_alias.sh"]
        K["10 - kirorepo_install.sh (Vide)"]
    end
```

### 👍 Points forts identifiés
* **Gestion d'erreurs** : Utilisation systématique de `set -euo pipefail` pour arrêter l'exécution au premier problème (sauf cas spécifiques gérés).
* **Robustesse de l'orchestration** : Le script principal `00 - super_script.sh` intègre un rafraîchissement en arrière-plan du cache de mot de passe `sudo`, évitant les interruptions en cours de route.
* **Flexibilité** : Plusieurs scripts proposent un mode simulation (`--dry-run`) fort utile pour vérifier les actions avant de les exécuter.
* **Sécurité** : Les scripts d'installation séparent correctement les privilèges requis (utilisation de `sudo -u "$SUDO_USER"` pour les tâches non-root comme la compilation AUR ou la configuration Flatpak utilisateur).
* **Robustesse de `05` & `06`** : Mécanisme de retry automatique (3 tentatives) sur les installations pacman/AUR — très utile en cas de problème réseau transitoire.
* **Détection d'environnement** : `07 - flatpak_install.sh` vérifie correctement `SUDO_USER` dès le début du script, avant toute utilisation de la variable.

---

## 🚨 Dysfonctionnements et bugs critiques

### 1. Risque élevé de corruption mémoire (Script `02 - zram_settings.sh`)
Dans la fonction de test de performance (lignes 380–394) :
```bash
dd if=/dev/urandom of=/dev/zram0 bs=1M count=50
```
> [!CAUTION]
> **Risque de Kernel Panic / Instabilité Système**
> Le périphérique `/dev/zram0` est ici configuré et activé en tant que partition d'échange (**swap**). Écrire des données brutes dessus avec `dd` alors que le système l'utilise activement pour paginer la mémoire va corrompre les pages système échangées. Cela peut provoquer des plantages d'applications instantanés ou un plantage complet du noyau (Kernel Panic).
>
> * **Solution** : Supprimer ce test d'écriture brute sur le périphérique de swap actif. Si un benchmark est requis, il doit s'effectuer sur un système de fichiers temporaire monté en RAM, ou en désactivant le swap au préalable (`swapoff`), puis en le recréant (`mkswap` / `swapon`).

---

### 2. Partial upgrade dangereux (Script `04 - chaotic_install.sh`)
Dans la fonction `update_pacman_db()` (ligne 139) :
```bash
sudo pacman -Sy --noconfirm
```
> [!CAUTION]
> **Risque de système cassé (partial upgrade)**
> `pacman -Sy` sans `-u` met à jour uniquement la base de données des dépôts sans mettre à jour les paquets. Sur Arch Linux, cela peut mener à l'installation de paquets qui dépendent de bibliothèques plus récentes que celles installées, brisant la compatibilité ABI.
>
> * **Solution** : Remplacer par `pacman -Syyu --noconfirm` pour forcer une synchronisation et mise à jour complète. Alternativement, supprimer cet appel puisque `update_system()` (ligne 59) appelle déjà `pacman -Syu` juste avant dans le même script.

---

### 3. `cd /tmp` sans isolation de sous-shell (Script `04 - chaotic_install.sh`)
Dans la fonction `install_chaotic_packages()` (ligne 92) :
```bash
cd /tmp
wget ... -O chaotic-keyring.pkg.tar.zst
```
> [!WARNING]
> Sous `set -euo pipefail`, changer le répertoire de travail du processus principal avec `cd /tmp` est risqué. Si une commande suivante échoue et que le script continue (ex: via `|| true`), le reste du script s'exécute depuis `/tmp` au lieu du répertoire d'origine. De plus, les fichiers téléchargés ne sont pas nettoyés en cas d'erreur prématurée.
>
> * **Solution** : Utiliser un sous-shell pour isoler le changement de répertoire :
>   ```bash
>   (
>     cd /tmp
>     wget -q --show-progress "$KEYRING_URL" -O chaotic-keyring.pkg.tar.zst
>     wget -q --show-progress "$MIRRORLIST_URL" -O chaotic-mirrorlist.pkg.tar.zst
>     sudo pacman -U --noconfirm chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
>     rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
>   )
>   ```

---

### 4. Problématique de la variable `$HOME` sous `sudo` (Scripts `08 - bash_tools.sh` & `09 -install_alias.sh`)
Dans `08 - bash_tools.sh` (ligne 32) :
```bash
BASHRC="$HOME/.bashrc"
```
Et dans `09 -install_alias.sh` (lignes 6–7) :
```bash
ALIASES_FILE="$HOME/dotfiles/bash/.bash_aliases"
BASHRC="$HOME/.bashrc"
```
Si le script est exécuté en tant que root (ce qui est induit par l'appel à `sudo` dans l'orchestrateur ou par l'utilisateur), la variable `$HOME` va pointer vers `/root` au lieu du répertoire de l'utilisateur standard (ex: `/home/nom_utilisateur`).
* **Conséquence** : Le fichier `/root/.bashrc` sera configuré avec les alias et prompts modernes (eza, bat, starship, zoxide), tandis que l'utilisateur standard n'aura aucun changement dans son terminal.
* **Solution** : Récupérer dynamiquement le répertoire personnel de l'utilisateur d'origine via `SUDO_USER` :
  ```bash
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
  BASHRC="$USER_HOME/.bashrc"
  ```

---

### 5. `sudo pacman` redondant dans un script déjà root (Script `08 - bash_tools.sh`)
Lignes 13 et 29 :
```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm "${PACMAN_TOOLS[@]}"
```
> [!WARNING]
> Le script `08` est appelé par l'orchestrateur via `sudo bash`, donc il tourne déjà en tant que root (`EUID=0`). Appeler `sudo` à nouveau depuis un processus root est redondant et peut échouer dans des environnements où `sudo` nécessite un TTY, ou provoquer des avertissements inattendus.
>
> * **Solution** : Retirer les `sudo` devant `pacman` dans ce script. Ajouter une vérification root en début de script et appeler les commandes directement.

---

### 6. Guillemets échappés fragiles dans `MODERN_CONF` (Script `08 - bash_tools.sh`)
Lignes 57 et 60 :
```bash
eval \"$(starship init bash)\"
eval \"$(zoxide init bash --cmd cd)\"
```
Ces échappements à l'intérieur d'une variable multi-ligne sont très fragiles. Le contenu réellement écrit dans `.bashrc` doit être vérifié manuellement à chaque modification du script, et une faute de frappe peut corrompre silencieusement le `.bashrc` de l'utilisateur.
* **Solution** : Réécrire l'écriture dans `.bashrc` avec un heredoc dédié (plus lisible, aucun risque d'échappement) :
  ```bash
  cat >> "$BASHRC" << 'BASHRC_CONF'
  eval "$(starship init bash)"
  eval "$(zoxide init bash --cmd cd)"
  BASHRC_CONF
  ```

---

### 7. Timestamp incohérent dans le log de sauvegarde (Script `04 - chaotic_install.sh`)
Dans `add_chaotic_repo()` (lignes 123–124) :
```bash
sudo cp "$PACMAN_CONF" "$PACMAN_CONF.backup.$(date +%Y%m%d_%H%M%S)"
print_info "Sauvegarde créée: $PACMAN_CONF.backup.$(date +%Y%m%d_%H%M%S)"
```
`$(date)` est appelé **deux fois** : le fichier créé et le nom affiché dans le log auront des timestamps différents (d'une seconde d'écart), rendant le message de log trompeur.
* **Solution** : Stocker le timestamp dans une variable :
  ```bash
  local ts; ts=$(date +%Y%m%d_%H%M%S)
  sudo cp "$PACMAN_CONF" "$PACMAN_CONF.backup.$ts"
  print_info "Sauvegarde créée: $PACMAN_CONF.backup.$ts"
  ```

---

### 8. `makepkg -si` interactif bloque en mode non-interactif (Script `06 - yay_install.sh`)
Dans `install_yay()` (ligne 76) :
```bash
sudo -u "$SUDO_USER" bash -c "... makepkg -si --noconfirm"
```
L'option `-i` de `makepkg` installe le paquet via `pacman` de manière interactive. Même avec `--noconfirm` passé à `makepkg`, l'appel interne à `pacman` peut requérir une confirmation dans certains cas. En mode orchestré (stdin non-TTY), cela peut bloquer indéfiniment.
* **Solution** : Séparer le build de l'installation :
  ```bash
  sudo -u "$SUDO_USER" bash -c "
    cd '$build_dir' && rm -rf yay && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -s --noconfirm"
  pacman -U --noconfirm "$build_dir"/yay/yay-*.pkg.tar.zst
  ```

---

### 9. Scripts oubliés de l'orchestrateur `00 - super_script.sh`
Les scripts suivants ne sont déclarés ni dans `SCRIPTS_SUDO` ni dans `SCRIPTS_USER` :
* `08 - bash_tools.sh`
* `09 -install_alias.sh`
* `10 - kirorepo_install.sh`
* **Conséquence** : L'exécution complète via le script maître n'installera pas vos alias ni vos outils de terminal modernes.

---

### 10. Faute de frappe bloquant l'installation (Script `05 - pacman_install.sh`)
À la ligne 223 :
```bash
Helix
```
> [!WARNING]
> Les paquets sous Arch Linux sont strictement en minuscules et sensibles à la casse. `Helix` provoquera une erreur d'installation pacman, ce qui arrêtera le script en raison de `set -e`.
>
> * **Solution** : Remplacer par `helix` en minuscules.

---

### 11. Script vide ou incomplet (Script `10 - kirorepo_install.sh`)
Ce script a la structure d'installation de paquets, mais le tableau `packages` est totalement vide (lignes 154–156) :
```bash
  packages+=(
      
  )
```
* **Conséquence** : Il effectue une mise à jour système complète inutilement (`pacman -Syu`) puis s'arrête sans rien installer.
* **Solution** : À supprimer s'il est inutile, ou à compléter avec les paquets du dépôt concerné.

---

## ⚠️ Problèmes de qualité et de cohérence

### 12. Duplication de code massive entre `05` et `10`
Les scripts `05 - pacman_install.sh` et `10 - kirorepo_install.sh` sont **quasiment identiques** — mêmes fonctions copiées-collées :
- `backup_installed_packages()`
- `create_recovery_script()`
- `install_package_with_retry()`
- `cleanup_on_exit()`
- `confirm_installation()`
- `show_help()`
- `update_system()`
- `is_endeavouros()`

* **Conséquence** : Un bug corrigé dans `05` doit aussi l'être dans `10` manuellement. Risque élevé de divergence silencieuse.
* **Solution** : Créer un fichier `lib/common.sh` contenant ces fonctions partagées, sourcé par les deux scripts :
  ```bash
  # En tête de 05 et 10
  source "$(dirname "$0")/lib/common.sh"
  ```

---

### 13. `check_deps` bloquant pour l'ensemble du script (Script `01 - systemd_services.sh`)
Actuellement, si un seul paquet requis pour un service est absent du système (par exemple `bluetoothctl` pour `bluetooth.service`), la fonction `check_deps` fait échouer l'ensemble du script.
* **Amélioration** : Rendre la vérification non-bloquante service par service. Si une dépendance manque, ignorer l'activation de ce service spécifique et continuer à activer les autres services fonctionnels (ex: le pare-feu ou le trim SSD).

---

### 14. `starship` installé en double (Scripts `05` et `08`)
`starship` est présent dans la liste de paquets de `05 - pacman_install.sh` (ligne 177) **et** dans `08 - bash_tools.sh` (ligne 24). Ce n'est pas bloquant grâce à `--needed`, mais cela signale un manque de coordination entre les scripts et génère un appel pacman redondant.
* **Solution** : Retirer `starship` de `08 - bash_tools.sh` puisqu'il est déjà géré par `05`.

---

### 15. Nom de fichier incohérent (`09 -install_alias.sh`)
Le fichier se nomme `09 -install_alias.sh` (espace manquant avant le tiret) alors que tous les autres scripts suivent la convention `NN - nom.sh`. Ce n'est pas bloquant mais peut causer des surprises avec des scripts glob, du tri alphabétique, ou de l'autocomplétion.
* **Solution** : Renommer en `09 - install_alias.sh`.

---

## 💡 Suggestions d'amélioration et d'optimisation

### A. Rendre l'orchestrateur dynamique
Plutôt que d'avoir des listes de scripts codées en dur dans `00 - super_script.sh`, il serait plus efficace de scanner automatiquement le dossier pour les scripts de `01` à `09` (ou de les filtrer par convention de nommage). Cela éviterait d'oublier des scripts lors d'ajouts futurs.

### B. Optimisation des installations avec Chaotic-AUR
Le script `04 - chaotic_install.sh` installe le dépôt **Chaotic-AUR** (qui fournit des paquets AUR précompilés).
Cependant, dans `06 - yay_install.sh`, certains logiciels lourds sont installés via le dépôt AUR standard (ex: `brave-bin`, `spotify`).
* **Amélioration** : Puisque Chaotic-AUR est activé, ces paquets populaires peuvent être installés directement via `pacman` depuis Chaotic-AUR dans le script `05 - pacman_install.sh`, économisant beaucoup de temps de téléchargement et d'installation par rapport à un build AUR classique.

### C. Robustesse du script d'alias (`09 -install_alias.sh`)
Le script présuppose l'existence d'un dossier `$HOME/dotfiles/bash/.bash_aliases`. Si ce dossier ou fichier n'existe pas, le script s'arrête en erreur.
* **Amélioration** : Permettre au script de créer un fichier d'alias vide par défaut s'il n'existe pas, ou proposer de saisir un autre chemin.

### D. Ajouter `Color` et `ILoveCandy` dans `03 - pacman_settings.sh`
Le script ne configure que `ParallelDownloads`. Deux options très recommandées pour améliorer l'expérience pacman sont absentes :
- `Color` : Active l'affichage coloré de pacman
- `ILoveCandy` : Remplace la barre de progression par une animation stylée (easter egg officiel d'Arch)
* **Amélioration** : Les ajouter dans la section `[options]` de `pacman.conf` lors de la configuration.

### E. Extraire une bibliothèque commune `lib/common.sh`
Regrouper toutes les fonctions partagées (retry, backup, confirmation, détection EndeavourOS, gestion des couleurs) dans un fichier dédié sourcé par tous les scripts concernés. Cela réduirait la base de code d'environ 40% et faciliterait la maintenance à long terme.

---

## 🛠️ Plan d'action recommandé

| Priorité | Étape | Fichier | Description de la correction |
| :---: | :---: | :--- | :--- |
| 🔴 Critique | **1** | `02 - zram_settings.sh` | Retirer ou réécrire le test `dd` de performance sur `/dev/zram0` |
| 🔴 Critique | **2** | `04 - chaotic_install.sh` | Remplacer `pacman -Sy` par `pacman -Syyu` dans `update_pacman_db()` |
| 🔴 Critique | **3** | `04 - chaotic_install.sh` | Isoler `cd /tmp` dans un sous-shell |
| 🟠 Majeur | **4** | `08 - bash_tools.sh` | Corriger la résolution de `$HOME` via `SUDO_USER` |
| 🟠 Majeur | **5** | `08 - bash_tools.sh` | Supprimer les `sudo` redondants (script déjà root) |
| 🟠 Majeur | **6** | `08 - bash_tools.sh` | Réécrire `MODERN_CONF` avec un heredoc pour éviter les guillemets fragiles |
| 🟠 Majeur | **7** | `05 - pacman_install.sh` | Remplacer `Helix` par `helix` |
| 🟠 Majeur | **8** | `04 - chaotic_install.sh` | Stocker le timestamp de sauvegarde dans une variable |
| 🟠 Majeur | **9** | `06 - yay_install.sh` | Rendre l'installation de yay non-interactive (`makepkg -s` + `pacman -U`) |
| 🟠 Majeur | **10** | `05` & `10` | Extraire les fonctions communes dans `lib/common.sh` |
| 🟡 Modéré | **11** | `00 - super_script.sh` | Inclure les scripts `08` et `09` dans l'orchestration |
| 🟡 Modéré | **12** | `10 - kirorepo_install.sh` | Nettoyer / supprimer ce fichier s'il est obsolète |
| 🟡 Modéré | **13** | `01 - systemd_services.sh` | Rendre `check_deps` non-bloquant par service |
| 🟡 Modéré | **14** | `03 - pacman_settings.sh` | Ajouter `Color` et `ILoveCandy` à la configuration |
| 🟢 Faible | **15** | `09 -install_alias.sh` | Renommer le fichier en `09 - install_alias.sh` |
| 🟢 Faible | **16** | `05` & `08` | Retirer `starship` en double (garder uniquement dans `05`) |

---

> [!NOTE]
> L'ensemble des scripts présente une très bonne qualité d'écriture (commentaires précis, journalisation soignée dans `/var/log`, structures de contrôle modernes). Les corrections ci-dessus permettront de finaliser ce travail et de le rendre parfaitement exploitable pour une installation automatisée et sûre.
