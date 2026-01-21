#!/bin/bash

# Crea un script que encuentre todos los archivos que contienen una palabra específica y los muestre en pantalla.

# Verificamos argumentos
if [ $# -lt 2 ]; then
  echo "Uso: $0 <directorio> <palabra>"
  exit 1
fi

DIR="$1"
WORD="$2"

# Verificamos si el directorio existe
if [ ! -d "$DIR" ]; then
  echo "El directorio $DIR no existe."
  exit 1
fi

echo "Archivos que contienen '$WORD' en '$DIR':"
# grep busca recursivamente la palabra exacta en los archivos y lista sus nombres
# Alternativa: find "$DIR" -type f -print0 | xargs -0 grep -l "$WORD" (más eficiente para muchísimos archivos)
grep -rwl "$WORD" "$DIR"