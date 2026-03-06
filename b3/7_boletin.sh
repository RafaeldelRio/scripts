#!/bin/bash

: <<"FIN"
EJERCICIO 7.
Se desea crear un script para automatizar la creación de usuarios para el servidor FTP,
de manera que:
- Los usuarios son usuarios reales (aparecen en /etc/passwd).
- Sus directorios personales son /srv/ftp/NOMBRE_USUARIO.
- Su grupo principal es ftpusers.
- Si el usuario ya existe, se genera un error.
- Además, si se añade el argumento --no-password, no se pide contraseña y el usuario se crea con la contraseña deshabilitada.
FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Automatiza el alta de usuarios para un servidor FTP:
# - comprueba que quien lo ejecuta sea `root`,
# - verifica si el usuario ya existe,
# - crea el grupo principal si no existe,
# - crea el usuario con su directorio personal en `/srv/ftp`,
# - y opcionalmente pide contraseña, salvo si se usa `--no-password`.

# Directorio base donde se crearán las carpetas personales de los usuarios FTP.
HOMEDIR_BASE=${HOMEDIR_BASE:-/srv/ftp}

# Grupo principal que se usará al crear los usuarios.
GRUPO_PRI=""${GRUPO_PRI:-ftpusers}

# Si esta variable tiene valor, el script pedirá contraseña.
PASSWORD=1

# Número máximo de intentos para leer usuario/contraseña.
INTENTOS_MAX=${INTENTOS_MAX:-3}

# Comprueba si el UID actual es 0. En Unix, UID 0 equivale a root.
soy_root() {
    [ "$(id -u)" -eq 0 ]
}

# Función común para mostrar avisos o errores fatales.
error() {
    local EXITCODE="$1"
    shift
    if [ "$EXITCODE" -eq 0 ]; then
        echo "¡Atención! "$* >&2
    else
        echo "ERROR. "$* >&2
        exit "$EXITCODE"
    fi
}
#
# Comprueba si un usuario existe.
# $1: Nombre de usuario
#
existe_usuario() {
    # `id usuario` falla si el usuario no existe.
    id "$1" >/dev/null 2>&1
}
#
# Comprueba si existe un grupo
# $1: Nombre del grupo
#
existe_grupo() {
    # `getent group grupo` consulta la base de datos de grupos del sistema.
    getent group "$1" >/dev/null
}
# Creación de usuarios/grupos.
# La implementación depende del tipo de usuario.
#
# Crea un grupo de sistema.
# $1: Nombre del grupo
#
crea_grupo() {
    # `addgroup --system` crea un grupo de sistema.
    addgroup --system "$1"
}
# Crea un usuario
# $1: Nombre de usuario
# $2: Grupo primario
# $3: Directorio personal
crea_usuario() {
    # `adduser` crea el usuario y su HOME.
    # `--disabled-password` hace que nazca sin contraseña válida.
    adduser --home "$3" --gecos "$1 (Usuario FTP)" --ingroup "$2" --
    disabled-password "$1"
}
#
# Cambia la contraseña
# $1: Usuario
# $2: Contraseña
#
establece_password() {
    # `chpasswd` recibe líneas usuario:contraseña por la entrada estándar.
    echo "$1:$2" | chpasswd
}
#
# Pregunta por el nombre de usuario
pregunta_usuario() {
    local i usuario
    for i in $(seq "$INTENTOS_MAX" -1 1); do
        read -rp "Nombre de usuario ($i intentos): " usuario

        # Primero se valida que no esté vacío.
        if [ -z "$usuario" ]; then
            error 0 "'$usuario': Usuario incorrecto"

        # Después se comprueba si ese login ya existe en el sistema.
        elif existe_usuario "$usuario"; then
            error 0 "'$usuario': El usuario ya existe"
        else
            echo "$usuario"
            return 0
        fi
    done
    return 1
}
# Pregunta por la contraseña
#
pregunta_password() {
    local i pass1 pass2
    for i in $(seq "$INTENTOS_MAX" -1 1); do
        # Se pregunta dos veces para evitar errores de escritura.
        read -s -rp "Contraseña ($i intentos): " pass1
        echo >&2
        read -s -rp "Repita la contraseña: " pass2
        echo >&2
        [ "$pass1" = "$pass2" ] && echo "$pass1" && return 0
        error 0 "Las contraseñas no coinciden."
    done
    return 1
}
#
# Main

# Antes de hacer nada, se exige ejecución como administrador.
soy_root || error 1 "Debe ser administrador"

# Si el primer argumento es `--no-password`, se desactiva la petición de clave.
[ "$1" = "--no-password" ] && unset PASSWORD
echo "Programa para crear usuarios FTP."
echo
NOMBRE=$(pregunta_usuario) || error 1 "No se puede fijar el usuario"

# Solo se pide contraseña si el modo normal sigue activo.
if [ -n "$PASSWORD" ]; then
    PASS=$(pregunta_password) || error 1 "Imposible establecer una con-
traseña"
fi

# Si el grupo principal no existe, se crea automáticamente.
existe_grupo "$GRUPO_PRI" || crea_grupo "$GRUPO_PRI"
crea_usuario "$NOMBRE" "$GRUPO_PRI" "$HOMEDIR_BASE/$NOMBRE"

# Si se recogió contraseña, se asigna al usuario recién creado.
[ -n "$PASSWORD" ] && establece_password "$NOMBRE" "$PASS"
