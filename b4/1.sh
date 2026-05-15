#!/bin/bash

: <<"FIN"
EJERCICIO 1.
Realizar un shell script llamado copiaSeguridad.sh para automatizar
las copias de seguridad de las cuentas de usuario (UID>=1000) de un servidor.
El script debe admitir dos parámetros obligatorios acción y directorio, es decir:
    ./copiaSeguridad.sh acción directorio
acción será -c (para crear la copia de seguridad en el directorio) o
    -r (para restaurar la copia de seguridad desde el directorio).

La copia de seguridad consistirá en un fichero llamado usuarios y en un fichero por
usuario del sistema xxxxxx.tgz y empaquetado en el que se encontrará su
directorio de trabajo, es decir, el usuario manolo con directorio de trabajo
/home/manolo creará un fichero manolo.tgz que contendrá esta carpeta.

El fichero usuarios tendrá la siguiente estructura:
    usuario1;nombre_completo1;clave_encriptada1;directorio_home1;shell1
    usuario2;nombre_completo2;clave_encriptada2;directorio_home2;shell2

-c Buscará en los ficheros adecuados la información necesaria para generar el
    fichero usuarios con la estructura anterior. Localizará el directorio de trabajo
    de estos y generará los ficheros xxxxxx.tgz

-r Restaurará la copia de seguridad que se encuentra en directorio y dejará el
    sistema tal y como se encontraba en el momento de sacar la copia de seguridad

El script deberá tener en cuenta todos los posibles fallos para que no muestra
ningún mensaje que no esté generado por el script
(no existe directorio, no existe permisos...)
FIN

# Este script se ha organizado en funciones pequeñas y con nombres descriptivos.
# La idea es que cada función tenga una única responsabilidad:
#   - validar datos de entrada
#   - leer información del sistema
#   - crear la copia de seguridad
#   - restaurar la copia guardada
# Así el flujo principal queda muy claro al final del archivo.

# Muestra la sintaxis correcta del script.
mostrar_uso() {
    echo "Uso: $0 <-c|-r> <directorio>"
}


# Centralizamos aquí la salida por error para no repetir código.
# Siempre mostramos mensajes propios del script, tal y como pide el enunciado.
salir_con_error() {
    echo "Error: $1"
    exit 1
}


# Para leer /etc/shadow y modificar cuentas de usuario necesitamos privilegios de
# administración. Si no somos root, paramos inmediatamente.
comprobar_root() {
    if (( "$EUID" != 0 )); then
        salir_con_error "Este script debe ejecutarse con privilegios de administrador (root)."
    fi
}


# Validamos que existan exactamente dos parámetros: acción y directorio.
comprobar_parametros() {
    if (( "$#" != 2 )); then
        echo "Error: Parámetros incorrectos."
        mostrar_uso
        exit 1
    fi
}


# Decide si un usuario del sistema debe formar parte de la copia de seguridad.
# En este script se considera usuario normal a quien tiene UID >= 1000.
# Además se excluye la cuenta nobody (UID 65534), que no es una cuenta humana.
es_usuario_a_copiar() {
    local uid="$1"

    if (( "$uid" >= 1000 )) && (( "$uid" != 65534 )); then
        return 0
    fi

    return 1
}


# Si el directorio de destino no existe, intentamos crearlo.
# Si existe pero no se puede escribir en él, abortamos.
preparar_directorio_para_copia() {
    local directorio="$1"

    if [[ ! -d "$directorio" ]]; then
        mkdir -p "$directorio" 2>/dev/null
        if (( "$?" != 0 )); then
            salir_con_error "No se pudo crear el directorio '$directorio'."
        fi
    fi

    if [[ ! -w "$directorio" ]]; then
        salir_con_error "No hay permisos de escritura en el directorio '$directorio'."
    fi
}


