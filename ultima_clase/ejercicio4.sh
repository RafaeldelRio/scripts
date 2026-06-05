#!/bin/bash

BACKUP_DIR="/var/backups/profiles"
FECHA=$(date +"%Y%m%d")

# Esto se ha visto ya en un ejercicio anterior.
# Simplemente sirve para encapsular una serie de "echo".
mostrar_ayuda() {
    echo "Uso: $0 <opción> <argumento>"
    echo "Opciones:"
    echo "  -b <usuario>   Crear copia de seguridad del usuario"
    echo "  -r <archivo>   Restaurar copia de seguridad desde archivo"
    echo "  -l <usuario>   Listar copias de seguridad de un usuario"
    exit 1
}

# Comprobar privilegios
if (( EUID != 0 )); then
    echo "Error: Se requieren privilegios de root para esta operación." >&2
    exit 1
fi

# Crear directorio maestro si no existe
mkdir -p "$BACKUP_DIR"

# Validar exactamente 2 argumentos
if [[ $# -ne 2 ]]; then
    mostrar_ayuda
fi



case "$1" in
    -b)
        USUARIO="$2"
        
        # Verificar si el usuario existe
        if ! id "$USUARIO" &>/dev/null; then
            echo "Error: El usuario '$USUARIO' no existe en el sistema." >&2
            exit 1
        fi
        
        # Obtener el HOME real leyendo /etc/passwd
        HOME_DIR=$(getent passwd "$USUARIO" | cut -d: -f6)
        ARCHIVO_DESTINO="${BACKUP_DIR}/${USUARIO}_${FECHA}.tar.gz"
        
        echo "Creando backup de $HOME_DIR..."
        
        # Uso avanzado de tar: -C cambia el directorio de trabajo antes de comprimir
        if tar -czf "$ARCHIVO_DESTINO" -C "$(dirname "$HOME_DIR")" "$(basename "$HOME_DIR")" 2>/dev/null; then
            # Opcional de calidad: Generar hash MD5
            md5sum "$ARCHIVO_DESTINO" > "${ARCHIVO_DESTINO}.md5"
            echo "[OK] Backup guardado en: $ARCHIVO_DESTINO"
        else
            echo "[ERROR] Fallo al crear el backup." >&2
            exit 1
        fi
        ;;
        
    -r)
        ARCHIVO_BACKUP="$2"
        
        # Validar que el archivo existe y es regular
        if [[ ! -f "$ARCHIVO_BACKUP" ]]; then
            echo "Error: El archivo '$ARCHIVO_BACKUP' no existe o no es válido." >&2
            exit 1
        fi
        
        # Aquí vamos a hacer uso de la manipulación de cadenas. Es lo más interesante del ejercicio.

        # 1. Quitar la ruta (Ej: /tmp/jgarcia_2023.tar.gz -> jgarcia_2023.tar.gz)
        # ${var##*/} significa: elimina el trozo más largo desde el principio que acabe en /
        NOMBRE_ARCHIVO="${ARCHIVO_BACKUP##*/}"
        
        # 2. Extraer el usuario (Ej: jgarcia_2023.tar.gz -> jgarcia)
        # ${var%%_*} significa: elimina el trozo más largo desde el final que empiece por _
        USUARIO_DEDUCIDO="${NOMBRE_ARCHIVO%%_*}"
        
        echo "-> Archivo detectado para el usuario: $USUARIO_DEDUCIDO"
        
        if ! id "$USUARIO_DEDUCIDO" &>/dev/null; then
            echo "Error: El usuario '$USUARIO_DEDUCIDO' no existe actualmente." >&2
            exit 1
        fi
        
        HOME_DIR=$(getent passwd "$USUARIO_DEDUCIDO" | cut -d: -f6)
        
        echo "-> Vaciando el directorio actual: $HOME_DIR..."
        # Borrado seguro: find vacía el contenido sin borrar el directorio maestro
        # Ojo con este comando que borra mucho si se le da la ruta equivocada. 
        # Siempre es buena idea imprimir el comando antes de ejecutarlo para verificar que es correcto.
        # find "$HOME_DIR" -mindepth 1 -delete
        # Lo dejo comentado y pongo uno sin borrar por si acaso se hacen pruebas.
        find "$HOME_DIR" -mindepth 1
        
        echo "-> Restaurando copia de seguridad..."
        if tar -xzf "$ARCHIVO_BACKUP" -C "$(dirname "$HOME_DIR")" 2>/dev/null; then
            echo "[OK] Perfil restaurado correctamente."
        else
            echo "[ERROR] Problemas al extraer el archivo." >&2
            exit 1
        fi
        ;;
        
    -l)
        USUARIO_BUSCADO="$2"
        ENCONTRADOS=0
        
        echo "Buscando backups para: $USUARIO_BUSCADO..."
        echo "----------------------------------------"
        
        # Iterar sobre ficheros del directorio
        shopt -s nullglob # Evita que el bucle falle si la carpeta está vacía
        for file in "$BACKUP_DIR"/*; do
            if [[ -f "$file" ]]; then
                # Manipulación de cadenas para extraer el dueño del archivo evaluado
                NOMBRE_ARCHIVO="${file##*/}"
                DUEÑO="${NOMBRE_ARCHIVO%%_*}"
                
                # Si el dueño coincide y es un .tar.gz, lo listamos
                if [[ "$DUEÑO" == "$USUARIO_BUSCADO" && "$NOMBRE_ARCHIVO" == *.tar.gz ]]; then
                    echo "- $NOMBRE_ARCHIVO"
                    (( ENCONTRADOS++ ))
                fi
            fi
        done
        shopt -u nullglob
        
        if (( ENCONTRADOS == 0 )); then
            echo "No hay copias disponibles."
        fi
        ;;
        
    *)
        echo "Error: Opción '$1' no válida." >&2
        mostrar_ayuda
        ;;
esac

exit 0