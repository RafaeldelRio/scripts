#!/bin/bash

# 1. Capturar el primer argumento (el nombre)
# La variable $1 contiene el primer argumento pasado al script.
NOMBRE=$1

# 2. Comprobar si se proporcionó un argumento
# La variable $# contiene el número total de argumentos pasados.
if [ $# -eq 0 ]; then
    echo "⛔ Error: Debes proporcionar un nombre como argumento."
    echo "Uso: ./saludo_argumento.sh [NOMBRE]"
    exit 1
fi

# 3. Mostrar el saludo
echo "¡Hola, **$NOMBRE**! ¡Bienvenido/a al mundo de los scripts de Bash!"