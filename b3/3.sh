#!/bin/bash

: << "FIN"
EJERCICIO 3.
Mejore el script anterior para que se compruebe si no se escribe nada al pedir el usuario; 
y se pregunte una segunda vez la contraseña y se compruebe que en ambos casos es la misma. 
Si no se cumple esto, el programa debe acabar con un 1.
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

obtener_datos_y_validar() {
    read -r -p "Nombre de usuario: " usuario
    if [[ -z "$usuario" ]]; then
        echo "El nombre de usuario no puede estar vacío."
        exit 1
    fi

    read -r -s -p "Contraseña: " password
    echo
    read -r -s -p "Repita la contraseña: " password2
    echo

    if [[ -z "$password" || -z "$password2" ]]; then
        echo "La contraseña no puede estar vacía."
        exit 1
    elif [[ "$password" != "$password2" ]]; then
        echo "Las contraseñas no coinciden."
        exit 1
    fi
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
obtener_datos_y_validar
cifrar_o_no "$@"
almacenar_datos



