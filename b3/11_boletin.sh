#!/bin/bash

: <<"FIN"
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
primero, «2» que sólo cursa segundo y «1+» que está entre primero y segundo. El nick del
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

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este script actualiza el estado de los alumnos de un centro en función de un
# fichero de matrícula:
# - crea nicks de usuario a partir de nombre y DNI,
# - asigna grupo principal y secundario según el curso,
# - crea usuarios nuevos,
# - actualiza grupos de usuarios existentes,
# - elimina usuarios que ya no aparecen en el listado actual.

# Nombres de los grupos que representan primero y segundo.
GRUPO1="smr1"
GRUPO2="smr2"

# Función genérica para mostrar avisos o errores fatales.
error() {
    local EXITCODE=$1
    shift
    if [ "$EXITCODE" -eq 0 ]; then
        echo "¡Atención!" $* >&2
    else
        echo "ERROR." $* >&2
        exit "$EXITCODE"
    fi
}

# Devuelve éxito solo si el script se ejecuta como administrador.
soy_root() {
    [ "$(id -u)" -eq 0 ]
}
# Convierte caracteres no ingleses:
# José Martín => Jose Martin
desacentua() {
    # `iconv` translitera caracteres acentuados a su versión ASCII aproximada.
    echo "$@" | iconv -f utf8 -t ascii//TRANSLIT
}
#
# Crea el nick del usuario
# $1: Nombre real.
# $2: NIF
#
crea_nick() {
    # Transformamos caracteres no ingleses
    local nombre="$(desacentua $1)"
    local inicial nif="$2" digitos
    # Eliminamos del nombre partículas como "de". Por ejemplo:
    # Miguel de la Quadra-Salcedo y Gayarre => Miguel Quadra-Salcedo
    Gayarre.
    nombre=$(echo "$nombre" | sed -r 's:\b[a-z]\w* ?::g')
    [ -n "$nombre" ] || return 1

    set -- $nombre                # Descomponemos el nombre.
    inicial=$(printf "%.1s" "$1") # Inicial del primer nombre.
    shift
    # Nos quedamos sólo con las dos últimas palabras (los apellidos)
    while [ $# -gt 2 ]; do
        shift
    done

    # Del DNI se extraen las tres últimas cifras numéricas.
    digitos=$(echo "$nif" | sed -r 's:.*([0-9]{3})[a-zA-Z]?$:\1:')

    # El nick final se construye con: inicial + 3 letras de cada apellido + 3 cifras.
    echo "$inicial$(printf "%.3s" "$@")$digitos" | tr '[:upper:]'
    '[:lower:]'
}
# Comprueba si la línea del fichero de entrada
# tiene el formato correcto.

# $1: Nombre
# $2: NIF
# $3: Curso del alumno
comprobar_linea() {
    # La línea no debe estar vacía ni ser de comentario
    [ -n "${1%%#*}" ] || return 1

    # NIF incorrecto (podría mejorarse y comprobrar la letra).
    echo "$2" | grep -qE '^[0-9]{7,8}[a-zA-Z]$' || return 2

    # El tercer campo debe ser 1, 2 o 1+.
    case $3 in
        1 | 2 | 1+) ;;
        *) return 2 ;;
    esac
    return 0
}
# Analiza un usuario inscrito en la entrada y
# realiza la operación pertinente.
# $1: Nombre completo de alumno
# $2: NIF.
# $3: Grupo al que debe pertenecer el alumno
trata_usuario() {
    local nick princpal secundario

    # Redirigimos temporalmente stdout a stderr para que los comandos internos
    # no ensucien la salida principal del script.
    exec 3>&1 1>&2
    nick=$(crea_nick "$1" "$2") || return 1

    # Según el tipo de matrícula, se decide grupo principal y, si procede,
    # grupo secundario.
    case "$3" in
        1) principal="$GRUPO1" ;;
        2) principal="$GRUPO2" ;;
        1+)
            principal="$GRUPO1"
            secundario="$GRUPO2"
            ;;
    esac

    # Si el usuario ya existe, se actualiza; si no existe, se crea.
    if id "$nick" >/dev/null 2>&1; then
        pone_grupo_principal "$nick" "$principal"
    else
        add_user "$nick" "$principal" "$(desacentua $nombre)"
    fi
    if [ -n "$secundario" ]; then
        # En alumnos repetidores se añade grupo secundario y se retoca GECOS.
        agrega_grupo_secundario "$nick" "$secundario"
        cambia_gecos "$nick" "$(desacentua "$1 (repetidor)")"
    fi

    # Restauramos stdout y devolvemos el nick calculado.
    exec 1>&3 3>&-
    echo "$nick"
}
{ ## Manipulación de usuarios (cambiará si no son locales).
    #
    # Crea el usuario con contraseña nula y obliga
    # a cambiar la contraseña en el próximo login.
    #
    add_user() {
        # `adduser` crea cuenta, HOME y grupo principal.
        adduser "$1" --ingroup "$2" --gecos "$3" --disabled-password

        # `usermod -p ""` deja contraseña vacía/forzada.
        usermod -p "" "$1"

        # `chage -d0` obliga a cambiar contraseña en el próximo acceso.
        chage -d0 "$1"
    }
    pone_grupo_principal() {
        # Si el grupo ya es suplementario, tiene que dejar de serlo
        id -Gn "$1" | grep -Eq " $2\b" && deluser "$1" "$2"

        # `usermod -g` cambia el grupo principal.
        usermod -g "$2" "$1"
    }
    agrega_grupo_secundario() {
        # `adduser usuario grupo` añade al usuario como miembro secundario.
        adduser "$1" "$2"
    }
    del_user() {
        # `--remove-home` borra también el directorio personal.
        deluser --remove-home "$1"
    }
    cambia_gecos() {
        # `chfn -f` modifica el campo nombre completo del usuario.
        chfn -f "$2" "$1"
    }
}
#
# Lista los antiguos alumnos que
# han dejado el instituto en el nuevo curso
# $@: Los nicks de todos los alumnos que sí están matriculados.
#
listar_exalumnos() {
    local usu grupo gid1 gid2 matriculados="$1"

    # Recuperamos los GID reales asociados a los grupos smr1 y smr2.
    gid1=$(getent group "$GRUPO1" | cut -d: -f3)
    gid2=$(getent group "$GRUPO2" | cut -d: -f3)

    # Se recorre /etc/passwd y se filtran usuarios cuyo grupo principal coincide
    # con alguno de los grupos académicos.
    getent passwd | while read -r usu _ _ gid _; do
        case "$gid" in
            $gid1 | $gid2)
                echo "$matriculados" | grep -Eq "^$usu$" || echo "$usu"
                ;;
        esac
    done
}
#
# MAIN
#

