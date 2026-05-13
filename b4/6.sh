#!/bin/bash

: <<"FIN"
Realizar un script que almacene los scripts realizados por los alumnos (UID entre 2000 y 2100) y genere un informe.
Para que los scripts sean procesados, los alumnos deben añadir obligatoriamente la siguiente información (si un script
no tuviera esta información no sería procesado).
        #!shell utilizada
        #Tema:7
        #Ejercicio:3
        #Autores:usuario1 usuario2
        resto del script

Los scripts de los alumnos se pueden encontrar en todo el árbol de directorios, pueden utilizar cualquier shell existente
en el sistema y pueden haber sido realizados individualmente o en grupo, en cuyo caso, los usuarios de los alumnos del
grupo se separarán por espacios.

La sintaxis deberá ser: recopilaScripts.sh directorios

El script recopilaScripts.sh solo podrá ser ejecutado por root y admitirá como parámetro obligatorio el directorio donde se desee
almacenar los informes (este directorio no será procesado).
En caso de que existan dos scripts para el mismo ejercicio se procesará el más reciente, generándose un informe para cada usuario
que se almacenará en directorio.

El informe tendrá la siguiente información:
############################################################################
# Nombre del script: ordena.sh
# Autor/es: Nombre Apellido1 Apellido2
# Coautores: Nombre Apellido1 Apellido2
# Shell:/bin/bash
# Tema:3 Ejercicio:22
# Posible Copia de: user3,user4... no se tendrá en cuenta los coautores.
###########################################################################
Contenido del script sin comentarios
FIN


# Comprobar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Este script debe ser ejecutado exclusivamente por root."
    exit 1
fi

# Comprobar número de parámetros
if [ "$#" -ne 1 ]; then
    echo "Sintaxis: $0 <directorio>"
    exit 1
fi

DEST_DIR="$1"

# Crear el directorio destino si no existe de forma silenciosa
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR" 2>/dev/null
fi

# Convertir la ruta a absoluta para que el find pueda excluirla correctamente
DEST_DIR=$(realpath "$DEST_DIR" 2>/dev/null)

# Limpiar informes de ejecuciones anteriores para evitar duplicados
rm -f "$DEST_DIR"/informe_*.txt 2>/dev/null

# Arrays asociativos para gestionar la lógica en memoria eficientemente
declare -A best_file
declare -A best_time
declare -A script_hash
declare -A script_autores
declare -A script_shell
declare -A script_tema
declare -A script_ejercicio

echo "Buscando scripts de alumnos y procesando (puede tardar unos segundos)..."

# Buscar ficheros pertenecientes a usuarios con UID entre 2000 y 2100, excluyendo el directorio destino
while IFS= read -r -d '' f; do

    # 1. Comprobar la primera línea (Shebang)
    shell_val=$(head -n 1 "$f" 2>/dev/null | sed -n 's/^#!//p')
    if [ -z "$shell_val" ]; then continue; fi

    # 2. Extraer Tema, Ejercicio y Autores asegurando que existan
    # Se eliminan los espacios en blanco para estandarizar
    tema_val=$(grep -iE '^[[:space:]]*#Tema:[[:space:]]*[0-9]+' "$f" 2>/dev/null | head -n 1 | cut -d: -f2 | tr -d ' ')
    if [ -z "$tema_val" ]; then continue; fi

    ej_val=$(grep -iE '^[[:space:]]*#Ejercicio:[[:space:]]*[0-9]+' "$f" 2>/dev/null | head -n 1 | cut -d: -f2 | tr -d ' ')
    if [ -z "$ej_val" ]; then continue; fi

    autores_val=$(grep -iE '^[[:space:]]*#Autores:' "$f" 2>/dev/null | head -n 1 | cut -d: -f2-)
    if [ -z "$autores_val" ]; then continue; fi

    # Si llega hasta aquí, el script tiene las cabeceras obligatorias válidas
    mtime=$(stat -c %Y "$f" 2>/dev/null)

    # Calcular el hash (huella digital) del script ignorando líneas vacías y comentarios (para detectar copias)
    if [ -z "${script_hash[$f]}" ]; then
        script_hash[$f]=$(grep -v '^[[:space:]]*#' "$f" 2>/dev/null | grep -v '^[[:space:]]*$' | md5sum | awk '{print $1}')
        script_autores[$f]=$autores_val
        script_shell[$f]=$shell_val
        script_tema[$f]=$tema_val
        script_ejercicio[$f]=$ej_val
    fi

    # Registrar el archivo más reciente para cada autor en ese tema y ejercicio
    for u in $autores_val; do
        key="${u}_${tema_val}_${ej_val}"
        if [[ -z "${best_time[$key]}" ]] || [[ "$mtime" -gt "${best_time[$key]}" ]]; then
            best_time[$key]=$mtime
            best_file[$key]=$f
        fi
    done

