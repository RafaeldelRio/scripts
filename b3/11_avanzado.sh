#!/bin/bash

: << "FIN"
EJERCICIO 11.
En el servidor de un centro con un ciclo medio de Sistemas Microinformáticos y Redes,
el profesor encargado de mantenerlo quiere a principios de septiembre hacer la transición del
curso pasado al actual.
El servidor está organizado de la siguiente forma:
- Los alumnos de primero tienen como grupo principal smr1.
- Los alumnos de segundo tienen como grupo principal smr2.
- Los alumnos con módulos de primero matriculados en alguno de segundo tienen como grupo principal smr1 y pertenecen a smr2.

El profesor encargado parte de la configuración del curso pasado y, a la vista de las
nuevas matriculaciones, debe actualizar la situación de usuarios y grupos. Para ello recibe un
fichero con la siguiente pinta:
- Nombre Real1;DNI1;1
- Nombre Real2;DNI2;1+
- Nombre Real3;DNI3;2

donde aparece los alumnos actualmente matriculados y «1» significa que el alumno sólo cursa
primero, «2» que sólo cursa segundo y «1+ que está entre primero y segundo. El nick del
alumno en el sistema se obtiene tomando la inicial de su primer nombre, las tres letras iniciales
de los dos apellidos y las tres últimas cifras del DNI (p.e. Manuel Jesús Vázquez Montalbán pasa
a mvazmonNNN).
Se pide crear un programa que tome el listado y

- Limpie del sistema los alumnos que ya no se encuentren matriculados (bien por abandono, bien porque hayan acabado).
    Bórrese también su directorio de usuario.
- Actualice la pertenencia a grupos de los alumnos que ya existieran en el sistema.
- Añada los nuevos alumnos matriculados.

Sintaxis: 11.sh fichero

Nota: En la información gecos debe añadirse el nombre real del alumno (no su DNI) y 
    si repite añadirse tras el nombre la palabra «repetidor» entre paréntesis.

Nota: Haga el programa para manipular usuarios locales, pero escriba el programa de modo que 
    sea fácil cambiar a otro tipo de usuarios.
FIN


# Muestra uso correcto del script.
usage() {
    echo "Uso: $0 fichero" >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

if [ "$EUID" -ne 0 ]; then
    echo "Error: debe ejecutarse como root." >&2
    exit 1
fi

input_file="$1"
if [ ! -f "$input_file" ]; then
    echo "Error: no existe el fichero $input_file" >&2
    exit 1
fi

# Garantiza que existan los grupos académicos requeridos.
ensure_group() {
    local group="$1"
    getent group "$group" >/dev/null || groupadd "$group"
}

# Normaliza texto para construir login (minúsculas y solo letras).
sanitize_token() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alpha:]'
}

# Genera el login: inicial nombre + 3+3 apellidos + 3 últimas cifras DNI.
generate_login() {
    local real_name="$1"
    local dni="$2"
    local -a parts

    read -r -a parts <<< "$real_name"
    if [ "${#parts[@]}" -lt 3 ]; then
        return 1
    fi

    local first_name="${parts[0]}"
    local last_name1="${parts[${#parts[@]}-2]}"
    local last_name2="${parts[${#parts[@]}-1]}"
    local dni_digits
    dni_digits="$(echo "$dni" | tr -cd '0-9')"
    if [ "${#dni_digits}" -lt 3 ]; then
        return 1
    fi

    local nick
    nick="$(sanitize_token "${first_name:0:1}")$(sanitize_token "${last_name1:0:3}")$(sanitize_token "${last_name2:0:3}")${dni_digits: -3}"
    [ -n "$nick" ] || return 1
    echo "$nick"
}

# Crea o actualiza alumno y ajusta pertenencias según estado 1/2/1+.
set_student_state() {
    local login="$1"
    local full_name="$2"
    local state="$3"

    local primary_group supplementary_group gecos
    case "$state" in
        1)
            primary_group="smr1"
            supplementary_group=""
            gecos="$full_name"
            ;;
        2)
            primary_group="smr2"
            supplementary_group=""
            gecos="$full_name"
            ;;
        1+)
            primary_group="smr1"
            supplementary_group="smr2"
            gecos="$full_name (repetidor)"
            ;;
        *)
            return 1
            ;;
    esac

    if id "$login" >/dev/null 2>&1; then
        usermod -c "$gecos" -g "$primary_group" "$login"
    else
        useradd -m -c "$gecos" -g "$primary_group" "$login"
    fi

    if [ "$supplementary_group" = "smr2" ]; then
        usermod -aG smr2 "$login"
    else
        gpasswd -d "$login" smr2 >/dev/null 2>&1 || true
    fi

    if [ "$primary_group" != "smr1" ]; then
        gpasswd -d "$login" smr1 >/dev/null 2>&1 || true
    fi
}

# Asegura grupos base del ciclo.
ensure_group smr1
ensure_group smr2

declare -A desired_state
declare -A desired_name

# Carga el estado deseado desde el fichero de matrícula.
while IFS=';' read -r full_name dni state; do
    [ -z "${full_name// /}" ] && continue
    [ -z "$dni" ] && continue
    [ -z "$state" ] && continue

    login="$(generate_login "$full_name" "$dni")" || {
        echo "Aviso: línea inválida, se omite: $full_name;$dni;$state" >&2
        continue
    }

    desired_state["$login"]="$state"
    desired_name["$login"]="$full_name"
done < "$input_file"

declare -A existing_students

gid_smr1="$(getent group smr1 | cut -d: -f3)"
gid_smr2="$(getent group smr2 | cut -d: -f3)"

# Descubre usuarios existentes relacionados con smr1/smr2.
while IFS=: read -r user _ uid gid _ _ _; do
    if [ "$gid" = "$gid_smr1" ] || [ "$gid" = "$gid_smr2" ]; then
        existing_students["$user"]=1
    fi
done < /etc/passwd

members_smr1="$(getent group smr1 | cut -d: -f4)"
members_smr2="$(getent group smr2 | cut -d: -f4)"

IFS=',' read -r -a arr1 <<< "$members_smr1"
for user in "${arr1[@]}"; do
    [ -n "$user" ] && existing_students["$user"]=1
done

IFS=',' read -r -a arr2 <<< "$members_smr2"
for user in "${arr2[@]}"; do
    [ -n "$user" ] && existing_students["$user"]=1
done

# Elimina alumnos que ya no figuran en la matrícula actual.
for user in "${!existing_students[@]}"; do
    if [ -z "${desired_state[$user]:-}" ]; then
        userdel -r "$user" >/dev/null 2>&1 || userdel "$user"
    fi
done

# Crea/actualiza los alumnos presentes en el listado actual.
for user in "${!desired_state[@]}"; do
    set_student_state "$user" "${desired_name[$user]}" "${desired_state[$user]}"
done

echo "Actualización de alumnos completada."