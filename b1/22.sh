#!/bin/bash

# Mandato que imprima un archivo sólo si se trata de un archivo ordinario.

archivo="Notas.md"
test -f $archivo && cat $archivo