done < <(find / -path "$DEST_DIR" -prune -o -uid +1999 -uid -2101 -type f -print0 2>/dev/null)


# Generar los informes cruzando los datos para detectar coautores y copias
for key in "${!best_file[@]}"; do
    u=$(echo "$key" | cut -d_ -f1)
    t=$(echo "$key" | cut -d_ -f2)
    e=$(echo "$key" | cut -d_ -f3)
    f="${best_file[$key]}"

    informe="$DEST_DIR/informe_${u}.txt"

    # Datos básicos
    nombre_script=$(basename "$f")
    # Obtener el nombre real del archivo /etc/passwd (gecos) si existe, sino usa el login
    autor_real=$(getent passwd "$u" 2>/dev/null | cut -d: -f5 | cut -d, -f1)
    [ -z "$autor_real" ] && autor_real="$u"

    # Coautores (autores del script que no sean el usuario evaluado actualmente)
    coautores_str=""
    my_autores="${script_autores[$f]}"
    for c in $my_autores; do
        if [ "$c" != "$u" ]; then
            creal=$(getent passwd "$c" 2>/dev/null | cut -d: -f5 | cut -d, -f1)
            [ -z "$creal" ] && creal="$c"
            coautores_str="$coautores_str $creal"
        fi
    done

    # Limpiar formato de coautores
    if [ -z "$coautores_str" ]; then
        coautores_str="Ninguno"
    else
        coautores_str=$(echo "$coautores_str" | awk '{$1=$1};1' | tr ' ' ',')
    fi

    # Buscar copias analizando si algún otro usuario tiene el MISMO Hash en este Tema/Ejercicio y NO es coautor
    my_hash="${script_hash[$f]}"
    copias_str=""

    for k2 in "${!best_file[@]}"; do
        u2=$(echo "$k2" | cut -d_ -f1)
        t2=$(echo "$k2" | cut -d_ -f2)
        e2=$(echo "$k2" | cut -d_ -f3)

        # Si coincide Tema y Ejercicio, pero es otro usuario distinto
        if [[ "$t2" == "$t" ]] && [[ "$e2" == "$e" ]] && [[ "$u2" != "$u" ]]; then

            # Verificamos si ese usuario2 es coautor legítimo
            is_coautor=0
            for c in $my_autores; do
                if [ "$c" == "$u2" ]; then is_coautor=1; break; fi
            done

            # Si NO es coautor, comparamos la huella digital (Hash) de los códigos
            if [ $is_coautor -eq 0 ]; then
                f2="${best_file[$k2]}"
                if [ "${script_hash[$f2]}" == "$my_hash" ]; then
                    copias_str="$copias_str $u2"
                fi
            fi
        fi
    done

    # Limpiar formato de copias
    if [ -z "$copias_str" ]; then
        copias_str="Ninguno"
    else
        copias_str=$(echo "$copias_str" | awk '{$1=$1};1' | tr ' ' ',')
    fi

    # Volcar resultados al informe correspondiente
    {
        echo "############################################################################"
        echo "# Nombre del script: $nombre_script"
        echo "# Autor/es: $autor_real"
        echo "# Coautores: $coautores_str"
        echo "# Shell: ${script_shell[$f]}"
        echo "# Tema:$t Ejercicio:$e"
        echo "# Posible Copia de: $copias_str"
        echo "###########################################################################"
        # Imprimir contenido ignorando líneas de comentarios y vacías
        grep -v '^[[:space:]]*#' "$f" | grep -v '^[[:space:]]*$'
        echo ""
        echo ""
    } >> "$informe"

done

echo "Proceso finalizado. Informes generados en '$DEST_DIR'."
exit 0
