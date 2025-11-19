#!/bin/bash

# Realice un shell-script que admita tres palabras como argumentos y que muestre un
# mensaje informando de las relaciones de igualdad y desigualdad entre esas palabras.

clear

while true; do
    read -p "Escriba 3 palabras separadas por blancos: " pal1 pal2 pal3

    if [[ "$pal1" == "$pal2" ]]; then
    
        if [[ "$pal1" == "$pal3" ]]; then
            echo "Las 3 son iguales"

        else echo "Son iguales la 1 y la 2"
        fi

        else
            if [[ "$pal1" == "$pal3" ]]; then
                echo "Iguales la 1 y la 3"

            else

                if [[ "$pal2" == "$pal3" ]]; then
                    echo "Son iguales la 2 y la 3"

                else echo "Son las 3 distintas!!"
            fi
        fi
    fi
done