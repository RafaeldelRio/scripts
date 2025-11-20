#!/bin/bash

: << 'FIN'
Mandato que imprima los usuarios que están utilizando
el sistema en orden alfabético.
FIN

# who muestra información sobre los usuarios que están utilizando el sistema
# cut -d " " -f 1 extrae la primera columna (el nombre de usuario)
# sort ordena los nombres alfabéticamente
# uniq elimina duplicados
who | cut -d " " -f 1 | sort | uniq