#!/bin/bash

: <<"FIN"
EJERCICIO 5.
Como en el caso anterior, pero las insistencias se limitan a 3.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este ejercicio es igual al 4, pero limita a 3 los intentos tanto para:
# - introducir un usuario válido,
# - confirmar correctamente la contraseña.

# Para no repetir todo lo anterior, pongo trozos de código que se ven afectados:

# Número máximo de intentos permitidos.
INTENTOS=3
#
# Pregunta por el nombre de usuario
pregunta_usuario() {
    local i usuario
    # `seq "$INTENTOS" -1 1` genera una cuenta atrás: 3, 2, 1.
    for i in $(seq "$INTENTOS" -1 1); do
        read -rp "Nombre de usuario ($i intentos): " usuario
        # Si `valida_usuario` tiene éxito, se imprime y se sale con éxito.
        valida_usuario "$usuario" && echo "$usuario" && return 0
        error 0 "Usuario incorrecto"
    done
    # Si se agotan los intentos, la función devuelve error.
    return 1
}
#
# Pregunta por la contraseña
#
pregunta_password() {
    local i pass1 pass2
    for i in $(seq "$INTENTOS" -1 1); do

        # Se pide la contraseña mostrando cuántos intentos quedan.
        read -s -rp "Contraseña ($i intentos): " pass1
        echo >&2
        if ! valida_password "$pass1"; then
            error 0 "La contraseña no cumple con nuestra política de se-
guridad"
            continue
        fi
        # Segunda entrada para confirmación.
        read -s -rp "Repita la contraseña: " pass2
        echo >&2
        [ "$pass1" = "$pass2" ] && echo "$pass1" && return 0
        error 0 "Las contraseñas no coinciden."
    done
    return 1
}

# Si las funciones anteriores fallan, aquí se sale con código 1.
usuario=$(pregunta_usuario) || error 1 "No se puede establecer el nombre de usuario"
password=$(pregunta_password) || error 1 "No se puede establecer la contraseña"

# Si está activado el modo de cifrado, se aplica antes de guardar.
[ -n "$cifrar" ] && password=$(cifrar "$password")

# Se añade la nueva credencial al fichero final.
echo "$usuario:$password" >>"$FICHERO"
