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
if [ "$EUID" -ne 0 ]; then
    echo "Error: Este script debe ser ejecutado por root."
    exit 1
fi

# Variables globales
BASE_DIR="/copiaSeg"
VALOR_DEFECTO_COPIAS=3

# Crear el directorio base si no existe (silenciosamente)
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR" 2>/dev/null
    chmod 755 "$BASE_DIR" 2>/dev/null
fi

# Función que realiza la copia de seguridad para un usuario específico
realizar_copia() {
    local u="$1"

    # Obtener el directorio de trabajo (home) del usuario
    local home_dir
    home_dir=$(awk -v usr="$u" -F: '$1 == usr {print $6}' /etc/passwd 2>/dev/null)

    # Si no tiene home o el usuario no existe, salimos de la función
    if [ -z "$home_dir" ] || [ ! -d "$home_dir" ]; then
        return
    fi

    local config_file="$home_dir/.copiaSeg.dat"

    # Comprobar si existe el fichero de configuración oculto
    if [ ! -f "$config_file" ]; then
        return
    fi

    # Extraer variables del fichero de configuración (ignorando espacios alrededor del =)
    local num_copias
    local contenido_copia
    num_copias=$(grep -E "^[[:space:]]*numeroCopias[[:space:]]*=" "$config_file" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    contenido_copia=$(grep -E "^[[:space:]]*contenidoCopia[[:space:]]*=" "$config_file" 2>/dev/null | cut -d= -f2 | tr -d ' ')

    # Aplicar valores por defecto si no existen
    if [ -z "$num_copias" ] || ! [[ "$num_copias" =~ ^[0-9]+$ ]]; then
        num_copias=$VALOR_DEFECTO_COPIAS
    fi

    # Si no hay contenido definido, se omite el usuario
    if [ -z "$contenido_copia" ]; then
        return
    fi

    # Preparar el directorio de destino
    local dest_dir="$BASE_DIR/$u"
    if [ ! -d "$dest_dir" ]; then
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
        local ruta_absoluta="$home_dir/$item"

        # Verificar que el fichero/directorio exista
        if [ -e "$ruta_absoluta" ]; then
            # Verificar si el propietario es el usuario
            local propietario
            propietario=$(stat -c "%U" "$ruta_absoluta" 2>/dev/null)
            if [ "$propietario" = "$u" ]; then
                # Guardamos solo el nombre relativo para que el tar lo empaquete limpiamente
                elementos_validos+=("$item")
            fi
        fi
    done

    # Si hay elementos válidos para copiar, creamos el archivo
    if [ ${#elementos_validos[@]} -gt 0 ]; then
        # Formato de fecha: hhmmDDMMYYYY -> %H%M%d%m%Y
        local fecha
        fecha=$(date +"%H%M%d%m%Y" 2>/dev/null)
        local nombre_archivo="copiaSeg_$fecha.tgz"

        # Empaquetar situándonos en el home del usuario
        tar -czf "$dest_dir/$nombre_archivo" -C "$home_dir" "${elementos_validos[@]}" 2>/dev/null
    fi

    # --- ROTACIÓN DE COPIAS DE SEGURIDAD ---
    # Listamos las copias ordenadas de más antiguas a más recientes (tr = time reverse)
    local copias_existentes
    copias_existentes=($(ls -1tr "$dest_dir"/copiaSeg_*.tgz 2>/dev/null))
    local total_existentes=${#copias_existentes[@]}

    # Si hay más copias de las permitidas, borramos las sobrantes (las más antiguas)
    if [ "$total_existentes" -gt "$num_copias" ]; then
        local num_a_borrar=$((total_existentes - num_copias))
        for (( i=0; i<num_a_borrar; i++ )); do
            rm -f "${copias_existentes[$i]}" 2>/dev/null
        done
    fi
}

# --- LÓGICA PRINCIPAL Y PARÁMETROS ---
if [ "$#" -eq 0 ]; then
    # Opción 1: Sin parámetros (se procesan todos los usuarios de sistema UID >= 1000)
    usuarios=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd 2>/dev/null)
    for user in $usuarios; do
        realizar_copia "$user"
    done
    echo "Proceso de copias masivas finalizado."

elif [ "$1" = "-u" ] && [ -n "$2" ]; then
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
