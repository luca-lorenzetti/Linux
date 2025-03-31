#!/bin/bash

# Variabili
PROFILE="releng"
ISO_NAME="arch-custom.iso"

# Creazione della directory di lavoro
mkdir archiso-build
cd archiso-build

# Copia del profilo di esempio
cp -r /usr/share/archiso/configs/$PROFILE .

# Personalizzazione del profilo (esempio)
echo "vim" >> $PROFILE/packages.x86_64
echo "tmux" >> $PROFILE/packages.x86_64

# Creazione dell'immagine ISO
sudo mkarchiso -v -w . -o $ISO_NAME $PROFILE

echo "Immagine ISO creata: $ISO_NAME"
