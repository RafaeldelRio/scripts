#!/bin/bash

: << "FIN"
EJERCICIO 5.
Como en el caso anterior, pero las insistencias se limitan a 3.
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
    intentos=0
    while [[ -z "$usuario" ]] && (( intentos < 3 )); do
        read -r -p "Nombre de usuario: " usuario
        if [[ -z "$usuario" ]]; then
            echo "El nombre de usuario no puede estar vacío. Intento: $((intentos + 1)) de 3."
            (( intentos++ ))
        fi
    done

    while [[ -z "$password" || -z "$password2" ]] && (( intentos < 3 )); do
        read -r -s -p "Contraseña: " password
        echo
        read -r -s -p "Repita la contraseña: " password2
        echo
        
        if [[ -z "$password" || -z "$password2" ]]; then
            echo "La contraseña no puede estar vacía. Intento: $((intentos + 1)) de 3."
            (( intentos++ ))
        elif [[ "$password" != "$password2" ]]; then
            echo "Las contraseñas no coinciden. Intento: $((intentos + 1)) de 3."
            password=""
            password2=""
            (( intentos++ ))
        fi
    done
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



