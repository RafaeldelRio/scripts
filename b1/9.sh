#!/bin/bash

# Realiza un script que escriba al revés una palabra.
clear

read -p "Introduce una palabra: " palabra

# Obtenemos la longitud de la cadena
longitud=${#palabra}

# Variable donde iremos guardando el resultado
invertida=""

# Bucle inverso
# Empezamos en el último carácter (longitud - 1)
# Vamos bajando hasta llegar a 0
# i-- significa restar 1 en cada vuelta
for (( i=$longitud-1; i>=0; i-- )); do
    
    # ${palabra:i:1} extrae 1 carácter en la posición i
    letra="${palabra:i:1}"
    
    # Concatenamos la letra a nuestra variable acumuladora
    invertida="$invertida$letra"
done

echo "La palabra al revés es: $invertida"