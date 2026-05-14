#!/bin/bash

: <<"FIN"
Realizar un script llamado copiaSeg.sh para gestionar el sistema centralizado de copias de seguridad de un servidor.
El script sin parámetros hará una copia de seguridad de todos los usuarios del sistema, y con el parámerto -u usuario
hará una copia de seguridad de la información del usuario pasado como parámetro. Este script solo podrá ser ejecutado
por root. La sintaxis del script será:
    copiaSeg.sh [-u usuario]

Los usuarios podrán utilizar el sistema de copias automatizado creando en su directorio de trabajo un fichero oculto,
llamado copiaSeg.dat, con el siguiente contenido:
    # Copias que se desean mantener
    numeroCopias=2
    # Contenido de la copia, único obligatorio
    contenidoCopia=dir1:dir2:fichero1:fichero2

En caso de que no exista alguno de los campos configurables anteriores, se usarán los valores por defecto, definidos en
el propio script. El único campo obligatorio es el campo contenidoCopia, que contendrá todos los ficheros y directorios
que se desean incluir en ka copia. Si dicho campo no estuviese definido no se copiaría nada para ese usuario.

El sistema creará un directorio /copiaSeg y dentro un directorio por usuario, si no existiese, que solo podrá ser accesible por su dueño.
En el interior de este directorio se almacenarán tantas copias de seguridad copiaSeg_hhmmDDMMYYYY.tgz como defina numeroCopias.
Para que un fichero o directorio sea añadido a la copia debe ser de su propiedad.

El script borrará las copias más antiguas manteniendo en el sistema solo las que se indiquen en el fichero de configuración
copiaSeg.dat y, si no está definido numeroCopias, lo que marque el valor por defecto.
FIN

#!/bin/bash

# Comprobar que el script se ejecuta como root
if (( "$EUID" != 0 )); then
    echo "Error: Este script debe ser ejecutado por root."
    exit 1
fi


# Variables globales
BASE_DIR="/copiaSeg"
VALOR_DEFECTO_COPIAS=3

# Variables para lectura de configuración
CFG_NUM_COPIAS=""
CFG_CONTENIDO_COPIA=""

# Crear el directorio base si no existe (silenciosamente)
if [[ ! -d "$BASE_DIR" ]]; then
    mkdir -p "$BASE_DIR" 2>/dev/null
    chmod 755 "$BASE_DIR" 2>/dev/null
fi

# Lee .copiaSeg.dat y carga valores en variables globales de configuración
leer_config_usuario() {
    local config_file="$1"
    local clave
    local valor

    CFG_NUM_COPIAS=""
    CFG_CONTENIDO_COPIA=""

    while IFS='=' read -r clave valor; do
        clave=$(echo "$clave" | tr -d '[:space:]')

        [[ -z "$clave" ]] && continue
        [[ "$clave" == \#* ]] && continue

        case "$clave" in
            numeroCopias)
                CFG_NUM_COPIAS=$(echo "$valor" | tr -d '[:space:]')
                ;;
            contenidoCopia)
                CFG_CONTENIDO_COPIA=$(echo "$valor" | tr -d ' ')
                ;;
        esac
    done < "$config_file"
}

