#!/bin/bash

# Diseña un script que verifique si los archivos de un directorio están vacíos o no, y muestre un mensaje para cada
# archivo.

# Usamos el primer argumento como directorio, o el directorio actual si no se especifica
DIR="${1:-.}"

# Verificamos si el directorio existe
if [ ! -d "$DIR" ]; then
  echo "El directorio $DIR no existe."
  exit 1
fi

# Iteramos sobre todos los archivos del directorio
for file in "$DIR"/*; do
  # Comprobamos si es un archivo regular
  if [ -f "$file" ]; then
    # -s verifica si el archivo tiene un tamaño mayor que 0
    # Alternativa: size=$(stat -c%s "$file"); if [ "$size" -gt 0 ]; ... (usando stat para obtener tamaño exacto)
    if [ -s "$file" ]; then
      echo "El archivo $(basename "$file") NO está vacío."
    else
      echo "El archivo $(basename "$file") está vacío."
    fi
  fi
done