#!/bin/bash

LOG_FILE="/tmp/update_log_$(date +%F_%T).log"

echo "=== Script de mise à jour système ==="
echo "Log enregistré dans : $LOG_FILE"
echo ""

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "Erreur : Ce script doit être lancé en tant que root." >&2
    exit 1
fi

# Vérification de la connexion Internet
echo "Vérification de la connexion réseau..."
ping -c 1 1.1.1.1 &>/dev/null
if [ $? -ne 0 ]; then
    echo "Erreur : Pas de connexion Internet. Veuillez vous connecter avant de lancer la mise à jour." >&2
    exit 1
fi

# Mise à jour APT
echo ">> Mise à jour des paquets APT..."
apt update -y >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'apt update'" >> "$LOG_FILE"
apt upgrade -y >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'apt upgrade'" >> "$LOG_FILE"
apt autoremove -y >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'apt autoremove'" >> "$LOG_FILE"
apt autoclean >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'apt autoclean'" >> "$LOG_FILE"

# Mise à jour Snap
if command -v snap &> /dev/null; then
    echo ">> Mise à jour des paquets Snap..."
    snap refresh >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'snap refresh'" >> "$LOG_FILE"
fi

# Mise à jour Flatpak
if command -v flatpak &> /dev/null; then
    echo ">> Mise à jour des paquets Flatpak..."
    flatpak update -y >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'flatpak update'" >> "$LOG_FILE"
fi

# Mise à jour Python (pip3)
if command -v pip3 &> /dev/null; then
    echo ">> Mise à jour des paquets Python (pip3)..."
    pip3 install --upgrade pip >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de 'pip3 install --upgrade pip'" >> "$LOG_FILE"
    pip3 list --outdated --format=freeze | cut -d= -f1 | xargs -n1 pip3 install -U >> "$LOG_FILE" 2>&1 || echo "⚠️  Échec de mise à jour des paquets Python" >> "$LOG_FILE"
fi

echo ""
echo "✅ Mise à jour terminée. Consultez le fichier log pour les détails : $LOG_FILE"