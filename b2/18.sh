#!/bin/bash

# Validación de contraseñas.
# Diseña un script que pida una contraseña al usuario y verifique que tenga al menos 8 caracteres.

# Leemos la contraseña sin mostrarla en pantalla (-s)
read -s -p "Introduce una contraseña: " password
echo "" # Nueva línea después de la entrada silenciosa
len=${#password}

# Comprobamos la longitud
# Alternativa POSIX: if [ $(echo -n "$password" | wc -m) -ge 8 ]; then ...
# Alternativa expr: if [ $(expr length "$password") -ge 8 ]; then ...
if [ "$len" -ge 8 ]; then
  echo "La contraseña es válida (tiene $len caracteres)."
else
  echo "La contraseña es insegura (tiene $len caracteres, se requieren al menos 8)."
fi