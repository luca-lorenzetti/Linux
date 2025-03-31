#!/bin/bash

# Variabili di configurazione
DIST_NAME="mia-distro"
WORKDIR="./build"
ISO_PATH="./$DIST_NAME.iso"
PROFILE="myprofile"
ARCH_PACKAGES_FILE="arch_packages.list"
AUR_PACKAGES_FILE="aur_packages.list"

# Funzione per gestire gli errori
error_exit() {
  echo "Errore: $1"
  exit 1
}

# Funzione per creare il profilo di archiso
create_profile() {
  mkdir -p $WORKDIR/$PROFILE
  cp -r /usr/share/archiso/configs/releng/ $WORKDIR/$PROFILE/
  # Crea un file profiledef.sh vuoto
  touch $WORKDIR/$PROFILE/profiledef.sh
}

# Funzione per aggiungere i pacchetti dai file .list al profilo
add_packages_to_profile() {
  if [ -f "$ARCH_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$ARCH_PACKAGES_FILE")
    echo "$PACKAGES" >> $WORKDIR/$PROFILE/packages.x86_64
  fi
  if [ -f "$AUR_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$AUR_PACKAGES_FILE")
    echo "$PACKAGES" >> $WORKDIR/$PROFILE/packages.x86_64
  fi
}

# Funzione principale
main() {
  # Installa archiso se non è installato
  if ! command -v mkarchiso &> /dev/null; then
    sudo pacman -S --needed archiso || error_exit "Errore durante l'installazione di archiso"
  fi

  create_profile
  add_packages_to-profile

  # Crea l'immagine ISO
  sudo mkarchiso -v -w $WORKDIR -o $ISO_PATH $WORKDIR/$PROFILE/ || error_exit "Errore durante la creazione dell'immagine ISO"

  echo "Immagine ISO creata: $ISO_PATH"
}

main
