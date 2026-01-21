#!/bin/bash

# Gestión de archivos grandes.
# Diseña un script que busque en un directorio todos los archivos mayores de 10 MB y los liste.

DIR="${1:-.}"

# Verificamos si el directorio existe
if [ ! -d "$DIR" ]; then
  echo "El directorio no existe."
  exit 1
fi

echo "Archivos mayores de 10 MB en '$DIR':"
# find busca archivos (-type f) mayores a 10MB (-size +10M)
# -exec ls -lh {} \; ejecuta ls en cada resultado para ver detalles
# awk filtra para mostrar solo el nombre (columna 9) y el tamaño (columna 5)
# Alternativa más rápida: find "$DIR" -type f -size +10M -print0 | xargs -0 ls -lh | awk ...
find "$DIR" -type f -size +10M -exec ls -lh {} \; | awk '{print $9 ": " $5}'