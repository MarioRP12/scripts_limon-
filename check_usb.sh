#!/usr/bin/env bash

# Verificar si la memoria USB está conectada
if lsblk -o NAME | grep -q "sdb1"; then
    # Realizar el montaje de la USB
    /usr/bin/pmount /dev/sdb1

    # Ejecutar el script de respaldo después del montaje
    /home/mario/backup_script.sh
fi

