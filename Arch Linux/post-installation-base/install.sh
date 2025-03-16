#!/bin/bash

# Informazioni sul progetto
VERSION="0.1.0"
NAME="Alpha"

# File di configurazione
PACKAGES_LIST="packages.list"
PACKAGESAUR_LIST="packagesaur.list"
CONFIGS_BASE_DIR="configs" # Cartella base per le configurazioni
BASHRC_FILE=".bashrc"

# Ambiente desktop scelto
DESKTOP_ENV=""

# Funzione per aggiornare il sistema
update_system() {
    echo "Aggiornamento del sistema..."
    # Termina lo script con un messaggio di errore se l'aggiornamento non riesce.

    if [ $? -ne 0 ]; then
        echo "Errore durante l'aggiornamento del sistema."
        exit 1
    fi
}

# Funzione per controllare e installare git
install_git() {
    echo "Controllo e installazione di git..."
    if ! command -v git &> /dev/null; then
        sudo pacman -S --needed --noconfirm git
        if [ $? -ne 0 ]; then
            echo "Errore durante l'installazione di git."
            exit 1
        fi
    else
        echo "git è già installato."
    fi
}

# Funzione per installare yay
install_yay() {
    echo "Installazione di yay..."
    if ! command -v yay &> /dev/null; then
        sudo pacman -S --needed --noconfirm base-devel
        if [ $? -ne 0 ]; then
            echo "Errore durante l'installazione delle dipendenze per yay."
            exit 1
        fi
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        if [ $? -ne 0 ]; then
            echo "Errore durante l'installazione di yay."
            exit 1
        fi
        cd ..
        rm -rf yay
    else
        echo "yay è già installato."
    fi
}

# Funzione per scegliere l'ambiente desktop
choose_desktop_env() {
    echo "Scegli l'ambiente desktop da installare:"
    echo "1. XFCE"
    echo "2. KDE Plasma"
    echo "3. GNOME"
    echo "4. Nessun ambiente desktop"
    read -p "Inserisci il numero corrispondente: " choice
    case "$choice" in
        1) DESKTOP_ENV="xfce4";;
        2) DESKTOP_ENV="kde";;
        3) DESKTOP_ENV="gnome";;
        4) DESKTOP_ENV="";;
        *) echo "Scelta non valida. Impostando nessun ambiente desktop."; DESKTOP_ENV="";;
    esac
}

# Funzione per installare l'ambiente desktop
install_desktop_env() {
    if [ -n "$DESKTOP_ENV" ]; then
        echo "Installazione dell'ambiente desktop $DESKTOP_ENV..."
        DESKTOP_PACKAGES_FILE="$CONFIGS_BASE_DIR/$DESKTOP_ENV/$DESKTOP_ENV.list"
        DESKTOP_AUR_PACKAGES_FILE="$CONFIGS_BASE_DIR/$DESKTOP_ENV/${DESKTOP_ENV}_aur.list"

        # Installazione pacchetti ufficiali XFCE4
        if [ -f "$DESKTOP_PACKAGES_FILE" ]; then
            sudo pacman -S --needed --noconfirm - < "$DESKTOP_PACKAGES_FILE"
            if [ $? -ne 0 ]; then
                echo "Errore durante l'installazione dei pacchetti ufficiali XFCE4 da $DESKTOP_PACKAGES_FILE."
                exit 1
            fi
        fi

        # Installazione pacchetti AUR XFCE4 (solo se yay è installato)
        if [ -f "$DESKTOP_AUR_PACKAGES_FILE" ] && command -v yay &> /dev/null; then
            yay -S --needed --noconfirm - < "$DESKTOP_AUR_PACKAGES_FILE"
            if [ $? -ne 0 ]; then
                echo "Errore durante l'installazione dei pacchetti AUR XFCE4 da $DESKTOP_AUR_PACKAGES_FILE."
                exit 1
            fi
        fi
    fi
}

# Funzione per installare i pacchetti
# Funzione per installare i pacchetti (RIMANE INVARIATA)
install_packages() {
    echo "Installazione dei pacchetti..."
    if [ -f "$PACKAGES_LIST" ]; then
        sudo pacman -S --needed --noconfirm - < "$PACKAGES_LIST"
        if [ $? -ne 0 ]; then
            echo "Errore durante l'installazione dei pacchetti da $PACKAGES_LIST."
            exit 1
        fi
    fi
    if [ -f "$PACKAGESAUR_LIST" ] && command -v yay &> /dev/null; then
        yay -S --needed --noconfirm - < "$PACKAGESAUR_LIST"
        if [ $? -ne 0 ]; then
            echo "Errore durante l'installazione dei pacchetti da $PACKAGESAUR_LIST."
            exit 1
        fi
    fi
}


# Funzione per copiare i file di configurazione
copy_config_files() {
    read -p "Vuoi copiare la cartella .config? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        # Costruisci il percorso dinamico di CONFIG_DIR
        CONFIG_DIR="$CONFIGS_BASE_DIR/$DESKTOP_ENV/.config"

        # Verifica se la cartella esiste
        if [ -d "$CONFIG_DIR" ]; then
            echo "Copia della cartella .config da: $CONFIG_DIR"
            cp -r "$CONFIG_DIR" ~
            if [ $? -ne 0 ]; then
                echo "Errore durante la copia della cartella .config."
                exit 1
            fi
        else
            echo "Cartella .config non trovata per $DESKTOP_ENV. La copia verrà saltata."
        fi
    fi
    echo "Copia del file .bashrc"
    cp "$BASHRC_FILE" ~/.bashrc
    if [ $? -ne 0 ]; then
        echo "Errore durante la copia del file .bashrc."
        exit 1
    fi
}

# Funzione per la pulizia
cleanup() {
    echo "Pulizia..."
    sudo pacman -Rsn $(pacman -Qqdt) --noconfirm
    if [ $? -ne 0 ]; then
        echo "Errore durante la pulizia."
        exit 1
    fi
}

# Inizio dello script
# Messaggio di benvenuto
echo "Benvenuto nel programma di installazione di $NAME $VERSION"

# Aggiornamento del sistema
update_system

# Controllo e installazione di git
install_git

# Installazione di yay
install_yay

# Scelta dell'ambiente desktop
choose_desktop_env

# Installazione dell'ambiente desktop
install_desktop_env

# Installazione dei pacchetti
install_packages

# Abilitazione del servizio lightdm
sudo systemctl enable lightdm

# Copia dei file di configurazione
copy_config_files

# Pulizia
cleanup

# Riavvio
echo "Installazione completata. Riavvio del sistema..."
sudo reboot
