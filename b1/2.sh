#!/bin/bash

# Ver el contenido de un directorio de un usuario introducido por teclado.

clear
read -p "¿De qué usuario quieres ver el directorio home? " usuario

ruta_home="/home/$usuario"

# Verificar si el usuario introducido es vacío
if [[ -z "$usuario" ]]; then
    echo "Error: No has introducido ningún nombre de usuario."
    exit 1
fi

# Verificar si NO existe el directorio
if [[ ! -d "$ruta_home" ]]; then
    echo "Error: El directorio '$ruta_home' no existe."
    exit 1
fi


ls -l $ruta_home