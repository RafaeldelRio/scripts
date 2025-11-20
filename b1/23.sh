#!/bin/bash

# Intercambiar el nombre de dos archivos usando repetidamente el mandato mv.

# Validar que se proporcionaron dos argumentos
if [[ $# -ne 2 ]]; then
    echo "Error: Debes proporcionar dos archivos como argumentos"
    echo "Uso: $0 <archivo1> <archivo2>"
    exit 1
fi

archivo1="$1"
archivo2="$2"
auxiliar=".temp_swap_$$"  # $$ es el PID del proceso (único)

# Validar que ambos archivos existen
if [[ ! -f "$archivo1" ]]; then
    echo "Error: El archivo '$archivo1' no existe"
    exit 1
fi

if [[ ! -f "$archivo2" ]]; then
    echo "Error: El archivo '$archivo2' no existe"
    exit 1
fi

# Realizar el intercambio
echo "Intercambiando '$archivo1' ↔ '$archivo2'..."
mv "$archivo1" "$auxiliar"
mv "$archivo2" "$archivo1"
mv "$auxiliar" "$archivo2"
echo "¡Intercambio completado!"
