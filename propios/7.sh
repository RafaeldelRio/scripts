#!/bin/bash

# Un script que muestre el directorio de trabajo actual y liste su contenido.


# Obtener el directorio de trabajo actual y guardarlo en la variable 'directorio_actual'
directorio_actual=$(pwd)

# Mostrar el directorio de trabajo actual
echo "Te encuentras en el directorio: $directorio_actual"
echo "" # Añade una línea en blanco para separar la información

# Mostrar el contenido del directorio actual
echo "El contenido de este directorio es:"
ls -l