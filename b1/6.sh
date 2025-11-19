#!/bin/bash

# Nos pregunta “¿Quién descubrió América?”, comprobar respuesta correcta y falsa.

read -p "¿Quién descubrió América? " respuesta

# La sintaxis ${variable,,} convierte todo a minúscula (requiere Bash 4.0+)
respuesta_min="${respuesta,,}"

case $respuesta_min in
    col[oó]n)
        echo "es correcto"
        ;;
    *) 
        echo no es correcto
        ;;
esac