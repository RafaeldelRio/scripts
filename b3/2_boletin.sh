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

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este script amplía el ejercicio 1:
# - Si se ejecuta sin argumentos, guarda la contraseña tal cual se escribió.
# - Si se ejecuta con argumento `c`, cifra la contraseña antes de guardarla.
# - Si se usa cualquier otro argumento, termina con error 2.

# Nombre del fichero donde se almacenarán las credenciales.
FICHERO="claves"

# Esta función encapsula el cifrado.
# Se define como función para no repetir el comando `openssl` varias veces.
# `$1` representa el primer argumento recibido por la función.
cifrar() {
    openssl passwd -1 -salt a "$1"
}

# Aquí se vuelve a asignar la misma variable. No es necesario, pero no rompe nada.
FICHERO="claves"

# `case` permite analizar el valor de `$1`, es decir, el primer parámetro del script.
# - `""` significa que no se pasó ningún parámetro.
# - `c` activa el modo cifrado.
# - `*` captura cualquier otro valor y provoca salida con error.
case $1 in
    "") ;;
    c) cifrar="1" ;;
    *)
        # `>&2` envía el mensaje de error a la salida de error estándar.
        echo "$1: Parámetro desconocido" >&2
        exit 2
        ;;
esac

# Pedimos usuario y contraseña por teclado.
read -p "Nombre de usuario: " usuario
read -s -p "Contraseña: " password

# Este `echo` solo añade un salto de línea después de la contraseña oculta.
echo

# Si la variable `cifrar` no está vacía, se reemplaza el contenido de `password`
# por su versión cifrada.
[ -n "$cifrar" ] && password=$(cifrar "$password")

# Finalmente se añade una línea con formato usuario:password al fichero.
echo "$usuario:$password" >>~/$FICHERO
