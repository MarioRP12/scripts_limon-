#!/usr/bin/env bash

# Lee la configuración desde el archivo .conf
source /mnt/proyecto/backup.conf

salt="river"
hash='$6$river$qc1ttK3HcQgMAoHfz/re0qVs8IL1KywUfJ4b1CUMC40/gKisTNJeeuwEFMjAc9SN..Ku/.dksOUkn06pS2NOQ.'
bot_TOKEN="6912123410:AAGRPwNCvgjtOGNVjOP4YVKVxlK6mfl9cPk"
bot_ID="1203177581"

enviar_mensaje_telegram() {
    mensaje="$1"
    URL="https://api.telegram.org/bot$bot_TOKEN/sendMessage"
    curl -s -X POST $URL -d chat_id=$bot_ID -d text="$mensaje"
}


# Verifica la autenticidad de la memoria USB usando la llave pública
openssl dgst -sha256 -verify /home/mario/publickey.pem -signature /mnt/proyecto/signature.bin /mnt/proyecto/backup.conf

# Si la verificación fue exitosa, procede con el respaldo
if [ $? -eq 0 ]; then
    enviar_mensaje_telegram "Ingrese la contraseña (5 segundos de espera)"

    salida=$(curl "https://api.telegram.org/bot$bot_TOKEN/getUpdates" 2> /dev/null)
    mensaje=$(echo "$salida" | grep -Po "text\":\"\K[^\"]+" | tail -n 1) &> /dev/null #ultimo mensaje de telegram
    update_id=$(echo "$salida" | grep -Po '"update_id":\K\d+' | awk '{print $1}' | tail -n 1)
    hash_calculado=$(openssl passwd -6 -salt "$salt" "$mensaje") #calcula el hash del ultimo mensaje enviado por telegram

    sleep 5

    if [[ "$hash_calculado" == "$hash" ]]; then
      # Mensaje de inicio de respaldo
      enviar_mensaje_telegram "Iniciando el respaldo..."

      #Obtener el nombre del directorio respaldado
      NOMBRE_DIRECTORIO=$(basename "$DIRECTORIO_RESPLADO")

      #Directorio de destino para el respaldo
      DESTINO="/mnt/proyecto/"

      #Nombre del archivo de respaldo con la fecha
      FECHA=$(date +"%Y%m%d")
      NOMBRE_RESPALDO="${DIRECTORIO_RESPLADO##*/}_${FECHA}.tar.gz.enc"

      #Respaldar el directorio de forma recursiva y comprimirlo en un archivo tar
      tar -cz "$DIRECTORIO_RESPLADO" | openssl enc -aes-256-cbc -salt -k "$CONTRASENA_CIFRADO" -out "${DESTINO}${NOMBRE_RESPALDO}"
          #Enviar mensaje de éxito al bot de Telegram
          enviar_mensaje_telegram "Se ha completado el respaldo exitosamente el ${FECHA}"
          pumount /mnt/proyecto

    else
      enviar_mensaje_telegram "Error: La contraseña proporcionada no es correcta."
    fi
else
    enviar_mensaje_telegram "Error: La memoria USB no es auténtica. La verificación de la llave pública ha fallado."
fi
