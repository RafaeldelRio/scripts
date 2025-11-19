#!/bin/bash

: <<"FIN"
Realice un shell-script 'pirámide' que admita como argumento un número 'N' y que ob-
tenga a la salida una serie de 'N' filas de forma triangular.
Para ./pirámide 12 la salida sería:
01
02 02
03 03 03
04 04 04 04
05 05 05 05 05
06 06 06 06 06 06
07 07 07 07 07 07 07
08 08 08 08 08 08 08 08
09 09 09 09 09 09 09 09 09
10 10 10 10 10 10 10 10 10 10
11 11 11 11 11 11 11 11 11 11 11
12 12 12 12 12 12 12 12 12 12 12 12
FIN

# Comprobar que se ha proporcionado un argumento
if [[ $# -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    echo "Error: Debes proporcionar un número como argumento"
    echo "Uso: $0 <número>"
    exit 1
fi

posicion=0

until (( $posicion == $1 )) ; do
    ((posicion++))
    veces=0

    while (( $veces < $posicion )); do
        if (( $posicion < 10 )) ; then
            echo -n "0$posicion "
        else
            echo -n "$posicion "
        fi

        ((veces++))
    done
    echo
done