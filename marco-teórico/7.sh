#!/bin/bash

#if [ "hola" = "hola" ]; then
# Usa el comparador moderno, empleando para ello el [[ ]]
if [[ "hola" == "hola" ]] ; then
    echo "Esto se verá si entra por el if"
fi

echo "Esto se verá siempre"



# if [ 1 = 2 ]; then
# Con números, el comparador moderno es (( ))
if (( 1 == 2 )); then
    echo "Esto no se verá"

else
    echo "Esto sí se verá (es el else)"
fi