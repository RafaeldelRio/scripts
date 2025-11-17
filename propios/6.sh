#!/bin/bash
# Un script que cree un nuevo directorio con un nombre proporcionado por el usuario.


# Pedir al usuario el nombre del nuevo directorio
echo "Introduce el nombre del directorio que quieres crear:"

# Leer el nombre del directorio y guardarlo en la variable 'nombre_directorio'
read nombre_directorio

# Crear el directorio utilizando el comando mkdir
mkdir "$nombre_directorio"

# Informar al usuario que el directorio ha sido creado
echo "Se ha creado el directorio '$nombre_directorio'."