# Para restaurar necesitamos al menos que el directorio exista, pueda leerse y
# contenga el fichero principal llamado "usuarios".
comprobar_directorio_de_restauracion() {
    local directorio="$1"

    if [[ ! -d "$directorio" ]]; then
        salir_con_error "El directorio '$directorio' no existe."
    fi

    if [[ ! -r "$directorio" ]]; then
        salir_con_error "No hay permisos de lectura sobre el directorio '$directorio'."
    fi

    if [[ ! -f "$directorio/usuarios" ]]; then
        salir_con_error "No se encuentra el fichero 'usuarios' dentro de '$directorio'."
    fi

    if [[ ! -r "$directorio/usuarios" ]]; then
        salir_con_error "No se puede leer el fichero 'usuarios' dentro de '$directorio'."
    fi
}


# Creamos o vaciamos el fichero de índice llamado "usuarios".
# Ese fichero es la base de la restauración posterior.
inicializar_fichero_usuarios() {
    local directorio="$1"

    : > "$directorio/usuarios" 2>/dev/null
    if (( "$?" != 0 )); then
        salir_con_error "No se puede escribir el archivo 'usuarios' en '$directorio'."
    fi
}


# Busca la clave cifrada de un usuario recorriendo /etc/shadow línea a línea.
# No usamos awk para que el proceso sea más explícito y fácil de seguir.
obtener_clave_encriptada() {
    local usuario_buscado="$1"
    local usuario_shadow=""
    local clave_shadow=""

    while IFS=: read -r usuario_shadow clave_shadow _; do
        if [[ "$usuario_shadow" = "$usuario_buscado" ]]; then
            echo "$clave_shadow"
            return 0
        fi
    done < /etc/shadow

    return 1
}


# Guarda una línea en el fichero "usuarios" con el formato pedido:
# usuario;nombre_completo;clave_encriptada;home;shell
escribir_registro_de_usuario() {
    local directorio="$1"
    local usuario="$2"
    local nombre_completo="$3"
    local clave_encriptada="$4"
    local home="$5"
    local shell="$6"

    printf '%s;%s;%s;%s;%s\n' \
        "$usuario" \
        "$nombre_completo" \
        "$clave_encriptada" \
        "$home" \
        "$shell" >> "$directorio/usuarios" 2>/dev/null

    if (( "$?" != 0 )); then
        salir_con_error "No se pudo escribir la información del usuario '$usuario' en '$directorio/usuarios'."
    fi
}


# Crea el archivo comprimido de un usuario a partir de su directorio personal.
# Usamos tar desde / para guardar la ruta completa relativa, por ejemplo:
#   /home/manolo  ->  home/manolo
crear_tgz_del_home() {
    local directorio="$1"
    local usuario="$2"
    local home="$3"
    local home_relativo=""

    if [[ ! -d "$home" ]]; then
        salir_con_error "El directorio personal '$home' del usuario '$usuario' no existe."
    fi

    home_relativo="${home#/}"

    tar -czf "$directorio/${usuario}.tgz" -C / "$home_relativo" 2>/dev/null
    if (( "$?" != 0 )); then
        salir_con_error "No se pudo crear la copia del directorio personal del usuario '$usuario'."
    fi
}


# Recorre /etc/passwd y procesa únicamente los usuarios normales.
# Cada línea de /etc/passwd tiene esta forma:
#   usuario:x:uid:gid:gecos:home:shell
crear_copia_de_seguridad() {
    local directorio="$1"
    local usuario=""
    local uid=""
    local gecos=""
    local home=""
    local shell=""
    local clave_encriptada=""
    local usuarios_copiados=0

    preparar_directorio_para_copia "$directorio"
    inicializar_fichero_usuarios "$directorio"

    while IFS=: read -r usuario _ uid _ gecos home shell; do
        if ! es_usuario_a_copiar "$uid"; then
            continue
        fi

        clave_encriptada=$(obtener_clave_encriptada "$usuario")
        if (( "$?" != 0 )); then
            salir_con_error "No se pudo obtener la clave encriptada del usuario '$usuario'."
        fi

        escribir_registro_de_usuario "$directorio" "$usuario" "$gecos" "$clave_encriptada" "$home" "$shell"
        crear_tgz_del_home "$directorio" "$usuario" "$home"

        usuarios_copiados=$((usuarios_copiados + 1))
    done < /etc/passwd

    echo "Copia de seguridad creada correctamente en '$directorio'. Usuarios copiados: $usuarios_copiados."
}


