#!/bin/bash

: << 'FIN'
Línea de mandatos que imprima en orden alfabético aquellas líneas que,
estando entre las 10 primeras del archivo carta, contengan la cadena de
caracteres Juan.
FIN


# head 10 carta: muestra las primeras 10 líneas del archivo
# grep Juan: filtra las líneas que contengan la cadena de caracteres Juan
# sort: ordena las líneas alfabéticamente
# Si ponemos lpr lo mandamos a la impresora
head -n 10 Notas.md | grep Bash | sort