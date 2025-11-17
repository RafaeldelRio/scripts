#!/bin/bash
for i in $(ls)
do
    echo "Fichero: $i"
done


# Texto comentado
: <<"Fin"
for color in rojo verde azul amarillo
do
    echo "El color actual es: $color"
done


for archivo in *.txt
do
    echo "Copiando $archivo a $archivo.bak..."
    cp "$archivo" "$archivo.bak"
done


for i in {1..5}
do
    echo "Número: $i"
done


for (( i=0; i<=10; i+=2 ))
do
    echo "Número par: $i"
done
Fin