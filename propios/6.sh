#!/bin/bash

# Enunciado: Crea un script que cuente y muestre el número total de archivos 
# regulares (no directorios) que existen en el directorio actual.

CONTADOR=0
echo "--- Contando archivos en el directorio actual (./) ---"
for ELEMENTO in *; do
    if [[ -f "$ELEMENTO" ]]; then
        CONTADOR=$((CONTADOR + 1))
    fi
done

echo "--------------------------------------------------------"
echo "Número total de archivos regulares encontrados: $CONTADOR"
echo "--------------------------------------------------------"