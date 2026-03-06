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

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# 1) Pide por teclado un nombre de usuario.
# 2) Pide por teclado una contraseña sin mostrarla en pantalla.
# 3) Cifra la contraseña usando `openssl passwd`.
# 4) Guarda una línea con formato usuario:contraseña_cifrada dentro del fichero
#    `claves` situado en el directorio personal del usuario que ejecuta el script.
# 5) Usa `>>` para AÑADIR la nueva línea al final del fichero, sin borrar las
#    que ya existieran de ejecuciones anteriores.

# La siguiente línea hace que el script falle si se produce un error, si se usa una variable no definida o si una tubería falla.
# Se usa para depurar y evitar comportamientos inesperados.
# -e hace que el script termine si cualquier comando devuelve un error (salida distinta de 0).
# -u hace que el script termine si se intenta usar una variable no definida.
# -o pipefail hace que el script termine si cualquier comando en una tubería falla, no solo el último.

# Nombre del fichero donde se van a guardar las credenciales.
# Ojo: aquí solo guardamos el nombre, no la ruta completa.
# La ruta completa se forma más abajo con `~/$FICHERO`.
FICHERO="claves"

# `read -p` muestra un mensaje y guarda lo escrito en la variable `usuario`.
# No valida todavía si el usuario está vacío o no.
read -p "Nombre de usuario: " usuario

# `read -s -p` hace lo mismo, pero `-s` evita que la contraseña se vea
# mientras se teclea.
read -s -p "Contraseña: " password

# `echo` sin texto se usa aquí para bajar a la línea siguiente después de
# introducir la contraseña oculta.

# La expansión `$(...)` ejecuta un comando y sustituye su salida.
# `openssl passwd -1 -salt a "$password"` genera una contraseña cifrada.
# `>>` añade el resultado al final del fichero sin sobrescribirlo.
# `~/$FICHERO` apunta al fichero `claves` dentro del HOME del usuario actual.
echo "$usuario:$(openssl passwd -1 -salt a "$password")" >>~/$FICHERO
