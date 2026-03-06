#!/bin/bash

: << "FIN"
EJERCICIO 4.
Vuelva a escribir el mismo programa, pero:
1. Se insiste hasta que el nombre de usuario no esté vacío.
2. Se insiste hasta que las dos contraseñas son iguales.
FIN

set -euo pipefail

# Fichero de almacenamiento de credenciales.
CLAVES_FILE="$HOME/claves"

# Acepta 0 argumentos (sin cifrar) o "c" (cifrar).
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

# Reintenta hasta obtener usuario no vacío.
while :; do
	read -r -p "Usuario: " usuario
	[ -n "$usuario" ] && break
	echo "El usuario no puede estar vacío." >&2
done

# Reintenta hasta que ambas contraseñas coincidan.
while :; do
	read -r -s -p "Contraseña: " password1
	echo
	read -r -s -p "Repita la contraseña: " password2
	echo
	[ "$password1" = "$password2" ] && break
	echo "Las contraseñas no coinciden." >&2
done

# Cifrado opcional según argumento.
if [ "$cifrar" -eq 1 ]; then
	salt="$(openssl rand -hex 4)"
	password_stored="$(openssl passwd -1 -salt "$salt" "$password1")"
else
	password_stored="$password1"
fi

# Guarda el registro sin borrar los anteriores.
printf '%s:%s\n' "$usuario" "$password_stored" >> "$CLAVES_FILE"
echo "Usuario guardado en $CLAVES_FILE"