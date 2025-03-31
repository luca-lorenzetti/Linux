#!/bin/bash

# Variabili
PROFILE="releng"
ISO_NAME="arch-custom.iso"

# Installazione dei pacchetti necessari
echo "Installazione di archiso e qemu-system-x86_64..."
sudo pacman -S --needed archiso qemu-system-x86_64 || {
  echo "Errore durante l'installazione dei pacchetti. Uscita."
  exit 1
}

# Creazione della directory di lavoro
mkdir archiso-build
cd archiso-build

# Copia del profilo di esempio
cp -r /usr/share/archiso/configs/$PROFILE .

# Elenco dei pacchetti installati
pacman -Qqe > installed_packages.txt

# Aggiunta dei pacchetti a packages.x86_64
cat installed_packages.txt >> $PROFILE/packages.x86_64

# Copia dei file di configurazione (esempio)
sudo cp /etc/locale.gen $PROFILE/airootfs/etc/
sudo cp /etc/locale.conf $PROFILE/airootfs/etc/

# Personalizzazione di profiledef.sh (esempio)
echo "loadkeys it" >> $PROFILE/profiledef.sh
echo "setfont ter-132n" >> $PROFILE/profiledef.sh

# Creazione dell'immagine ISO
sudo mkarchiso -v -w . -o $ISO_NAME $PROFILE

echo "Immagine ISO creata: $ISO_NAME"

# Lancio dell'immagine ISO con qemu
qemu-system-x86_64 -m 2G -cdrom $ISO_NAME
