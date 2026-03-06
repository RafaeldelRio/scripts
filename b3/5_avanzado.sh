#!/bin/bash

: << "FIN"
EJERCICIO 5.
Como en el caso anterior, pero las insistencias se limitan a 3.
FIN

set -euo pipefail

# Fichero de almacenamiento de usuarios/contraseñas.
CLAVES_FILE="$HOME/claves"

# Acepta 0 argumentos o "c" para cifrar.
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

# Usuario: máximo 3 intentos para no dejarlo vacío.
usuario=""
for _ in 1 2 3; do
	read -r -p "Usuario: " usuario
	[ -n "$usuario" ] && break
	echo "El usuario no puede estar vacío." >&2
done

if [ -z "$usuario" ]; then
	echo "Error: máximo de intentos para usuario." >&2
	exit 1
fi

# Contraseña: máximo 3 intentos para que coincida la confirmación.
password1=""
password2="x"
for _ in 1 2 3; do
	read -r -s -p "Contraseña: " password1
	echo
	read -r -s -p "Repita la contraseña: " password2
	echo
	[ "$password1" = "$password2" ] && break
	echo "Las contraseñas no coinciden." >&2
done

if [ "$password1" != "$password2" ]; then
	echo "Error: máximo de intentos para contraseña." >&2
	exit 1
fi

# Cifrado opcional según argumento recibido.
if [ "$cifrar" -eq 1 ]; then
	salt="$(openssl rand -hex 4)"
	password_stored="$(openssl passwd -1 -salt "$salt" "$password1")"
else
	password_stored="$password1"
fi

# Añade nueva línea al fichero de claves.
printf '%s:%s\n' "$usuario" "$password_stored" >> "$CLAVES_FILE"
echo "Usuario guardado en $CLAVES_FILE"