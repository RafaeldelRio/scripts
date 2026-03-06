#!/bin/bash

: << "FIN"
EJERCICIO 2.
Basándote en el ejercicio 1. Añada la posibilidad de que la contraseña se cifre o no, me-
diante la inclusión de un argumento en la línea de órdenes. Si se hace:
./2.sh
./2.sh c
La contraseña no estará cifrada.
La contraseña si lo estará.

Si se escribe cualquier otro argumento el programa debe fallar devolviendo un 2 al sistema.
FIN

set -euo pipefail

# Fichero de almacenamiento en el HOME del usuario que ejecuta.
CLAVES_FILE="$HOME/claves"

# Valida argumentos: sin argumento (sin cifrar) o "c" (cifrar).
if [ "$#" -gt 1 ]; then
	exit 2
fi

cifrar=0
if [ "$#" -eq 1 ]; then
	if [ "$1" = "c" ]; then
		cifrar=1
	else
		exit 2
	fi
fi

# Lectura de credenciales por teclado.
read -r -p "Usuario: " usuario
read -r -s -p "Contraseña: " password
echo

# Decide si guardar la contraseña en claro o cifrada.
if [ "$cifrar" -eq 1 ]; then
	salt="$(openssl rand -hex 4)"
	password_stored="$(openssl passwd -1 -salt "$salt" "$password")"
else
	password_stored="$password"
fi

# Añade registro al final del fichero para conservar históricos.
printf '%s:%s\n' "$usuario" "$password_stored" >> "$CLAVES_FILE"
echo "Usuario guardado en $CLAVES_FILE"