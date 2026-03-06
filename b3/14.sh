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
validar_entrada() {
    if [[ "$#" -ne 2 ]]; then
        echo "Número incorrecto de parámetros." >&2
        echo "Uso: $0 CURSO {-f|-c|-b}" >&2
        exit 2
    else
        curso="$1"
        opcion="$2"
        if [[ ! "$opcion" =~ ^-(f|c|b)$ ]]; then
            echo "Opción no válida: $opcion" >&2
            echo "Uso: $0 CURSO {-f|-c|-b}" >&2
            exit 2
        fi
    fi

}


# Comprueba que el script se está ejecutando como root.
# Solo es necesario para crear o borrar usuarios, grupos y homes.
soy_root() {
    if (($(id -u) != 0 )); then
        echo "Error: esta operación requiere root." >&2
        exit 1
    fi
}

# -f: genera el fichero de grupos del curso.
# Cada línea tendrá el formato: claveGrupo:numeroAlumnos
crear_archivo_grupos() {
    read -r -p "Número de grupos a registrar: " num_grupos
    if ! [[ "$num_grupos" =~ ^[0-9]+$ ]] || [[ "$num_grupos" -le 0 ]]; then
        echo "Número de grupos no válido." >&2
        exit 1
    fi

    # Crear o sobrescribir el fichero de grupos.
    > "$grupos_file"


    for ((i = 1; i <= num_grupos; i++)); do
        # Pedir los datos de cada grupo.
        read -r -p "Clave del grupo #$i: " clave
        read -r -p "Número de alumnos de $clave: " alumnos

        # Validar que la clave no esté vacía y que alumnos sea numérico.
        if [[ -n "$clave" && "$alumnos" =~ ^[0-9]+$ ]]; then
            echo "${clave}:${alumnos}" >> "$grupos_file"
        else
            echo "Datos inválidos para el grupo #$i." >&2
            exit 1
        fi

    done

    echo "Fichero creado: $grupos_file"
}

# -c: crea grupos y usuarios.
# Los directorios personales quedan organizados por grupo para dar más privacidad.
crear_cuentas() {
    soy_root
    if [[ ! -f "$grupos_file" ]]; then
        echo "Error: no existe $grupos_file. Ejecute antes con -f." >&2
        exit 1
    fi

    mkdir -p "$base_home"

    # Leer el fichero de grupos línea a línea: clave:alumnos
    while IFS=':' read -r clave alumnos; do
        # Ignorar líneas vacías o mal formadas.
        [[ -z "$clave" ]] && continue
        [[ "$alumnos" =~ ^[0-9]+$ ]] || continue

        # Crear el grupo si todavía no existe.
        getent group "$clave" >/dev/null || groupadd "$clave"

        # Crear el directorio contenedor del grupo.
        mkdir -p "$base_home/$clave"
        chmod 750 "$base_home/$clave"

        # Login: grupo + curso + número secuencial de alumno.
        for ((n = 1; n <= alumnos; n++)); do
            # Formatear el número del alumno con ceros a la izquierda (01, 02, ..., 10, etc.).
            num="$(printf '%02d' "$n")"
            login="${clave}${curso}${num}"
            home_dir="$base_home/$clave/$login"

            # Si el usuario ya existe, actualizar grupo principal y home.
            # Si no existe, crearlo y dejar la contraseña bloqueada.
            if id "$login" >/dev/null 2>&1; then
                # El usuario ya existe, actualizar su grupo principal y home.
                usermod -g "$clave" -d "$home_dir" "$login"
            else
                # El usuario no existe, crearlo con el grupo y home especificados.
                useradd -m -d "$home_dir" -g "$clave" -s /bin/bash "$login"
                passwd -l "$login" >/dev/null 2>&1 || true
            fi

            # Asegurar que el home exista y tenga permisos privados.
            mkdir -p "$home_dir"
            chown "$login:$clave" "$home_dir"
            chmod 700 "$home_dir"
        done
    done < "$grupos_file"

    echo "Cuentas y grupos creados/actualizados para el curso $curso."
}

# -b: elimina usuarios, grupos y directorios generados para ese curso.
borrar_cuentas() {
    soy_root
    if [[ ! -f "$grupos_file" ]]; then
        echo "Error: no existe $grupos_file." >&2
        exit 1
    fi

    # Recorrer el mismo fichero para localizar qué usuarios y grupos borrar.
    while IFS=':' read -r clave alumnos; do
        [[ -z "$clave" ]] && continue
        [[ "$alumnos" =~ ^[0-9]+$ ]] || continue

        # Borrar las cuentas asociadas a ese grupo y curso.
        for ((n = 1; n <= alumnos; n++)); do
            # Formatear el número del alumno con ceros a la izquierda (01, 02, ..., 10, etc.).
            num="$(printf '%02d' "$n")"
            login="${clave}${curso}${num}"
            if id "$login" >/dev/null 2>&1; then
                # Eliminar el usuario y su home. Si el usuario no tiene home o no se puede eliminar con -r, intentar sin -r.
                userdel -r "$login" >/dev/null 2>&1 || userdel "$login"
            fi
        done

        # Intentar borrar el grupo si existe.
        if getent group "$clave" >/dev/null; then
            groupdel "$clave" >/dev/null 2>&1 || true
        fi

        # Borrar el directorio del grupo dentro del curso.
        rm -rf "$base_home/$clave"
    done < "$grupos_file"

    # Eliminar el directorio del curso si ha quedado vacío.
    rmdir "$base_home" >/dev/null 2>&1 || true
    echo "Cuentas, grupos y directorios eliminados para el curso $curso."
}


validar_entrada "$@"
# Fichero con la relación grupo:número de alumnos del curso.
grupos_file="$HOME/proyecto/scripts/b3/14/grupos_${curso}.txt"

# Directorio base donde se crearán los homes organizados por curso y grupo.
base_home="$HOME/proyecto/scripts/b3/14/${curso}"

# Elegir la operación solicitada por parámetro.
case "$opcion" in
    -f)
        crear_archivo_grupos
        ;;
    -c)
        crear_cuentas
        ;;
    -b)
        borrar_cuentas
        ;;
    *)
        usage
        exit 2
        ;;
esac