#!/bin/bash

: <<"FIN"
Realizar un script llamado tree que mostrará por pantalla el árbol de subdirectorios del directorio
pasado como parámetro. Si además del directorio se le pasa el parámetro -f mostrará también los ficheros,
marcando con un + los directorios y con un - todo lo que no sea directorio. Si se pasa el -f, al final del árbol de
subdirectorios debe informar de cuántos directorios y cuántos ficheros regulares se han mostrado.

FIN

MOSTRAR_FICHEROS=0
DIRECTORIO=""

# 1. Parsear los argumentos (el orden de -f y el directorio da igual)
for arg in "$@"; do
    if [[ "$arg" = "-f" ]]; then
        MOSTRAR_FICHEROS=1
    else
        DIRECTORIO="$arg"
    fi
done

# 2. Comprobaciones iniciales
if [[ -z "$DIRECTORIO" ]]; then
    echo "Error: Falta el parámetro del directorio."
    echo "Uso: $0 [-f] <directorio>"
    exit 1
fi

if [[ ! -d "$DIRECTORIO" ]]; then
    echo "Error: El directorio '$DIRECTORIO' no existe."
    exit 1
fi

# 3. Variables globales para los contadores
TOTAL_DIR=0
TOTAL_FICHEROS=0


# 4. Función recursiva para recorrer y dibujar el árbol
dibujar_arbol() {
    local dir="$1"
    local indentacion="$2"

    # Si no tenemos permisos de lectura y ejecución sobre el directorio, salimos de esta rama
    # Si no tenemos permisos de ejecución no podemos entrar dentro.
    if [[ ! -r "$dir" ]] || [[ ! -x "$dir" ]]; then
        return
    fi

    # Recorremos cada elemento dentro del directorio actual
    for elemento in "$dir"/*; do
        # Si existe, no salta. Si no existe, salta. Esto es para evitar el error de "No such file or directory" cuando el directorio está vacío.
        [[ -e "$elemento" ]] || continue

        local nombre_base
        nombre_base=$(basename "$elemento")

        if [[ -d "$elemento" ]]; then
            # Es un subdirectorio
            if [[ "$MOSTRAR_FICHEROS" -eq 1 ]]; then
                echo "${indentacion}+ $nombre_base"
                ((TOTAL_DIR++))
            else
                echo "${indentacion}|-- $nombre_base"
            fi

            # Llamada recursiva aumentando la sangría (se añaden espacios)
            dibujar_arbol "$elemento" "$indentacion    "
        else
            # No es un directorio (fichero, enlace, etc.)
            if [[ "$MOSTRAR_FICHEROS" -eq 1 ]]; then
                echo "${indentacion}- $nombre_base"
                # Si es un fichero regular, aumentamos su contador
                if [[ -f "$elemento" ]]; then
                    ((TOTAL_FICHEROS++))
                fi
            fi
        fi
    done
}

# 5. Imprimir el nodo raíz (el directorio que pasamos por parámetro)
nombre_raiz=$(basename "$DIRECTORIO")
if [[ "$MOSTRAR_FICHEROS" -eq 1 ]]; then
    echo "+ $nombre_raiz"
    ((TOTAL_DIR++))
else
    echo "$nombre_raiz"
fi

# 6. Iniciar la recursión con la sangría base inicial
dibujar_arbol "$DIRECTORIO" "    "

# 7. Mostrar el recuento final si se ha pasado el parámetro -f
if [[ "$MOSTRAR_FICHEROS" -eq 1 ]]; then
    echo ""
    echo "==================================="
    echo "Directorios mostrados: $TOTAL_DIR"
    echo "Ficheros regulares mostrados: $TOTAL_FICHEROS"
fi
