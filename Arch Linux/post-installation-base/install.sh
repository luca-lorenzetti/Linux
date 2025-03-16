#!/bin/bash

# Informazioni sul progetto
VERSION="0.1.0"
PROJECT_NAME="alscript"

# File di configurazione
PACKAGES_LIST="packages.list"
PACKAGESAUR_LIST="packagesaur.list"
CONFIGS_BASE_DIR="configs" # Cartella base per le configurazioni
BASHRC_FILE=".bashrc"
ASCII_FILE="ASCII.txt"

# Variabili per le scelte dell'utente
DESKTOP_ENV=""
COPY_CONFIG="n" # Default: non copiare la cartella .config

# Funzione per raccogliere le informazioni iniziali
gather_initial_info() {
    # Messaggio di benvenuto con stile ASCII da file
    if [ -f "$ASCII_FILE" ]; then
        echo "$(tput setaf 6)" # Set color before printing ASCII art
        cat "$ASCII_FILE"
        echo "$(tput sgr0)" # Reset color after printing ASCII art
        echo "$(tput setaf 2)  Versione: $VERSION $(tput sgr0)"
    else
        echo "Errore: file $ASCII_FILE non trovato."
    fi
    echo "Benvenuto nel programma di installazione di $PROJECT_NAME"

    # Scelta dell'ambiente desktop
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

    # Scelta se copiare la cartella .config
    read -p "Vuoi copiare la cartella .config? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        COPY_CONFIG="y"
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    echo "Aggiornamento del sistema..."
    sudo pacman -Syy --noconfirm && sudo pacman -Syu --noconfirm
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

    # Check if yay is already installed
    if command -v yay &> /dev/null; then
        echo "yay è già installato."
        return 0 # Exit successfully
    fi

    # Install base-devel
    echo "Installazione di base-devel (dipendenze per yay)..."
    sudo pacman -S --needed --noconfirm base-devel
    if [ $? -ne 0 ]; then
        echo "Errore: impossibile installare base-devel. Controlla la tua connessione internet e i mirror di pacman."
        exit 1
    fi

    # Clone the yay repository
    echo "Clonazione del repository yay da AUR..."
    rm -rf yay # Remove any existing yay directory
    git clone https://aur.archlinux.org/yay.git
    if [ $? -ne 0 ]; then
        echo "Errore: impossibile clonare il repository yay. Controlla la tua connessione internet e che git sia installato correttamente."
        exit 1
    fi

    # Build and install yay
    echo "Compilazione e installazione di yay..."
    cd yay || { echo "Errore: impossibile accedere alla cartella yay."; exit 1; } # Exit if cd fails

    # Clean the build directory
    makepkg -C --noconfirm || { echo "Errore: impossibile pulire la cartella di compilazione."; exit 1; }

    # Capture and display the full output of makepkg
    makepkg -si --noconfirm 2>&1 | tee makepkg.log
    if [ $? -ne 0 ]; then
        echo "Errore: impossibile compilare e installare yay. Controlla il file makepkg.log per maggiori dettagli."
        cat makepkg.log # Display the log in the terminal
        exit 1
    fi

    # Cleanup
    echo "Pulizia..."
    cd .. || { echo "Errore: impossibile tornare alla cartella precedente."; exit 1; } # Exit if cd fails
    rm -rf yay

    echo "yay installato con successo."
    return 0 # Exit successfully
}



# Funzione per installare l'ambiente desktop
install_desktop_env() {
    if [ -n "$DESKTOP_ENV" ]; then
        echo "Installazione dell'ambiente desktop $DESKTOP_ENV..."
        DESKTOP_PACKAGES_FILE="$CONFIGS_BASE_DIR/$DESKTOP_ENV/$DESKTOP_ENV.list"
        DESKTOP_AUR_PACKAGES_FILE="$CONFIGS_BASE_DIR/$DESKTOP_ENV/${DESKTOP_ENV}_aur.list"

        # Installazione pacchetti ufficiali
        if [ -f "$DESKTOP_PACKAGES_FILE" ]; then
            sudo pacman -S --needed --noconfirm - < "$DESKTOP_PACKAGES_FILE"
            if [ $? -ne 0 ]; then
                echo "Errore durante l'installazione dei pacchetti ufficiali da $DESKTOP_PACKAGES_FILE."
                exit 1
            fi
        fi

        # Installazione pacchetti AUR (solo se yay è installato)
        if [ -f "$DESKTOP_AUR_PACKAGES_FILE" ] && command -v yay &> /dev/null; then
            yay -S --needed --noconfirm - < "$DESKTOP_AUR_PACKAGES_FILE"
            if [ $? -ne 0 ]; then
                echo "Errore durante l'installazione dei pacchetti AUR da $DESKTOP_AUR_PACKAGES_FILE."
                exit 1
            fi
        fi
    fi
}

# Funzione per installare i pacchetti
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
    if [[ "$COPY_CONFIG" == "y" ]]; then
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
# Raccolta delle informazioni iniziali
gather_initial_info

# Aggiornamento del sistema
update_system

# Controllo e installazione di git
install_git

# Installazione di yay
install_yay

# Installazione dell'ambiente desktop
install_desktop_env

# Installazione dei pacchetti
install_packages

# Abilitazione del servizio lightdm (solo se è stato scelto un DE)
if [ -n "$DESKTOP_ENV" ]; then
    sudo systemctl enable lightdm
fi

# Copia dei file di configurazione
copy_config_files

# Pulizia
cleanup

# Riavvio
echo "Installazione completata. Riavvio del sistema..."
sudo reboot
