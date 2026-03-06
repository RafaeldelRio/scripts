#!/bin/bash

: << "FIN"
EJERCICIO 1.
Pida un usuario y una contraseña por pantalla, donde NOMBRE_USUARIO y CONTRASEÑA es lo tecleado. 
Guarde ambos datos dentro del fichero “claves” en el formato:
    NOMBRE_USUARIO:CONTRASEÑA
Hágalo de forma que, si se vuelve a ejecutar el script, no se borren los usuarios ya almacenados. 
En cuanto al directorio en que debe alojarse el fichero “claves”, suponga que quiere almacenarlo en el 
directorio personal del usuario.
En cuanto a la contraseña, no debe almacenarse en claro sino codificada tal y como
aparece en el fichero /etc/shadow y por supuesto no debe de visualizarse mientras se escribe.
Nota: Para codificar la contraseña puede usar openssl: openssl passwd -1 -salt a contraseña
FIN

# La siguiente línea hace que el script falle si se produce un error, si se usa una variable no definida o si una tubería falla.
# Se usa para depurar y evitar comportamientos inesperados.
# -e hace que el script termine si cualquier comando devuelve un error (salida distinta de 0).
# -u hace que el script termine si se intenta usar una variable no definida.
# -o pipefail hace que el script termine si cualquier comando en una tubería falla, no solo el último.
set -euo pipefail

# Fichero de destino en el directorio personal del usuario.
CLAVES_FILE="$HOME/proyecto/scripts/b3/claves"

# Solicita usuario y contraseña (la contraseña no se muestra por pantalla).
read -r -p "Usuario: " usuario
read -r -s -p "Contraseña: " password
echo

# Cifra la contraseña en formato compatible con /etc/shadow (MD5-crypt).
salt="$(openssl rand -hex 4)"
password_hash="$(openssl passwd -1 -salt "$salt" "$password")"

# Añade el par usuario:hash sin sobrescribir entradas anteriores.
printf '%s:%s\n' "$usuario" "$password_hash" >> "$CLAVES_FILE"
echo "Usuario guardado en $CLAVES_FILE"