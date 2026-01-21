#!/bin/bash

# Crea un script que archive y comprima todos los archivos `.log` de un directorio en un archivo `logs.tar.gz`.

# Obtenemos el directorio del primer argumento o usamos el directorio actual por defecto
DIR="${1:-.}"

# Verificamos si el directorio existe
if [ ! -d "$DIR" ]; then
  echo "El directorio $DIR no existe."
  exit 1
fi

# Buscamos archivos con extensión .log y los comprimimos
# -print0 y --null se usan para manejar correctamente archivos con espacios en el nombre
# Alternativa: zip logs.zip $(find "$DIR" -name "*.log") (si se prefiere formato ZIP, cuidado con los espacios sin precauciones extra)
find "$DIR" -name "*.log" -print0 | tar --null -czf logs.tar.gz -T -

# Verificamos si el comando anterior se ejecutó correctamente
if [ $? -eq 0 ]; then
    echo "Archivos .log de '$DIR' comprimidos en logs.tar.gz"
else
    echo "Hubo un error al comprimir los archivos."
fi