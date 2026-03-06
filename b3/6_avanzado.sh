#!/bin/bash

: << "FIN"
EJERCICIO 6.
Tomando toda la casuística del supuesto anterior, use el fichero “claves” del siguiente modo:
La contraseña siempre se almacenará cifrada (con lo que puede prescindir del análisis del parámetro c).
Si el fichero ya existe, se pide el usuario mostrando el que había almacenado y, si el
usuario lo deja en blanco, se conserva el usuario antiguo.
Si la contraseña se deja en blanco y el usuario no cambió, la contraseña tampoco varía.
Si el usuario cambió, entonces no se conserva la contraseña, aunque se deje en blanco.
Se actualiza el fichero para que almacene exclusivamente el nuevo usuario y contraseña.
FIN

set -euo pipefail

# Ruta del fichero de claves (debe terminar con un único usuario:hash).
CLAVES_FILE="$HOME/claves"
old_user=""
old_hash=""

# Si ya existe información previa, se toma la primera línea como referencia.
if [ -f "$CLAVES_FILE" ] && [ -s "$CLAVES_FILE" ]; then
	IFS=':' read -r old_user old_hash < "$CLAVES_FILE"
fi

# Solicita usuario con hasta 3 intentos; si hay valor anterior permite Enter para conservar.
new_user=""
for _ in 1 2 3; do
	if [ -n "$old_user" ]; then
		read -r -p "Usuario [$old_user]: " new_user
		[ -z "$new_user" ] && new_user="$old_user"
	else
		read -r -p "Usuario: " new_user
	fi

	[ -n "$new_user" ] && break
	echo "El usuario no puede estar vacío." >&2
done

if [ -z "$new_user" ]; then
	echo "Error: máximo de intentos para usuario." >&2
	exit 1
fi

# Caso especial: usuario igual y contraseña en blanco => se conserva hash anterior.
final_hash=""
if [ "$new_user" = "$old_user" ] && [ -n "$old_hash" ]; then
	read -r -s -p "Contraseña (vacía para conservar): " pass1
	echo
	if [ -z "$pass1" ]; then
		final_hash="$old_hash"
	fi
fi

# Si no se conserva la contraseña, pide una nueva (confirmada) y la cifra.
if [ -z "$final_hash" ]; then
	matched=0
	for _ in 1 2 3; do
		read -r -s -p "Contraseña nueva: " pass1
		echo
		read -r -s -p "Repita la contraseña: " pass2
		echo

		if [ -z "$pass1" ]; then
			echo "La contraseña no puede estar vacía en este caso." >&2
			continue
		fi

		if [ "$pass1" = "$pass2" ]; then
			matched=1
			break
		fi
		echo "Las contraseñas no coinciden." >&2
	done

	if [ "$matched" -ne 1 ]; then
		echo "Error: máximo de intentos para contraseña." >&2
		exit 1
	fi

	salt="$(openssl rand -hex 4)"
	final_hash="$(openssl passwd -1 -salt "$salt" "$pass1")"
fi

# Sobrescribe el fichero para dejar exclusivamente el nuevo par usuario:hash.
printf '%s:%s\n' "$new_user" "$final_hash" > "$CLAVES_FILE"
echo "Fichero actualizado en $CLAVES_FILE"