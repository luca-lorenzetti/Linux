#!/bin/bash

# Variabili
PARTIZIONE="/dev/sda1"  # Sostituisci con la partizione del tuo sistema
IMMAGINE="arch_system.img"

# Verifica dei privilegi di root
if [[ $EUID -ne 0 ]]; then
  echo "Questo script deve essere eseguito come root."
  exit 1
fi

# Creazione dell'immagine
dd if="$PARTIZIONE" of="$IMMAGINE" bs=4M status=progress

echo "Immagine creata con successo: $IMMAGINE"
