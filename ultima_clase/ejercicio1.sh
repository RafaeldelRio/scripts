#!/bin/bash

# Esto no sé si os lo contarán positivamente en el examen, 
# pero es una buena práctica para evitar errores tontos.
set -euo pipefail

# Algunas constantes para el resto del script.
FECHA=$(date +"%Y%m%d")
BACKUP_FILE="/tmp/backup_logs_${FECHA}.tar.gz"
INFORME_FILE="informe_usuarios.txt"


# Comprobar privilegios: esto es típico de muchos ejercicios.
comprobar_root() {
    if (( EUID != 0 )); then
        echo "Error: Este script debe ejecutarse obligatoriamente como root." >&2
        exit 1
    fi
}

# Mostrar ayuda en caso de error.
mostrar_uso() {
    echo "Uso: $0 [-u] <directorio_logs>" >&2
    exit 1
}

# Primera parte, que se realiza siempre: Procesar logs
procesar_logs() {
    local dir="$1"
    echo "Auditando logs en: $dir"

    # Buscar ficheros .log y contar cuántos hay (silenciando errores de permisos)
    local num_logs
    num_logs=$(find "$dir" -type f -name "*.log" 2>/dev/null | wc -l)

    if (( num_logs == 0 )); then
        echo "Información: No se encontraron ficheros .log en el directorio especificado."
        return 0
    fi

    echo "Se han encontrado $num_logs ficheros .log. Procediendo al backup..."

    # Comprimir usando find + tar para evitar problemas si hay muchísimos archivos
    # El print0 evita que se rompa con nombres raros, como nombre\n.log.
    # El --null de tar es la pareja de print0 de find, para que se entiendan correctamente.
    # El -T - le dice a tar que lea la lista de archivos a comprimir desde stdin.
    if find "$dir" -type f -name "*.log" -print0 2>/dev/null | tar --null -czf "$BACKUP_FILE" -T - 2>/dev/null; then
        echo "Backup creado con éxito en: $BACKUP_FILE"
        
        # Vaciar los archivos originales sin borrarlos (truncate a 0 bytes)
        # En el while ponemos -r para evitar problemas con espacios o caracteres especiales en los nombres.
        # En el while ponemos -d '' para que el delimitador sea el null byte, que es lo que produce -print0 de find.
        find "$dir" -type f -name "*.log" -print0 2>/dev/null | while IFS= read -r -d '' archivo; do
            > "$archivo"
        done
        echo "Los ficheros .log originales han sido vaciados."
    else
        echo "Error: Fallo al crear el archivo comprimido." >&2
        exit 1
    fi
}

# Vamos con la siguiente tarea, la que solo se hace si se pasa la opción -u
auditar_usuarios() {
    echo "Iniciando auditoría de usuarios..."
    
    # Vaciar o crear el fichero de informe antes de empezar
    > "$INFORME_FILE"

    # Leer /etc/passwd separando por ":"
    # No nos interesa el campo de contraseña (el segundo), ni el GID (el cuarto), ni la descripción (el quinto).
    while IFS=: read -r usuario _ uid _ _ home shell; do
        # Filtrar UID >= 1000 y shell interactiva (ej. /bin/bash o /bin/zsh)
        if (( uid >= 1000 )) && [[ "$shell" == *bash || "$shell" == *zsh ]]; then
            echo "[OK] - El usuario $usuario tiene UID $uid y su directorio personal es $home" >> "$INFORME_FILE"
        fi
    done < /etc/passwd

    echo "Auditoría completada. Resultados guardados en: $INFORME_FILE"
}

# Vamos a pasar a la parte del main, por así decirlo, del script.

# Comprobar root
comprobar_root

# Variables iniciales
FLAG_USUARIOS=0
DIRECTORIO=""

# Lógica basada estrictamente en la cantidad de argumentos ($#)
# Es la forma más sencilla que se me ocurre, pero no cubre todos los casos raros.
if [[ $# -eq 1 ]]; then
    # Si solo hay un argumento. Asumimos que es el directorio.
    # Pequeña validación defensiva por si el usuario pone el flag pero olvida la ruta
    if [[ "$1" == "-u" ]]; then
        echo "Error: Has puesto el flag -u pero falta el directorio." >&2
        mostrar_uso
    fi
    
    DIRECTORIO="$1"

elif [[ $# -eq 2 ]]; then
    # Si hay dos argumentos. Uno debe ser el flag y el otro el directorio.
    
    if [[ "$1" == "-u" ]]; then
        # El usuario escribió: ./sys_audit.sh -u /var/log
        FLAG_USUARIOS=1
        DIRECTORIO="$2"
        
    elif [[ "$2" == "-u" ]]; then
        # El usuario lo escribió al revés: ./sys_audit.sh /var/log -u
        FLAG_USUARIOS=1
        DIRECTORIO="$1"
        
    else
        # Puso dos cosas, pero ninguna era '-u'
        echo "Error: Opciones no reconocidas. Usa '-u'." >&2
        mostrar_uso
    fi

else
    # Si hayy 0 argumentos, o hay 3 o más sí lanzamos error.
    echo "Error: Número incorrecto de argumentos." >&2
    mostrar_uso
fi

# Validar que el argumento es un directorio real
if [[ ! -d "$DIRECTORIO" ]]; then
    echo "Error: '$DIRECTORIO' no es un directorio válido o no existe." >&2
    mostrar_uso
fi

# Ejecutar tareas
procesar_logs "$DIRECTORIO"

if (( FLAG_USUARIOS == 1 )); then
    echo "----------------------------------------"
    auditar_usuarios
fi

echo "Proceso finalizado correctamente."
exit 0