#!/bin/bash

: << "FIN"
EJERCICIO 14. EXAMEN OPOSICIONES SAI. 2006. EJERCICIO 2.
El ejercicio práctico se realizará bajo sistema operativo LÍNUX. Se podrá hacer uso del comando man.

Elabora un script para automatizar las tareas de mantenimiento de usuarios en un servidor Linux, en el
    que realizan prácticas de scripts diversos grupos de alumnos.

Recibirá como parámetro el curso actual y admitirá además las siguientes opciones:

-f Creación del fichero de grupos del curso actual. Tendrá el siguiente formato: claveGrupo:numeroAlumnos
-c Creación de cuentas de usuario y grupos. El login reflejará grupo al que pertenece, curso académico y 
    número de alumno. Además, los directorios home estarán organizados por grupos, garantizando al máximo la privacidad.
-b Eliminación de cuentas, grupos y directorios.


FIN

# Ayuda básica de uso.
usage() {
    echo "Uso: $0 CURSO {-f|-c|-b}" >&2
}

if [ "$#" -ne 2 ]; then
    usage
    exit 2
fi

curso="$1"
opcion="$2"
grupos_file="grupos_${curso}.txt"
base_home="/srv/practicas/${curso}"

# Operaciones de cuentas/grupos requieren root.
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: esta operación requiere root." >&2
        exit 1
    fi
}

# -f: genera fichero de grupos del curso con formato claveGrupo:numeroAlumnos.
create_group_file() {
    read -r -p "Número de grupos a registrar: " num_grupos
    if ! [[ "$num_grupos" =~ ^[0-9]+$ ]] || [ "$num_grupos" -le 0 ]; then
        echo "Número de grupos no válido." >&2
        exit 1
    fi

    : > "$grupos_file"
    for ((i = 1; i <= num_grupos; i++)); do
        read -r -p "Clave del grupo #$i: " clave
        read -r -p "Número de alumnos de $clave: " alumnos

        if [ -z "$clave" ] || ! [[ "$alumnos" =~ ^[0-9]+$ ]]; then
            echo "Datos inválidos para el grupo #$i." >&2
            exit 1
        fi

        echo "${clave}:${alumnos}" >> "$grupos_file"
    done

    echo "Fichero creado: $grupos_file"
}

# -c: crea grupos y usuarios; organiza homes por grupo para maximizar privacidad.
create_accounts() {
    require_root
    if [ ! -f "$grupos_file" ]; then
        echo "Error: no existe $grupos_file. Ejecute antes con -f." >&2
        exit 1
    fi

    mkdir -p "$base_home"

    while IFS=':' read -r clave alumnos; do
        [ -z "$clave" ] && continue
        [[ "$alumnos" =~ ^[0-9]+$ ]] || continue

        getent group "$clave" >/dev/null || groupadd "$clave"
        mkdir -p "$base_home/$clave"
        chmod 750 "$base_home/$clave"

        # Login: grupo + curso + número secuencial de alumno.
        for ((n = 1; n <= alumnos; n++)); do
            num="$(printf '%02d' "$n")"
            login="${clave}${curso}${num}"
            home_dir="$base_home/$clave/$login"

            if id "$login" >/dev/null 2>&1; then
                usermod -g "$clave" -d "$home_dir" "$login"
            else
                useradd -m -d "$home_dir" -g "$clave" -s /bin/bash "$login"
                passwd -l "$login" >/dev/null 2>&1 || true
            fi

            mkdir -p "$home_dir"
            chown "$login:$clave" "$home_dir"
            chmod 700 "$home_dir"
        done
    done < "$grupos_file"

    echo "Cuentas y grupos creados/actualizados para el curso $curso."
}

# -b: elimina usuarios, grupos y directorios generados para ese curso.
delete_accounts() {
    require_root
    if [ ! -f "$grupos_file" ]; then
        echo "Error: no existe $grupos_file." >&2
        exit 1
    fi

    while IFS=':' read -r clave alumnos; do
        [ -z "$clave" ] && continue
        [[ "$alumnos" =~ ^[0-9]+$ ]] || continue

        for ((n = 1; n <= alumnos; n++)); do
            num="$(printf '%02d' "$n")"
            login="${clave}${curso}${num}"
            if id "$login" >/dev/null 2>&1; then
                userdel -r "$login" >/dev/null 2>&1 || userdel "$login"
            fi
        done

        if getent group "$clave" >/dev/null; then
            groupdel "$clave" >/dev/null 2>&1 || true
        fi

        rm -rf "$base_home/$clave"
    done < "$grupos_file"

    rmdir "$base_home" >/dev/null 2>&1 || true
    echo "Cuentas, grupos y directorios eliminados para el curso $curso."
}

# Selector de modo de operación.
case "$opcion" in
    -f)
        create_group_file
        ;;
    -c)
        create_accounts
        ;;
    -b)
        delete_accounts
        ;;
    *)
        usage
        exit 2
        ;;
esac