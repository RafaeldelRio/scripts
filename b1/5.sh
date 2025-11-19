#!/bin/bash

# Introducir dos números por teclado y realizar: suma, resto, multiplicación, división y resto
# de ambos números. Después indicar el resultado de cada operación.

#!/bin/bash
clear
read -p "Introduzca 2 numeros: " num1 num2

if [[ -n "$num1" ]] && [[ -n "$num2" ]]; then
    # Operador aritmético, forma 1
    # $ Saca el resultado de la operación y lo vuelca en suma
    suma=$(( num1 + num2 ))

    resta=$(( num1 - num2 ))

    multiplicacion=$(( num1 * num2))

    division=$(( num1 / num2 ))
    resto=$(( num1 % num2 ))

    echo " Los resultados son"
    echo " Suma = $suma Resta = $resta Mult=$multiplicacion Division=$division y resto=$resto"

else
    echo "El numero de parametros debe ser 2"
fi