#!/bin/bash

# Vérifie si zenity est installé
if ! command -v zenity &> /dev/null; then
    echo "Zenity n'est pas installé. Installation..."
    sudo apt install -y zenity
fi

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    zenity --error --title="Erreur de permission" --text="Ce script doit être lancé avec les droits administrateur (root)."
    exit 1
fi

# Confirmation de l'utilisateur
zenity --question --title="Mise à jour du système" --text="Souhaitez-vous lancer la mise à jour ?" --width=300
if [ $? -ne 0 ]; then
    exit 0
fi

# Création d'un fichier temporaire pour afficher la progression
LOG_FILE=$(mktemp)

(
    echo "0" ; echo "# Début des mises à jours en cours"
    sleep 0.5
    echo "10" ; echo "# Mise à jour des paquets APT..."
    apt update -y >> "$LOG_FILE" 2>&1
    apt upgrade -y >> "$LOG_FILE" 2>&1
    apt autoremove -y >> "$LOG_FILE" 2>&1
    apt autoclean >> "$LOG_FILE" 2>&1

    echo "30" ; echo "# Mise à jour de Snap..."
    if command -v snap &> /dev/null; then
        snap refresh >> "$LOG_FILE" 2>&1
    fi

    echo "50" ; echo "# Mise à jour de Flatpak..."
    if command -v flatpak &> /dev/null; then
        flatpak update -y >> "$LOG_FILE" 2>&1
    fi

    echo "70" ; echo "# Mise à jour des paquets Python..."
    if command -v pip3 &> /dev/null; then
        pip3 install --upgrade pip >> "$LOG_FILE" 2>&1
        pip3 list --outdated --format=freeze | cut -d= -f1 | xargs -n1 pip3 install -U >> "$LOG_FILE" 2>&1
    fi
) | zenity --progress \
  --title="Mise à jour du système en cours..." \
  --width=400 \
  --height=100 \
  --percentage=0 \
  --auto-close \
  --auto-kill

# Code de retour de zenity --progress
if [ $? -eq 0 ]; then
    zenity --info --title="Succès" --text="Mise à jour terminée !"
else
    zenity --error --title="Erreur" --text="Une erreur est survenue. Consultez le fichier : $LOG_FILE"
fi

