#!/bin/bash

# Script para verificar permisos.
# Diseña un script que compruebe si un archivo tiene permisos de lectura, escritura y ejecución.

# Validamos argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo>"
  exit 1
fi

FILE="$1"

# Verificamos existencia
if [ ! -e "$FILE" ]; then
  echo "El archivo no existe."
  exit 1
fi

echo "Permisos para $FILE:"
# Comprobamos cada permiso con los operadores -r, -w, -x
# Alternativa: stat -c "%A" "$FILE" (muestra los permisos en formato rwxr-xr-x)
# Alternativa: ls -l "$FILE" | awk '{print $1}'
[ -r "$FILE" ] && echo "- Lectura: SÍ" || echo "- Lectura: NO"
[ -w "$FILE" ] && echo "- Escritura: SÍ" || echo "- Escritura: NO"
[ -x "$FILE" ] && echo "- Ejecución: SÍ" || echo "- Ejecución: NO"