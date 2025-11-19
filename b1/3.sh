#!/bin/bash

: <<"Fin"
Nos pregunta la edad y que nos conteste:
- Si menor que 10 “eres muy joven”.
- Entre 10 y 30 “que mala edad tienes”.
- Mayor de 30 “que bien te veo”.
Fin

read -p "¿Cuál es tu edad? " edad

# Validar que la entrada sea un número entero
# El patrón '^[0-9]+$' verifica que la entrada consiste solo en uno o más dígitos.
if [[ ! "$edad" =~ ^[0-9]+$ ]]; then
    echo "Error: Por favor, introduce una edad válida (solo números enteros)."
    exit 1
fi


if (( $edad < 10 )); then
    echo "Eres muy joven."

elif (( $edad <= 30 )); then
    echo "Que mala edad tienes."

else
    echo "Que bien te veo."
fi