# Función que realiza la copia de seguridad para un usuario específico
realizar_copia() {
    local u="$1"

    # Obtener el directorio de trabajo (home) del usuario
    local home_dir
    home_dir=$(getent passwd "$u" | cut -d: -f6)

    # Si no tiene home o el usuario no existe, salimos de la función
    if [[ -z "$home_dir" ]] || [[ ! -d "$home_dir" ]]; then
        return
    fi

    # Dice el enunciado que es un archivo oculto, por eso le pongo el punto delante. Si no existiese, se omite el usuario.
    local config_file="$home_dir/.copiaSeg.dat"

    # Comprobar si existe el fichero de configuración oculto
    if [[ ! -f "$config_file" ]]; then
        return
    fi

    # Extraer variables del fichero de configuración
    leer_config_usuario "$config_file"
    local num_copias="$CFG_NUM_COPIAS"
    local contenido_copia="$CFG_CONTENIDO_COPIA"

    # Aplicar valores por defecto si no existen
    if [[ -z "$num_copias" ]] || ! [[ "$num_copias" =~ ^[0-9]+$ ]]; then
        num_copias=$VALOR_DEFECTO_COPIAS
    fi

    # Si no hay contenido definido, se omite el usuario
    if [[ -z "$contenido_copia" ]]; then
        return
    fi

    # Preparar el directorio de destino
    local dest_dir="$BASE_DIR/$u"
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" 2>/dev/null
        # Asegurar que solo es accesible por el dueño
        chown "$u":"$u" "$dest_dir" 2>/dev/null
        chmod 700 "$dest_dir" 2>/dev/null
    fi

    # Convertir el contenido separado por ':' en un array
    IFS=':' read -r -a elementos <<< "$contenido_copia"
    local elementos_validos=()

    # Validar que los ficheros existen y pertenecen al usuario
    for item in "${elementos[@]}"; do
        local ruta_absoluta
        local ruta_relativa

        # Permite rutas relativas (dir1:fichero) y absolutas (/home/usuario/dir1)
        if [[ "$item" = /* ]]; then
            ruta_absoluta="$item"
        else
            ruta_absoluta="$home_dir/$item"
        fi

        # Verificar que el fichero/directorio exista
        if [[ -e "$ruta_absoluta" ]]; then
            # Verificar si el propietario es el usuario
            local propietario
            propietario=$(stat -c "%U" "$ruta_absoluta" 2>/dev/null)
            if [[ "$propietario" = "$u" ]]; then
                # Guardamos solo rutas dentro del home para empaquetar con -C "$home_dir"
                if [[ "$ruta_absoluta" == "$home_dir"/* ]]; then
                    ruta_relativa="${ruta_absoluta#"$home_dir"/}"
                    elementos_validos+=("$ruta_relativa")
                fi
            fi
        fi
    done

    # Si hay elementos válidos para copiar, creamos el archivo
    if [[ ${#elementos_validos[@]} -gt 0 ]]; then
        # Formato de fecha: hhmmDDMMYYYY -> %H%M%d%m%Y
        local fecha
        fecha=$(date +"%H%M%d%m%Y" 2>/dev/null)
        local nombre_archivo="copiaSeg_$fecha.tgz"
        local archivo_destino="$dest_dir/$nombre_archivo"

        # Empaquetar situándonos en el home del usuario
        tar -czf "$archivo_destino" -C "$home_dir" "${elementos_validos[@]}" 2>/dev/null
        chown "$u":"$u" "$archivo_destino" 2>/dev/null
    fi

    # --- ROTACIÓN DE COPIAS DE SEGURIDAD ---
    # Listamos las copias ordenadas de más antiguas a más recientes (tr = time reverse)
    local copias_existentes
    copias_existentes=($(ls -1tr "$dest_dir"/copiaSeg_*.tgz 2>/dev/null))
    local total_existentes=${#copias_existentes[@]}

    # Si hay más copias de las permitidas, borramos las sobrantes (las más antiguas)
    if [[ "$total_existentes" -gt "$num_copias" ]]; then
        local num_a_borrar=$((total_existentes - num_copias))
        for (( i=0; i<num_a_borrar; i++ )); do
            rm -f "${copias_existentes[$i]}" 2>/dev/null
        done
    fi
}

# --- LÓGICA PRINCIPAL Y PARÁMETROS ---
if [[ "$#" -eq 0 ]]; then
    # Opción 1: Sin parámetros (se procesan todos los usuarios de sistema UID >= 1000)
    for user in $(cut -d: -f1 /etc/passwd 2>/dev/null); do
        uid_usuario=$(id -u "$user" 2>/dev/null)
        if [[ "$uid_usuario" -ge 1000 ]] && [[ "$uid_usuario" -ne 65534 ]]; then
            realizar_copia "$user"
        fi
    done
    echo "Proceso de copias masivas finalizado."

elif [[ "$1" = "-u" ]] && [[ -n "$2" ]]; then
    # Opción 2: Parámetro -u con nombre de usuario
    if id "$2" >/dev/null 2>&1; then
        realizar_copia "$2"
        echo "Copia finalizada para el usuario '$2'."
    else
        echo "Error: El usuario '$2' no existe."
    fi

else
    # Opción 3: Error de sintaxis
    echo "Error de sintaxis."
    echo "Uso: $0 [-u usuario]"
    exit 1
fi

exit 0