# Validaciones iniciales antes de modificar usuarios del sistema.
soy_root || error 1 "Necesita permisos de administración"
[ -f "$1" ] || error 1 "$1: Fichero inexistente"
for grupo in "$GRUPO1" "$GRUPO2"; do
    getent group "$grupo" >/dev/null || error 1 "El grupo $grupo no
existe"
done
# Actualiza los alumnos matriculados

# `matriculados` irá acumulando los nicks válidos del nuevo curso.
num=0
matriculados=

# Se lee el fichero de entrada línea a línea.
while IFS=: read -r nombre nif curso; do
    num=$((num + 1))
    comprobar_linea "$nombre" "$nif" "$curso"
    case $? in
        0) ;;
        1) # Simnplemente es una línea en blanco o de comentario
            continue
            ;;
        2)
            error 0 "Línea $num incomprensible" >&2
            continue
            ;;
    esac
    nick=$(trata_usuario "$nombre" "$nif" "$curso")
    if [ $? -ne 0 ]; then
        error 0 "No puede generarse nick para $nombre. Se salta"
        continue
    fi
    matriculados="$matriculados
$nick"
done <"$1"

# Borrar antiguos alumnos
listar_exalumnos "$matriculados" | while read -r exalumno; do
    del_user "$exalumno"
done
