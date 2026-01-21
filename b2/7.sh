#!/bin/bash

# Escribe un script que convierta todos los nombres de archivos de un directorio a minúsculas.

# Directorio objetivo, por defecto el actual
DIR="${1:-.}"

# Validación del directorio
if [ ! -d "$DIR" ]; then
    echo "Directorio no encontrado."
    exit 1
fi

# Iteramos sobre cada archivo en el directorio
for file in "$DIR"/*; do
    # Si es un archivo regular
    if [ -f "$file" ]; then
        dir=$(dirname "$file")
        base=$(basename "$file")
        # Convertimos el nombre base a minúsculas usando tr
        # Alternativa (Bash 4.0+): newname="${base,,}" (expansión de parámetros, no requiere subproceso tr)
        newname=$(echo "$base" | tr '[:upper:]' '[:lower:]')
        # Si el nombre cambia, renombramos el archivo
        # Alternativa masiva: rename 'y/A-Z/a-z/' "$DIR"/* (usando comando rename si está instalado)
        if [ "$base" != "$newname" ]; then
            mv "$file" "$dir/$newname"
            echo "Renombrado: $base -> $newname"
        fi
    fi
done