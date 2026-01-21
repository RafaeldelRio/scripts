#!/bin/bash

# Ordenar palabras en un archivo.
# Diseña un script que reciba un archivo de texto y escriba otro archivo con sus palabras ordenadas alfabéticamente.

# Validamos que se pase un archivo como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo>"
  exit 1
fi

FILE="$1"

# Verificamos si el archivo existe
if [ ! -f "$FILE" ]; then
  echo "El archivo no existe."
  exit 1
fi

# Definimos el nombre del archivo de salida
OUTPUT="${FILE%.*}_ordenado.txt"

# Usamos tr para convertir espacios y nuevas líneas en saltos de línea para aislar palabras,
# eliminamos líneas vacías con grep y luego ordenamos con sort.
# Alternativa: sed 's/[[:space:]]\+/\n/g' "$FILE" | sort | uniq (si se quieren palabras únicas)
# Alternativa: awk '{for(i=1;i<=NF;i++) print $i}' "$FILE" | sort
tr -s '[:space:]' '\n' < "$FILE" | grep -v '^$' | sort > "$OUTPUT"
echo "Palabras ordenadas guardadas en $OUTPUT"