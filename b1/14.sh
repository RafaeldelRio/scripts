#!/bin/bash

: <<"FIN"
Realizar un shell-script que reciba como argumentos números comprendidos entre 1 y 75. 
Dará error en caso de que algún argumento no esté dentro del rango y terminará sin hacer
nada. 
En caso contrario generará una línea por cada argumento con tantos asteriscos como indique su argumento.
FIN

clear

for num in $*; do
    if (( $num < 1 || $num > 75 )); then
        echo "El numero $num esta fuera de rango"
        exit;
    fi
done

for num in $@; do
    while (( $num > 0 )); do
        echo -n "*"
        ((num--))
    done
    
    echo
done