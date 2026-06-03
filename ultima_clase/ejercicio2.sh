#!/bin/bash

# Antes hemos usado el set -euo pipefail en el ejercicio anterior, 
# pero en este caso no lo vamos a usar. Esto se debe a que
# en scripts interactivos con menús si un comando falla (ej: un ping que no responde), 
# nos echaría del script por completo en lugar de volver al menú.


# Validar IP SIN Expresiones Regulares. 
# Lo prefiero ya que va a ser más fácil que lo recordéis así a un regex
# que en el examen con los nervios se puede olvidar.
validar_ip() {
    local ip="$1"
    # Preparamos el read para separar la IP por puntos y guardarla en un array.
    local IFS='.'
    local -a octetos
    
    # Separamos la IP por puntos y la guardamos en un array 
    read -r -a octetos <<< "$ip"

    # 1. ¿Tiene exactamente 4 bloques?
    if (( ${#octetos[@]} != 4 )); then
        # Detalle importante: devolvemos un return 1 en lugar de un exit 
        # porque queremos que el script siga funcionando y vuelva al menú,
        # no que se cierre por completo.
        return 1 # Falso
    fi

    # 2. Comprobar cada bloque individualmente
    for octeto in "${octetos[@]}"; do
        # Verificar que no esté vacío
        if [[ -z "$octeto" ]]; then return 1; fi
        
        # Verificar que solo contenga números usando expansión de Bash (no regex)
        # El patrón *[^0-9]* significa: "Cualquier cosa, seguida de algo que NO sea un número, seguida de cualquier cosa"
        if [[ "$octeto" == *[^0-9]* ]]; then return 1; fi
        
        # Verificar que esté entre 0 y 255
        if (( octeto < 0 || octeto > 255 )); then return 1; fi
    done

    return 0 # Verdadero
}

# Opción 1: Escaneo de red
escaneo_rapido() {
    echo "--- ESCANEO DE SUBRED ---"
    read -r -p "Introduce la IP de la red: " ip_input

    if ! validar_ip "$ip_input"; then
        echo "Error: La IP '$ip_input' no tiene un formato válido." >&2
        return # Volvemos al menú
    fi

    # Recortar la IP para sacar la base
    # Ejemplo: de 192.168.100.45 quita desde el último punto hacia la derecha -> 192.168.100
    local base_red="${ip_input%.*}"

    echo "Escaneando las 5 primeras IPs de la subred ${base_red}.0/24..."
    
    # Bucle for para lanzar los 5 pings
    for i in {1..5}; do
        local ip_objetivo="${base_red}.$i"
        
        # Ping de 1 paquete (-c 1), espera máxima 1 seg (-W 1)
        if ping -c 1 -W 1 "$ip_objetivo" &>/dev/null; then
            echo "$ip_objetivo - ACTIVA"
        else
            echo "$ip_objetivo - INACTIVA"
        fi
    done
}

# Opción 2: Crear perfil
crear_perfil() {
    echo "--- CREAR PERFIL DE EQUIPO ---"
    
    local intentos=0
    local hostname=""

    # Bucle de reintentos para el nombre
    while (( intentos < 3 )); do
        read -r -p "Nombre del equipo: " hostname
        
        if [[ -n "$hostname" ]]; then
            break # Si no está vacío, rompemos el bucle y avanzamos
        fi
        
        (( intentos++ ))
        echo "Error: El nombre no puede estar vacío. Intento $intentos de 3." >&2
    done

    # Si salimos del bucle y sigue vacío, es que gastó los 3 intentos
    if [[ -z "$hostname" ]]; then
        echo "Operación cancelada por límite de intentos." >&2
        return
    fi

    # Pedir contraseñas de forma segura
    local pass1 pass2
    read -r -s -p "Introduce contraseña de administrador: " pass1; echo
    read -r -s -p "Confirma la contraseña: " pass2; echo

    if [[ "$pass1" != "$pass2" ]]; then
        echo "Error: Las contraseñas no coinciden. Abortando." >&2
        return
    fi

    # Manipulación: Pasar a mayúsculas (Patrón 9)
    local host_mayus="${hostname^^}"
    local archivo="perfil_${host_mayus}.conf"

    # Generar el fichero
    echo "HOSTNAME=$host_mayus" > "$archivo"
    echo "STATUS=GENERADO" >> "$archivo"
    
    echo "Perfil guardado en el archivo: $archivo"
}

# ==========================================
# FLUJO PRINCIPAL: MENÚ INTERACTIVO
# ==========================================

while true; do
    echo ""
    echo "====================================="
    echo "  HERRAMIENTA DE DIAGNÓSTICO DE RED  "
    echo "====================================="
    echo "1) Escaneo rápido de subred"
    echo "2) Crear perfil seguro de equipo"
    echo "3) Salir"
    echo "====================================="
    
    read -r -p "Elige una opción (1-3): " opcion
    echo ""

    case "$opcion" in
        1) escaneo_rapido ;;
        2) crear_perfil ;;
        3) 
            echo "Saliendo del sistema..."
            exit 0 
            ;;
        *) 
            echo "Opción no válida. Por favor, introduce 1, 2 o 3." >&2 
            ;;
    esac
done