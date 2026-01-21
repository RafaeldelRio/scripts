#!/bin/bash

# Crea un script que reciba un archivo como argumento y calcule cuántas líneas, palabras y caracteres tiene.

# Verificamos si se pasó el archivo
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo>"
  exit 1
fi

# Verificamos que el archivo exista
if [ ! -f "$1" ]; then
  echo "El archivo $1 no existe."
  exit 1
fi

echo "Líneas, palabras y caracteres:"
# wc (word count) muestra por defecto líneas, palabras y bytes
# Alternativa con awk: awk '{l++; w+=NF; c+=length($0)+1} END{print l, w, c}' "$1" (para control total del conteo)
wc "$1"