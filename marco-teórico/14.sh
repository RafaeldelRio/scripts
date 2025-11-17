#!/bin/bash

a=0

# FORMA ANTIGUA
# while [[ a -lt 10 ]]

# ¡NO TE COMPLIQUES!
while (( a <= 10 ))
do
    echo "Valor: $a"

    # FORMA ANTIGUA
    # let a=a+1

    (( a++ ))
done