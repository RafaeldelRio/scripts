#!/bin/bash

MOSTRAR_FICHEROS=0
DIRECTORIO=""
TOTAL_DIR=0
TOTAL_FICH=0

for arg in "$@"; do
    if [[ "$arg" = "-f" ]]; then
        MOSTRAR_FICHEROS=1
    else
        DIRECTORIO="$arg"
    fi
done

if [[ -z "$DIRECTORIO" ]]; then
    echo "Error: falta directorio"
    exit 1
fi

if [[ ! -d "$DIRECTORIO" ]]; then
    echo "Error: '$DIRECTORIO' no existe."
    exit 1
fi

dibujar_arbol(){
    dir="$1"
    indentacion="$2"

    if [[ ! -r "$dir" ]] || [[ ! -x "$dir" ]]; then
        return
    fi

    for elemento in "$dir"/*; do
        [[ -e "$elemento" ]] || continue

        nombre_base=$(basename "$elemento")

        if [[ -d "$elemento" ]]; then
            if (( "$MOSTRAR_FICHEROS" == 1 )); then
                echo "${indentacion}+ $nombre_base"
                ((TOTAL_DIR++))
            else
                echo "${indentacion} $nombre_base"
            fi

            dibujar_arbol "$elemento" "$indentacion "
        else
            if (( "$MOSTRAR_FICHEROS" == 1 )); then
                echo "${indentacion}- $nombre_base"
                ((TOTAL_FICH++))
            fi
        fi

    done
}

nombre_raiz=$(basename "$DIRECTORIO")
if (( "$MOSTRAR_FICHEROS" == 1 )); then
    echo "+ $nombre_raiz"
    ((TOTAL_DIR++))
else
    echo "$nombre_raiz"
fi

dibujar_arbol "$DIRECTORIO" " "

# Recuento final
if (( "$MOSTRAR_FICHEROS" == 1 )); then
    echo "Total directorios: $TOTAL_DIR"
    echo "Total ficheros regulares: $TOTAL_FICH"
fi

exit 0
