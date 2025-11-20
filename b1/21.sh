#!/bin/bash

: << 'FIN'
Mandato que imprima un archivo sólo si no es un directorio.
FIN

archivo="Notas.md"

test -d $archivo || cat $archivo
