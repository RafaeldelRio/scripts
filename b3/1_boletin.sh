#!/bin/bash

: <<"FIN"
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

FICHERO="$HOME/proyecto/scripts/b3/claves"

# `read -r` lee una línea de entrada y la guarda en la variable `usuario`.
# El `-r` evita que se interpreten caracteres de escape como `\n`.
# `-p` muestra un mensaje antes de leer la entrada.
# `read -s` hace lo mismo pero oculta la entrada, ideal para contraseñas.
read -r -p "Nombre de usuario: " usuario
read -r -s -p "Contraseña: " password

# Para meter una línea en blanco después de la contraseña oculta.
echo

cifrada=$(openssl passwd -1 -salt a "$password")

echo "$usuario:$cifrada" >> $FICHERO
# printf '%s:%s\n' "$usuario" "$cifrada" >> $FICHERO

echo "Usuario guardado en $FICHERO"