# Comprueba si una cuenta existe ya en el sistema.
# Redirigimos la salida porque solo queremos usar el código de retorno.
existe_usuario() {
    local usuario="$1"

    id "$usuario" >/dev/null 2>&1
}


# Si el usuario ya existe, actualizamos sus datos básicos.
# Si no existe, lo creamos con la información guardada en la copia.
crear_o_actualizar_usuario() {
    local usuario="$1"
    local nombre_completo="$2"
    local clave_encriptada="$3"
    local home="$4"
    local shell="$5"

    if existe_usuario "$usuario"; then
        usermod -c "$nombre_completo" -d "$home" -s "$shell" -p "$clave_encriptada" "$usuario" 2>/dev/null
        if (( "$?" != 0 )); then
            salir_con_error "No se pudo actualizar el usuario '$usuario'."
        fi
    else
        useradd -m -c "$nombre_completo" -d "$home" -s "$shell" -p "$clave_encriptada" "$usuario" 2>/dev/null
        if (( "$?" != 0 )); then
            salir_con_error "No se pudo crear el usuario '$usuario'."
        fi
    fi
}


# Recupera el contenido del directorio personal guardado en el .tgz del usuario.
restaurar_home_de_usuario() {
    local directorio="$1"
    local usuario="$2"
    local home="$3"
    local grupo_principal=""

    if [ ! -f "$directorio/${usuario}.tgz" ]; then
        salir_con_error "No se encuentra el fichero '$directorio/${usuario}.tgz'."
    fi

    tar -xzf "$directorio/${usuario}.tgz" -C / 2>/dev/null
    if (( "$?" != 0 )); then
        salir_con_error "No se pudo restaurar el directorio personal del usuario '$usuario'."
    fi

    if [[ -d "$home" ]]; then
        grupo_principal=$(id -gn "$usuario" 2>/dev/null)
        if [[ -z "$grupo_principal" ]]; then
            salir_con_error "No se pudo averiguar el grupo principal del usuario '$usuario'."
        fi

        chown -R "$usuario:$grupo_principal" "$home" 2>/dev/null
        if (( "$?" != 0 )); then
            salir_con_error "No se pudieron ajustar los permisos del directorio personal de '$usuario'."
        fi
    fi
}


# Lee el fichero "usuarios" de la copia y reconstruye las cuentas del sistema.
restaurar_copia_de_seguridad() {
    local directorio="$1"
    local usuario=""
    local nombre_completo=""
    local clave_encriptada=""
    local home=""
    local shell=""
    local usuarios_restaurados=0

    comprobar_directorio_de_restauracion "$directorio"

    while IFS=';' read -r usuario nombre_completo clave_encriptada home shell; do
        if [ -z "$usuario" ]; then
            continue
        fi

        crear_o_actualizar_usuario "$usuario" "$nombre_completo" "$clave_encriptada" "$home" "$shell"
        restaurar_home_de_usuario "$directorio" "$usuario" "$home"

        usuarios_restaurados=$((usuarios_restaurados + 1))
    done < "$directorio/usuarios"

    echo "Sistema restaurado correctamente desde la copia en '$directorio'. Usuarios restaurados: $usuarios_restaurados."
}


# -----------------------------------------------------------------------------
# Programa principal

comprobar_root
comprobar_parametros "$@"

ACCION="$1"
DIR="$2"

case "$ACCION" in
    -c)
        crear_copia_de_seguridad "$DIR"
        ;;
    -r)
        restaurar_copia_de_seguridad "$DIR"
        ;;
    *)
        echo "Error: La acción '$ACCION' no es válida."
        mostrar_uso
        exit 1
        ;;
esac
