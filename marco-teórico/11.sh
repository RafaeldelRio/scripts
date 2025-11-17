#!/bin/bash

# ---------------------------- Comparaciones de textos ---------------------------- 
# NO USAR: ES EL COMPARADOR ANTIGUO QUE PUEDE RESULTAR EN PROBLEMAS
if [ "hola" = "hola" ]; then
    echo "ha funcionado 1"
fi

# PERFECTO: FORMA PERFECTA DE COMPARAR TEXTOS
if [[ "hola" == "hola" ]]; then
    echo "ha funcionado 2"
fi

# ---------------------------- Comparaciones de números ---------------------------- 
# SE PUEDE PERO NO USARLO. NO TE COMPLIQUES. PARA NÚMEROS USA EL (( ))
if [[ 1 -eq 1 ]]; then
    echo "ha funcionado 3"
fi

# PERFECTO: FORMA PERFECTA DE COMPARAR NÚMEROS
if (( 1 == 1 )); then
    echo "ha funcionado 4"
fi


# Y ahora, el 11 de verdad
echo "Introduzca un dato"
read DATO

echo "El dato introducido es $DATO"