#!/bin/bash

: <<"FIN"
EJERCICIO 2.
Basándote en el ejercicio 1. Añada la posibilidad de que la contraseña se cifre o no, me-
diante la inclusión de un argumento en la línea de órdenes. Si se hace:
./2.sh
./2.sh c
La contraseña no estará cifrada.
La contraseña si lo estará.

Si se escribe cualquier otro argumento el programa debe fallar devolviendo un 2 al sistema.
FIN


FICHERO="$HOME/proyecto/scripts/b3/claves"

# Función validar argumentos. Solo se permiten 0 o 1 argumento, y si hay un argumento, debe ser "c".
validar_argumentos() {
    if (( "$#" > 1 )); then
        echo "Uso: $0 [c]" >&2
        exit 2
    fi

    if (( "$#" == 1 )) && [[ "$1" != "c" ]]; then
        echo "Uso: $0 [c]" >&2
        exit 2
    fi
}

obtener_datos() {
    read -r -p "Nombre de usuario: " usuario
    read -r -s -p "Contraseña: " password
    echo
}


# Función para cifrar la contraseña.
cifrar_o_no() {
    if (( "$#" == 1 )) && [[ "$1" == "c" ]]; then
        password_stored=$(openssl passwd -1 -salt a "$password")
    else
        password_stored="$password"
    fi
}

almacenar_datos() {
    printf '%s:%s\n' "$usuario" "$password_stored" >> $FICHERO
    echo "Usuario guardado en $FICHERO"
}


validar_argumentos "$@"
obtener_datos
cifrar_o_no "$@"
almacenar_datos



