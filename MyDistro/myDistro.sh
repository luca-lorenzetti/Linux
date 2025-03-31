#!/bin/bash

# Variabili di configurazione
DIST_NAME="mia-distro"
WORKDIR="./build"
ISO_PATH="./$DIST_NAME.iso"
MOUNTPOINT="$WORKDIR/rootfs"
ARCH_PACKAGES_FILE="arch_packages.list"
AUR_PACKAGES_FILE="aur_packages.list"
EFI_MOUNTPOINT="$MOUNTPOINT/boot/efi"

# Funzione per gestire gli errori
error_exit() {
  echo "Errore: $1"
  cleanup
  exit 1
}

# Funzione per montare le partizioni
mount_partitions() {
  if [ ! -d "$MOUNTPOINT/dev" ]; then
    sudo mkdir -p $MOUNTPOINT/dev || error_exit "Impossibile creare $MOUNTPOINT/dev"
  fi
  if [ ! -d "$MOUNTPOINT/proc" ]; then
    sudo mkdir -p $MOUNTPOINT/proc || error_exit "Impossibile creare $MOUNTPOINT/proc"
  fi
  if [ ! -d "$MOUNTPOINT/sys" ]; then
    sudo mkdir -p $MOUNTPOINT/sys || error_exit "Impossibile creare $MOUNTPOINT/sys"
  fi
  if [ ! -d "$MOUNTPOINT/dev/pts" ]; then
    sudo mkdir -p $MOUNTPOINT/dev/pts || error_exit "Impossibile creare $MOUNTPOINT/dev/pts"
  fi

  sudo mount -o bind /dev $MOUNTPOINT/dev || error_exit "Impossibile montare /dev"
  sudo mount -o bind /dev/pts $MOUNTPOINT/dev/pts || error_exit "Impossibile montare /dev/pts"
  sudo mount -o bind /proc $MOUNTPOINT/proc || error_exit "Impossibile montare /proc"
  sudo mount -o bind /sys $MOUNTPOINT/sys || error_exit "Impossibile montare /sys"
}

# Funzione per smontare le partizioni
umount_partitions() {
  sudo umount $MOUNTPOINT/dev
  sudo umount $MOUNTPOINT/dev/pts
  sudo umount $MOUNTPOINT/proc
  sudo umount $MOUNTPOINT/sys
}

# Funzione per pulire le directory temporanee
cleanup() {
  umount_partitions
  sudo rm -rf $MOUNTPOINT
}

# Funzione per installare i pacchetti dai repository di Arch
install_arch_packages() {
  if [ -f "$ARCH_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$ARCH_PACKAGES_FILE")
    sudo chroot $MOUNTPOINT /bin/bash -c "pacman -Sy --noconfirm $PACKAGES" || error_exit "Errore durante l'installazione dei pacchetti da Arch"
  else
    echo "File $ARCH_PACKAGES_FILE non trovato."
  fi
}

# Funzione per installare i pacchetti dall'AUR
install_aur_packages() {
  if [ -f "$AUR_PACKAGES_FILE" ]; then
    PACKAGES=$(cat "$AUR_PACKAGES_FILE")
    sudo chroot $MOUNTPOINT /bin/bash -c "yay -S --noconfirm $PACKAGES" || error_exit "Errore durante l'installazione dei pacchetti dall'AUR"
  else
    echo "File $AUR_PACKAGES_FILE non trovato."
  fi
}

# Funzione principale
main() {
  mkdir -p $MOUNTPOINT
  mount_partitions
  install_arch_packages
  install_aur_packages

  # Crea il file /etc/hostname
  echo "$DIST_NAME" | sudo tee $MOUNTPOINT/etc/hostname

  sudo chroot $MOUNTPOINT /bin/bash -c "echo '127.0.0.1 localhost' > /etc/hosts"
  sudo chroot $MOUNTPOINT /bin/bash -c "echo '127.0.0.1 $DIST_NAME' >> /etc/hosts"

  #Installa GRUB
  sudo chroot $MOUNTPOINT /bin/bash -c "pacman -S --noconfirm grub efibootmgr" || error_exit "Errore durante l'installazione di GRUB e efibootmgr"

  #Monta la partizione EFI se presente
  if [[ -d "$EFI_MOUNTPOINT" ]]; then
      sudo chroot $MOUNTPOINT /bin/bash -c "mount /dev/$(findmnt -n -o SOURCE /boot/efi) $EFI_MOUNTPOINT"
  fi

  #Verifica l'esistenza di /bin/bash
  if [[ -f "$MOUNTPOINT/bin/bash" ]]; then
      sudo chroot $MOUNTPOINT /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB" || error_exit "Errore durante l'installazione di GRUB"
      sudo chroot $MOUNTPOINT /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" || error_exit "Errore durante la configurazione di GRUB"
  else
      error_exit "/bin/bash non trovato nell'ambiente chroot"
  fi

  sudo genisoimage -o $ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -cache-inodes -J -R -T $MOUNTPOINT || error_exit "Errore durante la creazione dell'immagine ISO"
  echo "Immagine ISO creata: $ISO_PATH"
  cleanup
}

main
