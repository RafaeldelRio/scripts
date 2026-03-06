#!/bin/bash

: <<"FIN"
EJERCICIO 6.
Tomando toda la casuística del supuesto anterior, use el fichero “claves” del siguiente modo:
La contraseña siempre se almacenará cifrada (con lo que puede prescindir del análisis del parámetro c).
Si el fichero ya existe, se pide el usuario mostrando el que había almacenado y, si el
usuario lo deja en blanco, se conserva el usuario antiguo.
Si la contraseña se deja en blanco y el usuario no cambió, la contraseña tampoco varía.
Si el usuario cambió, entonces no se conserva la contraseña, aunque se deje en blanco.
Se actualiza el fichero para que almacene exclusivamente el nuevo usuario y contraseña.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este ejercicio ya no guarda varias líneas, sino solo una credencial final.
# Además incorpora reutilización de datos anteriores:
# - si existe el fichero `claves`, recupera el usuario y contraseña previos,
# - permite dejar el usuario vacío para conservar el anterior,
# - permite dejar la contraseña vacía para conservar la anterior, pero solo si
#   el usuario no ha cambiado,
# - al final sobrescribe el fichero con `>` para dejar únicamente el nuevo valor.

FICHERO="$HOME/claves"

# Se permiten como máximo 3 intentos para pedir usuario/contraseña.
INTENTOS=3
#
# Imprime un mensaje de error y sale
# $1: Código de salida
# $2: Mensaje de error
#
error() {
    # En este archivo la función está incompleta a propósito / pendiente.
    Igual que la anterior
}
#
# Extrae usuario y contraseña anteriores.
#
extrae_datos() {
    # Si el fichero no existe, devolvemos error para indicar que no hay datos previos.
    [ -f "$1" ] || return 1

    # `cat` devuelve literalmente la línea `usuario:contraseña`.
    cat "$1"
}
#
# Comprueba que el usuario cumpla con la politica de nombres
# $1: La contraseña a validad.
# return: 0 si es válida; 1 si no lo es.
#
valida_usuario() {
    # De nuevo, la política es mínima: solo se exige que no esté vacío.
    [ -n "$1" ]
}
#
# Pregunta por el nombre de usuario
#
pregunta_usuario() {
    local i usuario antiguo="$1"

    # Si hay usuario antiguo, se muestra entre corchetes como valor sugerido.
    [ -n "$antiguo" ] && extra=" [$antiguo]"
    for i in $(seq "$INTENTOS" -1 1); do
        read -rp "Nombre de usuario ($i intentos)$extra: " usuario

        # `${usuario:-$antiguo}` significa: si `usuario` está vacío, usa `antiguo`.
        usuario="${usuario:-$antiguo}"
        valida_usuario "$usuario" && echo "$usuario" && return 0
        error 0 "Usuario incorrecto"
    done
    return 1
}
#
# Comprueba que la contraseña cumple con nuestra política de seguridad
# $1: La contraseña a validad.
# return: 0 si es válida; 1 si no lo es.
#
valida_password() {
    # Como el enunciado no establece ninguna, acepto cualquiera.
    return 0
}
#
# Pregunta por la contraseña.
#
pregunta_password() {
    local i pass1 pass2 antigua="$1"
    for i in $(seq "$INTENTOS" -1 1); do
        read -s -rp "Contraseña ($i intentos): " pass1
        echo >&2

        # Contraseña vacía implica que se conserva la anterior.
        [ -z "$pass1" ] && [ -n "$antigua" ] && echo "$antigua" && re-
        turn 0
        if ! valida_password "$pass1"; then
            error 0 "La contraseña no cumple con nuestra política de se-
guridad"
            continue
        fi
        read -s -rp "Repita la contraseña: " pass2
        echo >&2

        # Si ambas coinciden, se cifra la contraseña y se devuelve.
        [ "$pass1" = "$pass2" ] && cifrar "$pass1" && return 0
        error 0 "Las contraseñas no coinciden."
    done
    return 1
}
#
# Cifra la contraseña
#
cifrar() {
    # Se cifra con el mismo formato usado en ejercicios anteriores.
    openssl passwd -1 -salt a "$1"
}

# `datos` contendrá la línea completa previa, si existía.
datos=$(extrae_datos "$FICHERO")

# `%%:*` elimina desde el primer `:` hasta el final, dejando la parte izquierda.
antiguo="${datos%%:*}"
usuario=$(pregunta_usuario "$antiguo") || error 1 No se puede estable-
cer el usuario

# Si se mantiene el mismo usuario, se conserva la contraseña anterior como candidata.
[ "$usuario" = "$antiguo" ] && antigua="${datos#*:}"
password=$(pregunta_password "$antigua") || error 1 No se puede esta-
blecer la contraseña

# `>` sobrescribe el fichero entero con la nueva credencial única.
echo "$usuario:$password" >"$FICHERO"
