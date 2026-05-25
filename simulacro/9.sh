#!/bin/bash

mostrar_ayuda() {
    echo "Uso: $0 [opciones] <fichero_o_directorio>"
    echo "Opciones permitidas:"
    echo "  -l, --legible      Indica si es legible"
    echo "  -m, --modificable  Indica si es modificable"
    echo "  -x, --ejecutable   Indica si es ejecutable"
    echo "  -h, --help         Muestra este mensaje de ayuda"
}

for argumento in "$@"; do
    if [[ "$argumento" == "-h" || "$argumento" == "--help" ]]; then
        mostrar_ayuda
        exit 0
    fi
done
