✅ 1. Rendre tous tes scripts exécutables d’un coup

Si tous tes fichiers sont dans le même dossier :

```chmod +x *.sh```

Ça va rendre 00.sh, 01.sh, 02.sh, etc. exécutables en une seule commande.

---

✅ 2. Variante plus ciblée (si tu veux être précis)

Si tu veux seulement certains fichiers :

```chmod +x 00.sh 01.sh 02.sh 03.sh 04.sh```

---

✅ 3. Si tes scripts sont dans des sous-dossiers

Utilise find :

```find . -type f -name "*.sh" -exec chmod +x {} \;```

---

✅ 4. Vérifier que c’est bien appliqué

```ls -l```

Tu devrais voir un x dans les permissions :

```-rwxr-xr-x  00.sh```

---

⚠️ Important pour ton script principal (00.sh)

Dans 00.sh, appelle les autres scripts correctement :

Option A — exécution directe
```
./01.sh
./02.sh
```

Option B — via bash (pas besoin d’exécutable dans ce cas)

```
01.sh
02.sh
```

---

👉 Si tu utilises bash script.sh, le chmod +x n’est pas obligatoire.

💡 Bonnes pratiques

Ajoute toujours un shebang en haut de chaque script :

```#!/usr/bin/env bash``



##############################################
Comment gérer vos alias et fonctions personnalisés dans le .bashrc

Structurer vos alias dans un fichier séparé
Pour garder un .bashrc propre et facile à maintenir, créez un fichier ~/.bash_aliases :

# Création du fichier
touch ~/.bash_aliases
Ajoutez-y vos alias personnels, par exemple :

# ~/.bash_aliases
alias maj='sudo pacman -Syu'
alias upall='yay -Syu --noconfirm'
alias ports='sudo netstat -tulanp'
alias ip='ip -color'
alias clean='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || echo "Rien à nettoyer"'
alias update-mirrors='sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'
Puis, dans votre ~/.bashrc, ajoutez (ou décommentez) les lignes suivantes :

# Chargement des alias personnels
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi
Rechargez ensuite votre shell : source ~/.bashrc.
