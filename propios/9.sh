#!/bin/bash
echo "Introduce el nombre de un archivo o directorio:"
read nombre

# Comprueba si la ruta `$nombre` existe.
if [ -e "$nombre" ]; then
  echo "El archivo o directorio '$nombre' existe."
else
  echo "El archivo o directorio '$nombre' no existe."
fi