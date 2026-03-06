#!/bin/bash

: <<"FIN"
EJERCICIO 4.
Vuelva a escribir el mismo programa, pero:
1. Se insiste hasta que el nombre de usuario no esté vacío.
2. Se insiste hasta que las dos contraseñas son iguales.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este script reescribe el ejercicio anterior pero insiste indefinidamente:
# - sigue preguntando el usuario hasta que no esté vacío,
# - sigue preguntando la contraseña hasta que las dos entradas coincidan.

# Imprime un mensaje de error y sale
# $1: Código de salida
# $2: Mensaje de error
#
error() {
    # Se toma el primer parámetro como código de salida.
    local EXITCODE=$1
    shift
    if [ "$EXITCODE" -eq 0 ]; then
        echo "¡Atención! $*" >&2
    else
        echo "ERROR. $*" >&2
        exit "$EXITCODE"
    fi
}
# Comprueba que el usuario cumpla con la politica de nombres
# $1: La contraseña a validad.
# return: 0 si es válida; 1 si no lo es.
valida_usuario() {
    # Usuario válido = cadena no vacía.
    [ -n "$1" ]
}
#
# Pregunta por el nombre de usuario
#
pregunta_usuario() {
    local usuario
    while true; do
        # El bucle `while true` repite la pregunta hasta encontrar un valor válido.
        read -rp "Nombre de usuario: " usuario
        valida_usuario "$usuario" && break
        error 0 "Usuario incorrecto"
    done
    echo "$usuario"
}
# Comprueba que la contraseña cumple con nuestra política de seguridad
# $1: La contraseña a validad.
# return: 0 si es válida; 1 si no lo es.
#
valida_password() {
    # Como el enunciado no establece ninguna, acepto cualquiera.
    return 0
}
# Pregunta por la contraseña
#
pregunta_password() {
    local pass1 pass2
    while true; do
        # Primer intento de contraseña.
        read -s -rp "Contraseña: " pass1
        echo >&2
        if ! valida_password "$pass1"; then
            error 0 "La contraseña no cumple con nuestra política de se-
guridad"
            continue
        fi
        # Segunda lectura para confirmar que ambas contraseñas son iguales.
        read -s -rp "Repita la contraseña: " pass2
        echo >&2
        [ "$pass1" = "$pass2" ] && break
        error 0 "Las contraseñas no coinciden."
    done
    echo "$pass1"
}
cifrar() {
    # Se usa `openssl passwd` para obtener el hash de la contraseña.
    openssl passwd -1 -salt a "$1"
}

# De nuevo, el primer argumento es opcional y solo puede ser `c`.
case $1 in
    "") ;;
    c) cifrar="1" ;;
    *)
        echo "$1: Parámetro desconocido" >&2
        exit 2
        ;;
esac

    # Aquí se pide la información al usuario.
usuario=$(pregunta_usuario) # Esta es la diferencia, no lo mandamos al
error: || error…
password=$(pregunta_password)

    # Si el modo cifrado está activo, se cifra la contraseña antes de guardar.
[ -n "$cifrar" ] && password=$(cifrar "$password")

    # Se guarda el resultado en el fichero de credenciales.
echo "$usuario:$password" >>"$FICHERO"
