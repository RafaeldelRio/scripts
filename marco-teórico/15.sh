#!/bin/bash

a=20

# FORMA ANTIGUA
# until [[ $a -lt 10 ]]


# NO TE COMPLIQUES
until (( $a < 10 ))
do
    echo "Valor $a"
    
    # FORMA ANTIGUA
    # let a=a-1

    (( a-- ))
done