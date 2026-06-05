#!/bin/bash

# Archivos de registro (Logs)
LOG_ERRORES="errores.log"
LOG_CREADOS="creados.log"
PASS_DEFAULT="Temporal123"

# Repasamos una vez más cómo se comprueba que el script se ejecute como root
if (( EUID != 0 )); then
    echo "Error: Este script debe ejecutarse obligatoriamente como root." >&2
    exit 1
fi

# Repasamos la comprobación del número exacto de argumentos
if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero_rrhh.txt>" >&2
    exit 1
fi

FICHERO_RRHH="$1"

# Si solo queremos comprobar la existencia, podríamos usar -f, pero -r es más completo porque también verifica que el script pueda leerlo.
if [[ ! -r "$FICHERO_RRHH" ]]; then
    echo "Error: El fichero '$FICHERO_RRHH' no existe o no se puede leer." >&2
    exit 1
fi

# Aquí vamos a ver cómo se cifrar la contraseña por defecto UNA sola vez.
# Usamos -6 para indicar que queremos cifrado SHA-512 (el estándar actual de Linux)
PASS_CIFRADA=$(openssl passwd -6 "$PASS_DEFAULT")

echo "Iniciando aprovisionamiento masivo desde: $FICHERO_RRHH..."


# Bucle while read leyendo desde el fichero
# El || [[ -n "$usuario" ]] evita que se ignore la última línea si el archivo no acaba en salto de línea (Enter)
while IFS=: read -r usuario nombre_real departamento || [[ -n "$usuario" ]]; do
    
    # Validación defensiva: saltar líneas vacías o mal formadas
    if [[ -z "$usuario" || -z "$nombre_real" || -z "$departamento" ]]; then
        continue
    fi

    # Comprobar si el usuario YA existe en el sistema
    if id "$usuario" &>/dev/null; then
        echo "[ERROR] El usuario $usuario ya existe en el sistema." >> "$LOG_ERRORES"
    else
        # El comando useradd a veces falla si la carpeta padre no existe.
        # Creamos la carpeta del departamento previamente por seguridad.
        mkdir -p "/home/$departamento"

        # Crear el usuario con todos los flags solicitados
        # -m: Crea el home
        # -d: Ruta del home
        # -c: GECOS (Nombre real)
        # -s: Shell interactiva
        # -p: Contraseña ya cifrada
        if useradd -m -d "/home/$departamento/$usuario" -c "$nombre_real" -s "/bin/bash" -p "$PASS_CIFRADA" "$usuario" 2>/dev/null; then
            echo "[OK] Usuario $usuario creado en el departamento de $departamento." >> "$LOG_CREADOS"
        else
            echo "[ERROR] Fallo inesperado al intentar crear el usuario $usuario." >> "$LOG_ERRORES"
        fi
    fi

done < "$FICHERO_RRHH"

echo "Proceso finalizado. Revisa $LOG_CREADOS y $LOG_ERRORES para más detalles."
exit 0