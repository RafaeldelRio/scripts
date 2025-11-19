#!/bin/bash

: <<"FIN"
Programe un script llamado 'estadística_dir' que realice un estudio de todo el árbol de
directorios y ficheros partiendo del directorio pasado como parámetro de forma que obtenga-
mos la siguiente información:
- Número de ficheros en los cuales:
- Número disponemos de permiso de lectura.
- Número disponemos de permiso de escritura.
- Número disponemos de permiso de ejecución.
- Número carecemos de permiso de lectura.
- Número carecemos de permiso de escritura.
- Número carecemos de permiso de ejecución.
- Número de ficheros regulares encontrados.
- Número de directorios encontrados.
- Número de dispositivos de bloques encontrados.
- Número de dispositivos de caracteres encontrados.
- Número de fifos encontrados.
FIN

# Validar que se pase un parámetro
if [[ $# -ne 1 ]]; then
    echo "Error: Debe proporcionar un directorio como parámetro"
    echo "Uso: $0 <directorio>"
    exit 1
fi

# Validar que el parámetro sea un directorio válido
if [[ ! -d "$1" ]]; then
    echo "Error: '$1' no es un directorio válido"
    exit 1
fi

# Inicializar contadores
con_lectura=0
con_escritura=0
con_ejecucion=0
sin_lectura=0
sin_escritura=0
sin_ejecucion=0
ficheros_regulares=0
directorios=0
dispositivos_bloques=0
dispositivos_caracteres=0
fifos=0

# Función para analizar el árbol de directorios
analizar_directorio() {
    local dir="$1"
    
    # Recorrer todos los elementos del directorio
    for elemento in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
        # Verificar que el elemento existe (evitar errores con patrones sin coincidencias)
        [[ -e "$elemento" || -L "$elemento" ]] || continue
        
        # Contar permisos
        if [[ -r "$elemento" ]]; then
            ((con_lectura++))
        else
            ((sin_lectura++))
        fi
        
        if [[ -w "$elemento" ]]; then
            ((con_escritura++))
        else
            ((sin_escritura++))
        fi
        
        if [[ -x "$elemento" ]]; then
            ((con_ejecucion++))
        else
            ((sin_ejecucion++))
        fi
        
        # Contar tipos de archivos
        if [[ -f "$elemento" ]]; then
            ((ficheros_regulares++))
        elif [[ -d "$elemento" ]]; then
            ((directorios++))
            # Llamada recursiva para subdirectorios
            analizar_directorio "$elemento"
        elif [[ -b "$elemento" ]]; then
            ((dispositivos_bloques++))
        elif [[ -c "$elemento" ]]; then
            ((dispositivos_caracteres++))
        elif [[ -p "$elemento" ]]; then
            ((fifos++))
        fi
    done
}

# Ejecutar el análisis
echo "Analizando el directorio: $1"
echo "=========================================="
analizar_directorio "$1"

# Mostrar resultados
cat << EOF
ESTADÍSTICAS DE PERMISOS:
-------------------------
Ficheros con permiso de lectura:    $con_lectura
Ficheros con permiso de escritura:  $con_escritura
Ficheros con permiso de ejecución:  $con_ejecucion
Ficheros sin permiso de lectura:    $sin_lectura
Ficheros sin permiso de escritura:  $sin_escritura
Ficheros sin permiso de ejecución:  $sin_ejecucion

ESTADÍSTICAS DE TIPOS DE ARCHIVOS:
-----------------------------------
Ficheros regulares:                 $ficheros_regulares
Directorios:                        $directorios
Dispositivos de bloques:            $dispositivos_bloques
Dispositivos de caracteres:         $dispositivos_caracteres
FIFOs (named pipes):                $fifos

Total de elementos analizados:      $((con_lectura + sin_lectura))
EOF
