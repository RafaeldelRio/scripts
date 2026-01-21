#!/bin/bash

# Crea un script que encuentre todos los archivos que contienen una palabra específica y los muestre en pantalla.

# Se requieren al menos 2 argumentos: directorio y palabra
if [ $# -lt 2 ]; then
  echo "Uso: $0 <directorio> <palabra>"
  exit 1
fi

DIR="$1"
WORD="$2"

# Validación del directorio
if [ ! -d "$DIR" ]; then
  echo "El directorio $DIR no existe."
  exit 1
fi

echo "Archivos que contienen '$WORD' en '$DIR':"
# grep -r (recursivo) -w (palabra completa) -l (solo mostrar nombre de archivo)
# Alternativa: find "$DIR" -type f -exec grep -l "$WORD" {} + (útil si se quieren filtrar tipos de archivo antes de grep)
grep -rwl "$WORD" "$DIR"