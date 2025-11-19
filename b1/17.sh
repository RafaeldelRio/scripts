#!/bin/bash

: <<"FIN"
Un script que ordene una lista de palabras entradas por el teclado, 
terminando la lista al pulsar q.
FIN

clear
read -p "Introduce una palabra (q para terminar): " pal

lista=''

if [[ $pal != q ]]; then
    while [[ $pal != q ]]; do
        lista=$lista"$pal:"
        read -p "Introduce otra palabra (q para terminar): " pal
    done

    echo "$lista" | tr ":" "\n" | sort
fi