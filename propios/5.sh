#!/bin/bash

# Un script que salude al usuario y le muestre la fecha y hora actual.

# Pedir al usuario que introduzca su nombre
echo "Por favor, introduce tu nombre:"

# Leer el nombre introducido por el usuario y guardarlo en la variable 'nombre'
read nombre

# Obtener la fecha y la hora actuales y guardarlas en la variable 'fecha_actual'
fecha_actual=$(date)

# Mostrar el saludo personalizado y la fecha
echo "¡Hola, $nombre!"
echo "La fecha y hora actuales son: $fecha_actual"