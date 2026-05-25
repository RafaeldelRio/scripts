#!/bin/bash

imprimir_informe() {
    echo "USUARIO: $user"
    echo "******************************************"
    echo "PROCESOS EN EJECUCIÓN USUARIO: $num_procesos"
    echo "PROCESO MÁS ANTIGUO DEL USUARIO: $proceso_antiguo"
    echo "******************************************"
    if [[ -n $lista_procesos ]]; then
        echo "$lista_procesos"
    fi
    echo ""
    echo "******************************************"
    echo "DIRECTORIOS DEL USUARIO: $num_directorios"
    echo "FICHEROS REGULARES DEL USUARIO: $num_ficheros"
    echo "TAMAÑO TOTAL FICHEROS USUARIO: $tamano_bytes B"
    echo "USO DE DISCO DURO USUARIO: $porcentaje"
    echo "******************************************"
    echo ""
}

generar_informe() {
    user=$1

    if ! id "$user" &>/dev/null; then
        return
    fi

    num_procesos=$(ps -U "$user" -u "$user" --no-headers 2>/dev/null | wc -l)

    if (( "$num_procesos" == 0 )); then
        proceso_antiguo="Ninguno"
        lista_procesos=""
    else
        proceso_antiguo=$(ps -U "$user" -u "$user" -o comm= --sort=lstart 2>/dev/null | head -n 1)
        lista_procesos=$(ps -U "$user" -u "$user" -o comm= 2>/dev/null)
    fi

    num_directorios=$(find / -user "$user" -type d 2>/dev/null | wc -l)
    num_ficheros=$(find / -user "$user" -type f 2>/dev/null | wc -l)

    tamano_bytes=$(tamano_bytes_ficheros)

    porcentaje=$(df -B1 / 2>/dev/null | obtener_porcentaje)

    imprimir_informe

}

tamano_bytes_ficheros() {
    lista_de_tamanyos=$(find / -user "$user" -type f -printf "%s\n" 2>/dev/null)

    total=0
    for tamano in lista_de_tamanyos; do
        total=$((total + tamano))
    done

    echo $total
}

obtener_porcentaje() {
    local cabecera
    local sistema total usados libres porcentaje punto_montaje

    read -r cabecera
    read -r sistema total usados libres porcentaje punto_montaje

    echo "$porcentaje"
}

case "$1" in
    -a)
        # Para todos los usuarios
        usuarios_conectados=$(who 2>/dev/null | awk '{print $1}' | sort -u)
        for usuario in $usuarios_conectados; do
            generar_informe "$usuario"
        done
        ;;
    -u)

        # Si no se pone nada: usuario actual. Si se pone algo: para ese usuario
        if [[ -n "$2" ]]; then
            generar_informe "$2"
        else
            generar_informe "$(whoami 2>/dev/null)"
        fi
        ;;
    "")
        # Usuario actual
        generar_informe "$(whoami 2>/dev/null)"
        ;;
    *)

        exit 1
        ;;
esac

exit 0
