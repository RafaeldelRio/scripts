#!/bin/bash

# Cambio masivo de extensiones.
# Escribe un script que cambie la extensión de todos los archivos .txt de un directorio a .bak.

DIR="${1:-.}"

# Validación del directorio
if [ ! -d "$DIR" ]; then
  echo "Directorio no existe."
  exit 1
fi

count=0
# Habilitamos nullglob para evitar errores si no hay coincidencias
shopt -s nullglob
for file in "$DIR"/*.txt; do
    # Renommbramos usando expansión de parámetros para quitar la extensión antigua
    # Alternativa: newname=$(basename "$file" .txt).bak; mv "$file" "$(dirname "$file")/$newname"
    mv "$file" "${file%.txt}.bak"
    echo "Cambiado: $(basename "$file") -> $(basename "${file%.txt}.bak")"
    ((count++))
done

if [ $count -eq 0 ]; then
    echo "No se encontraron archivos .txt en $DIR"
fi