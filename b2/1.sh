#!/bin/bash

# Crea un script que reciba un archivo como argumento y realice un respaldo del archivo en la misma ubicación,
# añadiendo la extensión `.bak`.

# Verificamos si se ha pasado un argumento (el nombre del archivo)
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo>"
  exit 1
fi

# Verificamos si el archivo existe y es un archivo regular
if [ -f "$1" ]; then
  # Copiamos el archivo con la extensión .bak
  # Alternativa: rsync -a "$1" "$1.bak" (preserva mejor los metadatos y permisos)
  # Alternativa: cat "$1" > "$1.bak" (redirige el contenido, útil si no hay permisos de cp)
  cp "$1" "$1.bak"
  echo "Respaldo creado: $1.bak"
else
  # Si el archivo no existe, mostramos un mensaje de error
  echo "El archivo $1 no existe."
fi