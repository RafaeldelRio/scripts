#!/bin/bash

: <<"FIN"
Diseñar un shell script que permita comprobar las características de un fichero o directorio que se le pasa por parámetro.
Si el último parámetro que se introduce no es un fichero o un directorio válido debe aparecer el mensaje "Fichero o directorio no válido" y
salir del script devolviendo 1.
A continuación debe pedir le nombre de un usuario válido del sistema. Si no se introduce debe terminar el script con el mensaje
"No tiene acceso a este script" y con valor 2 de salida.
A la hora de escribir el nombre de usuario no se debe mostrar en pantalla lo que el usuario está escribiendo. Es decir, se debe escribir como
una contraseña de linux.
Si el nombre de usuario que se introduce es un nombre de usuario válido, el script debe comprobar los parámetros que recibe y en función de ellos
escribir los mensajes oportunos especificado en la tabla que se encuentra a continuación.
Si el último parámetro es un fichero o directorio válido se debe mostrar los mensajes que se indican según las opciones especificadas por el usuario.
Las opciones pueden ser introducidas en cualquier orden. Si se introduce alguna otra opción no contemplada en la tabla debe indicar el parámetro
erróneo y salir del script devolviendo un 3.

Opción y comportamiento
-l o --legible: Se debe indicar el mensaje "es legible" o "no legible" según corresponda
-m o --modificable: Se debe indicar el mensaje "es modificable" o "no modificable" según corresponda
-x o --ejecutable: Se debe indicar el mensaje "es ejecutable" o "no es ejecutable" según corresponda
-h o --help: Muestra un mensaje de ayuda al usuario explicando los posibles parámetros y termina la ejecución sin mostrar ninguna opción de los posibles parámetros.
FIN

mostrar_ayuda() {
    echo "Uso: $0 [opciones] <fichero_o_directorio>"
    echo "Opciones permitidas:"
    echo "  -l, --legible      Indica si es legible"
    echo "  -m, --modificable  Indica si es modificable"
    echo "  -x, --ejecutable   Indica si es ejecutable"
    echo "  -h, --help         Muestra este mensaje de ayuda"
}

# 1. Comprobamos primero si se ha introducido la opción de ayuda (-h o --help)
# Se comprueba antes para evitar el error de "fichero no válido" si solo se pide ayuda
for argumento in "$@"; do
    if [[ "$argumento" == "-h" || "$argumento" == "--help" ]]; then
        mostrar_ayuda
        exit 0
    fi
done

# 2. Si no se ha introducido ningún parámetro, el último parámetro no puede ser válido
# En ese caso se cumple exactamente lo que dice el enunciado:
# mostrar el mensaje de error y salir con código 1.
if [[ "$#" -eq 0 ]]; then
    echo "Fichero o directorio no válido"
    exit 1
fi

# 3. Obtenemos el último parámetro introducido usando la expansión de bash ${!#}
# Ese último parámetro debe ser la ruta sobre la que se harán las comprobaciones.
ruta_objetivo="${!#}"

# 4. Comprobamos si el último parámetro es realmente un fichero o un directorio
# No usamos -e porque el enunciado habla específicamente de fichero o directorio.
if [[ ! -f "$ruta_objetivo" ]] && [[ ! -d "$ruta_objetivo" ]]; then
    echo "Fichero o directorio no válido"
    exit 1
fi

# 5. Solicitamos el nombre de usuario de forma oculta (-s)
# El nombre no se muestra por pantalla, como si fuese una contraseña.
read -r -s -p "Introduzca un nombre de usuario: " usuario
printf '\n'

# 6. Comprobamos si el usuario introducido es válido en el sistema
# Se verifica que no esté vacío y que el comando 'id' lo reconozca (enviando errores a /dev/null)
if [[ -z "$usuario" ]] || ! id "$usuario" >/dev/null 2>&1; then
    echo "No tiene acceso a este script"
    exit 2
fi

# 7. Procesamos las opciones.
# Solo se recorren los parámetros anteriores al último, porque el último es la ruta objetivo.
parametros=("$@")
ultima_posicion=$((${#parametros[@]} - 1))

for (( i=0; i<ultima_posicion; i++ )); do
    opcion_actual="${parametros[i]}"

    case "$opcion_actual" in
        -l|--legible)
            # `-r` comprueba si la ruta es legible para el usuario que ejecuta el script.
            if [[ -r "$ruta_objetivo" ]]; then
                echo "es legible"
            else
                echo "no legible"
            fi
            ;;
        -m|--modificable)
            # `-w` comprueba si la ruta es modificable.
            if [[ -w "$ruta_objetivo" ]]; then
                echo "es modificable"
            else
                echo "no modificable"
            fi
            ;;
        -x|--ejecutable)
            # `-x` comprueba si la ruta es ejecutable.
            if [[ -x "$ruta_objetivo" ]]; then
                echo "es ejecutable"
            else
                echo "no ejecutable"
            fi
            ;;
        *)
            # Si se encuentra una opción no contemplada en la tabla,
            # se informa de cuál es y se termina con código 3.
            echo "Parámetro erróneo: $opcion_actual"
            exit 3
            ;;
    esac
done
