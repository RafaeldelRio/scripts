#!/bin/bash

# Un script que salude al usuario y le muestre la fecha y hora actual.
# El script debe mostrar la fecha y hora en el formato dd/mm/yyyy hh:mm:ss


# Pedir al usuario que introduzca su nombre
read -p "Por favor, introduce tu nombre: " nombre

# Obtener la fecha y la hora actuales y guardarlas en la variable 'fecha_actual'
fecha_actual=$(date +"%d/%m/%Y %H:%M:%S")

# Mostrar el saludo personalizado y la fecha
echo "¡Hola, $nombre!"
echo "La fecha y hora actuales son: $fecha_actual"  