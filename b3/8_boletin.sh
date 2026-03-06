#!/bin/bash

: <<"FIN"
EJERCICIO 8.
Definir una función que calcule la clase a la que pertenece una IP determinada.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Determina la clase de una dirección IPv4 en función de su primer octeto:
# - 0..127   -> clase A
# - 128..191 -> clase B
# - 192..223 -> clase C
# - 224..239 -> clase D
# - 240..255 -> clase E

# Determina si una IP es correcta. $1: La IP
es_ip() {
    # En realidad sólo comprobamos si hay
    # cuatro números separados por 3 puntos.
    # `grep -E` usa expresiones regulares extendidas.
    echo "$1" | grep -Eq '^[0-9]+(\.[0-9]){3}$'
}
# Calcula la clase de red.
# Parámetros: $1: La IP.
# Devuelve error si la IP es incorrecta.
netclass() {
    # Si la IP no cumple el patrón, se devuelve error.
    es_ip $1 || return 1

    # `${1%%.*}` elimina desde el primer punto hasta el final.
    # El resultado es el primer octeto.
    local octeto=${1%%.*}

    # Se compara el primer octeto con los rangos clásicos de clases.
    if [ $octeto -lt 128 ]; then
        echo "A"
    elif [ $octeto -lt 192 ]; then
        echo "B"
    elif [ $octeto -lt 224 ]; then
        echo "C"
    elif [ $octeto -lt 240 ]; then
        echo "D"
    else
        echo "E"
    fi
}

# Se calcula la clase usando el primer argumento del script.
clase=$(netclass $1)
res=$?

# Si la función falló, se informa por stderr y se sale con ese mismo código.
if [ $res -ne 0 ]; then
    echo "Imposible obtener la clase de $1" >&2
    exit $res
fi

# Mensaje final legible para el usuario.
echo "La clase de $1 es $clase."
