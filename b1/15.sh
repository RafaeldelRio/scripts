#!/bin/bash

: <<"FIN"
Hacer un shell-script que acepte como argumentos nombres de ficheros y muestre el
contenido de cada uno de ellos precedido de una cabecera con el nombre del fichero.
FIN

# Validar que se hayan pasado argumentos
if [[ $# -eq 0 ]]; then
    echo "Error: Debe proporcionar al menos un archivo como argumento" >&2
    echo "Uso: $0 archivo1 [archivo2 ...]" >&2
    exit 1
fi

clear

# Iterar sobre cada archivo pasado como argumento
for fichero in "$@"; do
    # Verificar que el archivo existe
    if [[ ! -e "$fichero" ]]; then
        echo "Error: '$fichero' no existe" >&2
        continue
    fi
    
    # Verificar que es un archivo regular (no un directorio)
    if [[ ! -f "$fichero" ]]; then
        echo "Error: '$fichero' no es un archivo regular" >&2
        continue
    fi
    
    # Mostrar el contenido del archivo con una cabecera
    echo "=========================================="
    echo "Contenido de: $fichero"
    echo "=========================================="
    cat "$fichero"
    echo ""
done