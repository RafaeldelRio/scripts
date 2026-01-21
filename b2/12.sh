#!/bin/bash

# Lista de usuarios que usan un shell específico.
# Extrae del archivo /etc/passwd los nombres de usuarios que usan Bash y guárdalos en un archivo ordenado.

SHELL_PATTERN="/bin/bash"
OUTPUT="usuarios_bash.txt"

# Buscamos el patrón en /etc/passwd, extraemos el primer campo (nombre de usuario) y ordenamos alfabéticamente
# Alternativa awk: awk -F: '/\/bin\/bash$/ {print $1}' /etc/passwd | sort
# Alternativa grep puro: grep "/bin/bash$" /etc/passwd | cut -d: -f1 | sort
grep "$SHELL_PATTERN" /etc/passwd | cut -d: -f1 | sort > "$OUTPUT"
echo "Usuarios con shell $SHELL_PATTERN guardados en $OUTPUT"