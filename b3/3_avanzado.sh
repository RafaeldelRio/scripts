#!/bin/bash

: << "FIN"
EJERCICIO 3.
Mejore el script anterior para que se compruebe si no se escribe nada al pedir el usuario; 
y se pregunte una segunda vez la contraseña y se compruebe que en ambos casos es la misma. 
Si no se cumple esto, el programa debe acabar con un 1.
FIN

set -euo pipefail

# Fichero de almacenamiento en HOME.
CLAVES_FILE="$HOME/claves"

# Acepta los mismos argumentos que el ejercicio 2.
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

# Valida que el usuario no esté vacío.
read -r -p "Usuario: " usuario
if [ -z "$usuario" ]; then
	echo "Error: usuario vacío" >&2
	exit 1
fi

# Pide contraseña dos veces y verifica coincidencia.
read -r -s -p "Contraseña: " password1
echo
read -r -s -p "Repita la contraseña: " password2
echo

if [ "$password1" != "$password2" ]; then
	echo "Error: las contraseñas no coinciden" >&2
	exit 1
fi

# Cifra solo si se ha indicado con el argumento "c".
if [ "$cifrar" -eq 1 ]; then
	salt="$(openssl rand -hex 4)"
	password_stored="$(openssl passwd -1 -salt "$salt" "$password1")"
else
	password_stored="$password1"
fi

# Añade la nueva línea al fichero de claves.
printf '%s:%s\n' "$usuario" "$password_stored" >> "$CLAVES_FILE"
echo "Usuario guardado en $CLAVES_FILE"