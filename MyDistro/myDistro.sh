#!/bin/bash

# Variabili
PARTIZIONE="/dev/sda1"  # Sostituisci con la partizione del tuo sistema
IMMAGINE="arch_system.img"
ISO_NAME="arch_system.iso"
MOUNT_POINT="/mnt/immagine"
ISO_DIR="iso"

# Verifica dei privilegi di root
if [[ $EUID -ne 0 ]]; then
  echo "Questo script deve essere eseguito come root."
  exit 1
fi

# Creazione dell'immagine .img
echo "Creazione dell'immagine .img..."
dd if="$PARTIZIONE" of="$IMMAGINE" bs=4M status=progress

# Montaggio dell'immagine .img
echo "Montaggio dell'immagine .img..."
mkdir -p "$MOUNT_POINT"
sudo mount -o loop "$IMMAGINE" "$MOUNT_POINT"

# Creazione della struttura di directory ISO
echo "Creazione della struttura di directory ISO..."
mkdir -p "$ISO_DIR/boot/grub"

# Copia dei file di boot
echo "Copia dei file di boot..."
sudo cp "$MOUNT_POINT/boot/vmlinuz-linux" "$ISO_DIR/boot/"
sudo cp "$MOUNT_POINT/boot/initramfs-linux.img" "$ISO_DIR/boot/"

# Gestione di intel-ucode e amd-ucode
if [ -f "$MOUNT_POINT/boot/intel-ucode.img" ]; then
  sudo cp "$MOUNT_POINT/boot/intel-ucode.img" "$ISO_DIR/boot/"
fi

if [ -f "$MOUNT_POINT/boot/amd-ucode.img" ]; then
  sudo cp "$MOUNT_POINT/boot/amd-ucode.img" "$ISO_DIR/boot/"
fi

sudo cp "$MOUNT_POINT/boot/grub/grub.cfg" "$ISO_DIR/boot/grub/"

# Copia dei file del sistema
echo "Copia dei file del sistema..."
sudo cp -r "$MOUNT_POINT/"* "$ISO_DIR/"

# Generazione dell'immagine ISO
echo "Generazione dell'immagine ISO..."
genisoimage -o "$ISO_NAME" -b boot/grub/grub.cfg -graft-points /boot /boot /boot/grub /boot/grub "$ISO_DIR"

# Smontaggio dell'immagine .img
echo "Smontaggio dell'immagine .img..."
sudo umount "$MOUNT_POINT"

# Pulizia delle directory temporanee
echo "Pulizia delle directory temporanee..."
sudo rm -rf "$MOUNT_POINT" "$ISO_DIR"

echo "Immagine ISO creata con successo: $ISO_NAME"
