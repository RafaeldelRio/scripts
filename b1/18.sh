#!/bin/bash

: <<'FIN'
Un script que convierta a minúsculas los nombres de archivos de un directorio
dado por teclado.
FIN

clear

if [[ $# -ne 1 ]]; then
    echo "Error: Debes proporcionar un directorio como argumento"
    echo "Uso: $0 <directorio>"
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "Error: El directorio $1 no existe"
    exit 1
fi

listado=$(ls $1)

echo "$listado" | tr [A-Z] [a-z]