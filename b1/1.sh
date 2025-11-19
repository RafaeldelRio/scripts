#!/bin/bash

# Pregunta por un nombre de usuario y a continuación muestre sus procesos en curso.

clear
# -p permite escribir un prompt en la misma línea
read -p "Introduce nombre de usuario: " usuario

# Comprobamos que $usuario no esté vacío.
if [[ -z "$usuario" ]]; then
    echo "Error: No has introducido ningún nombre de usuario."
    exit 1
fi

echo "Los procesos en curso de $usuario son:"
ps -u $usuario