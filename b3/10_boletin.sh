#!/bin/bash

: <<"FIN"
EJERCICIO 10.
Modifique el ejercicio anterior para que:
- Cuando no se incluye la máscara, se sobreentienda que es la predeterminada.
- La función, además, de admitir un único argumento (IP en notación CIDR), admita dos que representen
 respectivamente la dirección y la máscara (en forma de dirección IP):
netaddr 192.168.25.4 255.255.254.0
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este archivo amplía la idea del ejercicio 9:
# - acepta IP/MÁSCARA en formato CIDR,
# - acepta IP y máscara en formato decimal punteado,
# - si no se pasa máscara, intenta deducir la predeterminada según la clase.
# Internamente hace conversiones entre decimal y binario para calcular la red.

# Obtiene la dirección de red a partir de una IP en notación CIDR:
#
10.11.12.13/24 --- >10.11.12.0/24
# $1: La IP.
#
netaddr() {
    local IP MASK
    local octeto # Cada byte de la dirección IP
    local bits

    # Almacena la IP como 32 bits.
    es_entero() {
        # Valida cadenas formadas únicamente por dígitos.
        echo "$1" | grep -Eq '^[0-9]+$'
    }
    #
    # Junta los elementos que se le proporcionan con una cadena.
    # $1: La cadena que sirve de pegamento.
    # $@: El resto de argumentos.
    #
    join() {
        # Une varios fragmentos usando el separador recibido como primer argumento.
        local IFS="$1"
        shift
        printf "$*"
    }
    {
        Pág. 13
        # Evitamos usar la calculadora (bc, dc, etc.)
        d2b() { # Conversión decimal -> binario
            # Igual que en el ejercicio 9, convierte decimal a binario de 8 bits.
            local r num="$1"
            while [ "$num" -gt 0 ]; do
                r="$((num % 2))$r"
                num=$((num >> 1))
            done
            printf "%08d" "$r"
        }
        b2d() { # Conversión binario -> decimal
            # Hace la operación inversa: de binario a decimal.
            set -- $(echo "$1" | fold -b1)
            local r=0
            while [ $# -gt 0 ]; do
                r=$((r * 2 + $1))
                shift
            done
            echo "$r"
        }
    }
    # Convierte una IPv4 en 32 bits.
    ipd2b() {
        local IFS="."
        for octeto in $1; do
            # Cada octeto debe ser numérico y estar entre 0 y 255.
            es_entero "$octeto" || return 1
            [ "$octeto" -lt 0 -o "$octeto" -gt 255 ] && return 1
            d2b "$octeto"
        done
    }
    # Convierte 32 bits en una IPv4.
    ipb2d() {
        # `fold -b8` corta la cadena binaria en bloques de 8 bits.
        # Luego cada bloque se transforma a decimal y se unen con puntos.
        join . $(echo "$1" | fold -b8 | while read -r octeto; do
            b2d
            "$octeto"
        done)
    }
    if [ $# -eq 1 ]; then # Formato: 192.168.12.23/24
        IP="${1%/*}"
        MASK="${1#*/}"

        # Cálculo de la máscara
        if es_entero "$MASK"; then
            [ $MASK -lt 2 -o $MASK -gt 32 ] && return 1
        elif [ "$MASK" = "$IP" ]; then # Hay que averiguar la máscara
            predeterminada
            octeto=${IP%%.*}

            # Aquí se aplica la máscara por defecto según la clase clásica.
            if [ "$octeto" -lt 128 ]; then
                MASK=8
            elif [ "$octeto" -lt 192 ]; then
                MASK=16
            elif [ "$octeto" -lt 224 ]; then
                MASK=24
            else
                return 1
            fi
        else
            return 1
        fi
    else
        # Formato: 192.168.12.23 255.255.255.0
        IP="$1"
        MASK=$(ipd2b "$2") || return 1

        MASK=${MASK%%0*} # Eliminamos los ceros finales.

        # Si después de eliminar los ceros aparecen cosas distintas de `1`, la
        # máscara no es continua y por tanto no es válida como máscara de red.
        echo "$MASK" | grep -Eq '^1+$' || return 1
        MASK=$(printf "$MASK" | wc -c)
    fi

    # Convertimos la IP a binario y forzamos a cero la parte de host.
    bits=$(ipd2b "$IP") || return 1
    # Sustituimos la parte de host por ceros.
    bits=$(
        printf "%.${MASK}s" "$bits"
        printf "0%.s" $(seq $MASK 31)
    )

    # Se imprime la IP de red seguida de su prefijo CIDR.
    ipb2d "$bits"
    echo "/$MASK"
}

# La última línea permite usar la función directamente como script ejecutable.
netaddr "$@"
