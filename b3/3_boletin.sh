#!/bin/bash

: <<"FIN"
EJERCICIO 3.
Mejore el script anterior para que se compruebe si no se escribe nada al pedir el usuario; 
y se pregunte una segunda vez la contraseña y se compruebe que en ambos casos es la misma. 
Si no se cumple esto, el programa debe acabar con un 1.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este ejercicio añade validaciones al anterior:
# - comprueba el nombre de usuario,
# - pide dos veces la contraseña,
# - verifica que ambas coincidan,
# - mantiene el parámetro opcional `c` para cifrar.

# Ruta completa del fichero de credenciales.
# Aquí ya se usa `$HOME`, que es más explícito que `~` dentro de cadenas.
FICHERO="$HOME/claves"
#
# Imprime un mensaje de error y sale
# $1: Código de salida
# $2: Mensaje de error
#
error() {
    # `local` crea variables solo visibles dentro de la función.
    local EXITCODE=$1
    shift
    # `shift` elimina el primer argumento (`EXITCODE`) y deja el resto como mensaje.
    if [ "$EXITCODE" -eq 0 ]; then
        echo "¡Atención! $*" >&2
    else
        echo "ERROR. $*" >&2
        exit "$EXITCODE"
    fi
}
#
# Comprueba que el usuario cumpla con la politica de nombres
# $1: La contraseña a validar.
# return: 0 si es válida; 1 si no lo es.
#
valida_usuario() {
    # `[ -n ... ]` devuelve éxito si la cadena no está vacía.
    [ -n "$1" ]
}
#
# Pregunta por el nombre de usuario
#
pregunta_usuario() {
    local usuario
    while true; do
        # `-r` evita interpretar barras invertidas.
        read -rp "Nombre de usuario: " usuario
        valida_usuario "$usuario" && break
        error 0 "Usuario incorrecto"
    done
    echo "$usuario"
}
#
# Comprueba que la contraseña cumple con nuestra política de seguridad
# $1: La contraseña a validad.
# return: 0 si es válida; 1 si no lo es.
#
valida_password() {
    # Como el enunciado no establece ninguna, acepto cualquiera.
    # `return 0` significa "todo correcto".
    return 0
}
#
# Pregunta por la contraseña
pregunta_password() {
    local pass1 pass2
    while true; do
        # Se piden dos veces para comprobar que no hubo errores al teclear.
        read -s -rp "Contraseña: " pass1
        echo >&2
        if ! valida_password "$pass1"; then
            error 0 "La contraseña no cumple con la política seguridad"
            continue
        fi
        read -s -rp "Repita la contraseña: " pass2
        echo >&2
        [ "$pass1" = "$pass2" ] && break
        error 0 "Las contraseñas no coinciden."
    done
    echo "$pass1"
}

# Esta parte vuelve a analizar el posible argumento `c`.
case $1 in
    "") ;;
    c) cifrar="1" ;;
    *)
        echo "$1: Parámetro desconocido" >&2
        exit 2
        ;;
esac

    # `$(...)` captura la salida devuelta por cada función.
usuario=$(pregunta_usuario) || error 1 "Usuario incorrecto"
password=$(pregunta_password) || error 1 "Las contraseñas no coinci-
den"

    # Si se activó el modo cifrado, se reemplaza la contraseña por su hash.
[ -n "$cifrar" ] && password=$(openssl passwd -1 -salt a "$password")

    # Se añade el nuevo usuario al fichero, sin borrar los ya existentes.
echo "$usuario:$password" >>"$FICHERO"
