#!/bin/bash

# Escribe un script que reciba un directorio como argumento y cuente cuántos archivos de texto (`.txt`) contiene.

# Validamos que se haya pasado un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <directorio>"
  exit 1
fi

DIR="$1"

# Validamos que el argumento sea un directorio válido
if [ ! -d "$DIR" ]; then
  echo "El directorio $DIR no existe."
  exit 1
fi

# Buscamos archivos (-type f) que terminen en .txt en el directorio actual (-maxdepth 1) y contamos las líneas (wc -l)
# Alternativa: ls -1 "$DIR"/*.txt 2>/dev/null | wc -l (más simple pero falla si hay muchos archivos o nombres raros)
# Alternativa Bash puro: files=("$DIR"/*.txt); count=${#files[@]}; echo $count
count=$(find "$DIR" -maxdepth 1 -type f -name "*.txt" | wc -l)
echo "El directorio $DIR contiene $count archivos .txt."