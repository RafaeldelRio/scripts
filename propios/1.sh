#!/bin/bash

# Crea una función que reciba un número 
# y muestre todos los números pares desde el 1 hasta ese número

function pares() {
    for (( i=1; i<=$1; i++ )); do
        if (( i % 2 == 0 )); then
            printf "%d\n" "$i"
        fi
    done
}

# Crea un main que se ejecute y pida un número
# y muestre todos los números pares desde el 1 hasta ese número

function main() {
    read -p "Ingrese un número: " num
    pares $num
}

main
