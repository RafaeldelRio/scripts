#!/bin/bash

# Copia de seguridad automática.
# Crea un script que copie todos los archivos de un directorio a otro llamado backup, creando este último si no existe.

if [ -z "$1" ]; then
  echo "Uso: $0 <directorio_origen>"
  exit 1
fi

SOURCE="$1"
DEST="./backup"

# Validamos origen
if [ ! -d "$SOURCE" ]; then
  echo "El directorio origen no existe."
  exit 1
fi

# Creamos destino si no existe
if [ ! -d "$DEST" ]; then
  mkdir "$DEST"
  echo "Directorio '$DEST' creado."
fi

# Copia recursiva de todo el contenido
# Alternativa: rsync -av --exclude 'backup' "$SOURCE"/ "$DEST"/ (más robusto, evita copiar backup dentro de sí mismo si está en el source)
cp -r "$SOURCE"/* "$DEST"/ 2>/dev/null
if [ $? -eq 0 ]; then
  echo "Archivos copiados de '$SOURCE' a '$DEST'."
else
  echo "Advertencia: El directorio origen podría estar vacío o hubo un error."
fi