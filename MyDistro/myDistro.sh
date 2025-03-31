#!/bin/bash

# Variabili di configurazione
DIST_NAME="mia-distro" # Nome della tua distribuzione
WORKDIR="./build" # Directory di lavoro per la build
ISO_PATH="./$DIST_NAME.iso" # Percorso dell'immagine ISO risultante
MOUNTPOINT="$WORKDIR/rootfs" # Punto di montaggio per il rootfs
ARCH_PACKAGES_FILE="arch_packages.list" # File con i pacchetti dei repository di Arch
AUR_PACKAGES_FILE="aur_packages.list" # File con i pacchetti AUR

# Funzione per gestire gli errori e uscire dallo script
error_exit() {
  echo "Errore: $1" # Stampa il messaggio di errore
  cleanup # Esegue la pulizia delle partizioni e delle directory temporanee
  exit 1 # Esce dallo script con codice di errore 1
}

# Funzione per montare le partizioni necessarie
mount_partitions() {
  # Crea la directory $MOUNTPOINT/dev se non esiste
  if [ ! -d "$MOUNTPOINT/dev" ]; then
    sudo mkdir -p $MOUNTPOINT/dev || error_exit "Impossibile creare $MOUNTPOINT/dev"
  fi

  # Monta le directory di sistema necessarie all'interno del chroot
  sudo mount -o bind /dev $MOUNTPOINT/dev || error_exit "Impossibile montare /dev"
  sudo mount -o bind /dev/pts $MOUNTPOINT/dev/pts || error_exit "Impossibile montare /dev/pts"
  sudo mount -o bind /proc $MOUNTPOINT/proc || error_exit "Impossibile montare /proc"
  sudo mount -o bind /sys $MOUNTPOINT/sys || error_exit "Impossibile montare /sys"
}

# Funzione per smontare le partizioni
umount_partitions() {
  # Smonta le directory di sistema montate in precedenza
  sudo umount $MOUNTPOINT/dev
  sudo umount $MOUNTPOINT/dev/pts
  sudo umount $MOUNTPOINT/proc
  sudo umount $MOUNTPOINT/sys
}

# Funzione per pulire le directory temporanee
cleanup() {
  # Smonta le partizioni e rimuove la directory del rootfs
  umount_partitions
  sudo rm -rf $MOUNTPOINT
}

# Funzione per installare i pacchetti dai repository di Arch
install_arch_packages() {
  if [ -f "$ARCH_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$ARCH_PACKAGES_FILE") # Legge i pacchetti dal file
    sudo arch-chroot $MOUNTPOINT /bin/bash -c "pacman -Sy --noconfirm $PACKAGES" || error_exit "Errore durante l'installazione dei pacchetti da Arch"
  else
    echo "File $ARCH_PACKAGES_FILE non trovato."
  fi
}

# Funzione per installare i pacchetti dall'AUR
install_aur_packages() {
  if [ -f "$AUR_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$AUR_PACKAGES_FILE") # Legge i pacchetti dal file
    sudo arch-chroot $MOUNTPOINT /bin/bash -c "yay -S --noconfirm $PACKAGES" || error_exit "Errore durante l'installazione dei pacchetti dall'AUR"
  else
    echo "File $AUR_PACKAGES_FILE non trovato."
  fi
}

# Funzione principale per la creazione dell'ISO
main() {
  # 1. Crea la directory di lavoro del rootfs
  mkdir -p $MOUNTPOINT

  # 2. Monta le partizioni necessarie
  mount_partitions

  # 3. Installa i pacchetti dai repository di Arch
  install_arch_packages

  # 4. Installa i pacchetti dall'AUR
  install_aur_packages

  # 5. Configura il sistema all'interno del chroot (esempio: imposta il nome host)
  echo "$DIST_NAME" | sudo tee $MOUNTPOINT/etc/hostname
  sudo arch-chroot $MOUNTPOINT /bin/bash -c "echo '127.0.0.1 localhost' > /etc/hosts"
  sudo arch-chroot $MOUNTPOINT /bin/bash -c "echo '127.0.0.1 $DIST_NAME' >> /etc/hosts"

  # 6. Installa e configura il bootloader GRUB
  sudo arch-chroot $MOUNTPOINT /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB" || error_exit "Errore durante l'installazione di GRUB"
  sudo arch-chroot $MOUNTPOINT /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" || error_exit "Errore durante la configurazione di GRUB"

  # 7. Crea l'immagine ISO utilizzando genisoimage
  sudo genisoimage -o $ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -cache-inodes -J -R -T $MOUNTPOINT || error_exit "Errore durante la creazione dell'immagine ISO"

  # Stampa un messaggio di successo
  echo "Immagine ISO creata: $ISO_PATH"

  # 8. Esegue la pulizia delle partizioni e cartelle temporanee.
  cleanup
}

# Esegue la funzione principale
main
