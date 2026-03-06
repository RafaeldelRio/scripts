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

# Función que comprueba si introducimos un dato y si ese dato se parece a una IP (4 números separados por puntos).
comprobar_entrada() {
    local octeto

    if [[ "$#" -ne 1 ]]; then
        echo "Uso: $0 IP" >&2
        exit 1
    # `=~` comprueba si `$1` encaja con la expresión regular.
    # `!` niega el resultado: entra aquí cuando NO tiene formato IPv4.
    # `^` y `$` obligan a que toda la cadena cumpla el patrón completo.
    # `([0-9]{1,3}\.){3}` exige 3 grupos de 1 a 3 dígitos seguidos de punto.
    # `[0-9]{1,3}` final exige el cuarto octeto, sin punto al final.
    elif [[ ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "IP no válida" >&2
        exit 1
    fi

    # Recuerda "<" para archivos, "<<" para cadenas. "<<<" para cadenas.
    IFS='.' read -r -a octetos <<< "$1"
    # Recorre el array `octetos` elemento a elemento.
    # En cada vuelta, `octeto` toma uno de los 4 valores de la IP.
    for octeto in "${octetos[@]}"; do
        if (( octeto < 0 || octeto > 255 )); then
            echo "IP no válida" >&2
            exit 1
        fi
    done

    return 0
}

# Función que calcula la clase de una IP dada. Se asume que la IP es válida.
calcula_clase_ip() {
    # `local` hace que `octeto` solo exista dentro de esta función.
    # `${1%%.*}` elimina desde el primer punto hasta el final.
    # Así se obtiene el primer octeto de la IP.
    # Ejemplo: si `$1` es `192.168.1.1`, el resultado es `192`.
    local octeto=${1%%.*}

    if (($octeto < 128 )); then
        echo "A"
    elif (( $octeto < 192)) ; then
        echo "B"
    elif (( $octeto < 224 )); then
        echo "C"
    elif (( $octeto < 240 )); then
        echo "D"
    else
        echo "E"
    fi
}

comprobar_entrada "$@"
calcula_clase_ip "$1"