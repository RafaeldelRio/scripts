#!/bin/bash

: <<"FIN"
Realizar un shell script llamado informe.sh que genere un informe del estado del sistema.
Admitirá los siguientes parámetros:
-u usuario: define el usuario para el que se va a mostrar el informe, en caso de
    no ponerlos, realizará el informe con el usuario actual.
-a deberá generar un informe de todos los usuarios conectados al sistema en el momento
    de ejecutarlo.

El informe consistirá en: nombre del usuario, número de procesos en ejecución del usuario,
proceso más antiguo del usuario, listado de los procesos del usuario, número de directorios
del usuario en el sistema, número de ficheros regulares del usuario en el sistema, tamaño
ocupado en disco por el usuario y el porcentaje que este representa sobre el total.

El script deberá tener en cuenta todos los posibles fallos, para que no se muestre ningún
mensaje que no esté generado por el propio script.
FIN

imprimir_informe() {
    echo "USUARIO: $u"
    echo "**********************************************************"
    echo "PROCESOS EN EJECUCIÓN USUARIO: $num_procesos"
    echo "PROCESO MÁS ANTIGUO DEL USUARIO: $proceso_antiguo"
    echo "**********************************************************"
    # Si el listado de procesos existe (distinto de cero)
    if [[ -n "$lista_procesos" ]]; then
        echo "$lista_procesos"
    fi
    echo ""
    echo "**********************************************************"
    echo "DIRECTORIOS DEL USUARIO: $num_directorios"
    echo "FICHEROS REGULARES DEL USUARIO: $num_ficheros"
    echo "TAMAÑO TOTAL FICHEROS USUARIO: $tamano_bytes B"
    echo "USO DE DISCO DURO USUARIO: $porcentaje%"
    echo "**********************************************************"
    echo ""
}

# Función principal que genera el informe para un usuario concreto
generar_informe() {
    # Cogemos el parámetro 1 (por si se hubiera indicado el usuario concreto)
    u=$1

    # Comprobamos de forma silenciosa si el usuario existe en el sistema
    if ! id "$u" &>/dev/null; then
        return
    fi

    # 1. Obtener número de procesos en ejecución
    # Filtramos por usuario para ejecutar el script y por permisos del usuario que ejecuta el script
    num_procesos=$(ps -U "$u" -u "$u" --no-headers 2>/dev/null | wc -l)

    # 2. Obtener proceso más antiguo y lista completa
    if [[ "$num_procesos" -eq 0 ]]; then
        proceso_antiguo="Ninguno"
        lista_procesos=""
    else
        # --sort=lstart ordena por fecha de inicio (los más antiguos primero)
        proceso_antiguo=$(ps -U "$u" -u "$u" -o comm= --sort=lstart 2>/dev/null | head -n 1)
        lista_procesos=$(ps -U "$u" -u "$u" -o comm= 2>/dev/null)
    fi

    # 3. Contar directorios del usuario en todo el sistema
    num_directorios=$(find / -user "$u" -type d 2>/dev/null | wc -l)

    # 4. Contar ficheros regulares del usuario
    num_ficheros=$(find / -user "$u" -type f 2>/dev/null | wc -l)

    # 5. Calcular tamaño total en bytes de esos ficheros
    tamano_bytes=$(tamanyo_bytes_ficheros)

    # 6. Calcular el tamaño total del disco (partición raíz en bytes) para sacar el porcentaje
    total_disco=$(df -B1 / 2>/dev/null | obtener_total_disco)

    if [[ -n "$total_disco" ]] && [[ "$total_disco" -gt 0 ]]; then
        porcentaje=$(awk "BEGIN {printf \"%.2f\", ($tamano_bytes / $total_disco) * 100}")
    else
        porcentaje="0.00"
    fi

    imprimir_informe
}

tamanyo_bytes_ficheros() {
    # 1. Creamos la lista de tamaños primero
    lista_de_tamanyos=$(find / -user "$u" -type f -printf "%s\n" 2>/dev/null)

    # 2. Inicializamos el acumulador
    total=0

    # 3. El bucle "for-each" tradicional
    for tamano in $lista_de_tamanyos; do
        total=$((total + tamano))
    done

    echo $total
}

obtener_total_disco() {
    local cabecera
    local sistema total usados libres porcentaje punto_montaje

    read -r cabecera
    read -r sistema total usados libres porcentaje punto_montaje

    echo "$total"
}


# Lógica de gestión de los parámetros
case "$1" in
    -a)
        # Se obtiene la lista de todos los usuarios conectados actualmente (sin duplicados)
        usuarios_conectados=$(who 2>/dev/null | awk '{print $1}' | sort -u)
        for usuario in $usuarios_conectados; do
            generar_informe "$usuario"
        done
        ;;
    -u)
        # Si se pasa un segundo parámetro, es el usuario específico
        if [[ -n "$2" ]]; then
            generar_informe "$2"
        else
            # Si no se pone usuario tras la -u, se realiza para el usuario actual
            generar_informe "$(whoami 2>/dev/null)"
        fi
        ;;
    "")
        # Si no se pasan parámetros en absoluto, también asumimos usuario actual
        generar_informe "$(whoami 2>/dev/null)"
        ;;
    *)
        # Cualquier otro parámetro no contemplado finaliza silenciosamente
        exit 1
        ;;
esac

exit 0
