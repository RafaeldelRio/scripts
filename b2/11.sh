#!/bin/bash

# Compresión y copia remota. Comprime un directorio y envíalo a un servidor remoto usando scp.

# Validamos que se reciban al menos 2 argumentos
if [ $# -lt 2 ]; then
 echo "Uso: $0 <directorio> <usuario@host:destino>"
 exit 1
fi

DIR="$1"
REMOTE="$2"

# Verificamos si el directorio existe
if [ ! -d "$DIR" ]; then
 echo "Directorio no existe."
 exit 1
fi

# Eliminamos la barra final para manejar correctamente el nombre del archivo
DIR="${DIR%/}"
ARCHIVE="${DIR##*/}.tar.gz"

echo "Comprimiendo $DIR en $ARCHIVE..."
# Comprimimos el directorio en formato tar.gz
# Alternativa: zip -r "${ARCHIVE%.tar.gz}.zip" "$DIR"
tar -czf "$ARCHIVE" "$DIR"

echo "Enviando $ARCHIVE a $REMOTE..."
# Enviamos el archivo comprimido usando SCP
# Alternativa: rsync -avz -e ssh "$ARCHIVE" "$REMOTE" (mejor para archivos grandes o conexiones inestables)
scp "$ARCHIVE" "$REMOTE"

# Verificamos si la transferencia fue exitosa
if [ $? -eq 0 ]; then
 echo "Enviado correctamente."
 # Eliminamos el archivo comprimido local si se envió correctamente
 rm "$ARCHIVE"
else
 echo "Error al enviar."
 exit 1
fi