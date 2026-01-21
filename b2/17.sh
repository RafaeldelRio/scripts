#!/bin/bash

# Validar un archivo de configuración.
# Escribe un script que lea un archivo y verifique si contiene la línea config=true. Si no, agrégala.

# Validamos argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo_config>"
  exit 1
fi

FILE="$1"

# Creamos el archivo si no existe
if [ ! -f "$FILE" ]; then
  touch "$FILE"
  echo "Archivo '$FILE' creado."
fi

# Buscamos la línea exacta 'config=true'
# Alternativa: if grep -q "^config=true$" "$FILE"; then ...
if grep -Fxq "config=true" "$FILE"; then
  echo "'config=true' ya existe en el archivo."
else
  # Aseguramos que haya una nueva línea antes de agregar si el archivo no está vacío
  if [ -s "$FILE" ] && [ "$(tail -c 1 "$FILE")" != "" ]; then
      echo "" >> "$FILE"
  fi
  # Agregamos la configuración
  echo "config=true" >> "$FILE"
  echo "'config=true' agregado."
fi