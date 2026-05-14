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

DEST_DIR=""

# Guarda el fichero más reciente para cada combinación usuario-tema-ejercicio.
# La clave tendrá este formato: usuario|tema|ejercicio
# Los declare -A lo que hacen es crear un array asociativo, es decir, un diccionario donde la clave no tiene por qué ser un número.
declare -A BEST_FILE
declare -A BEST_TIME

# Guarda datos del script usando como clave la ruta completa del fichero.
# Así, una vez localizado un script válido, podemos consultar sus datos más tarde.
declare -A SCRIPT_HASH
declare -A SCRIPT_AUTORES
declare -A SCRIPT_SHELL
declare -A SCRIPT_TEMA
declare -A SCRIPT_EJERCICIO

comprobar_root() {
    # Este ejercicio exige que el script solo pueda ejecutarlo root.
    if (( EUID != 0 )); then
        echo "Error: Este script debe ser ejecutado exclusivamente por root."
        exit 1
    fi
}

comprobar_parametros() {
    # Solo se admite un parámetro: el directorio donde guardar los informes.
    if [[ "$#" -ne 1 ]]; then
        echo "Sintaxis: $0 <directorio>"
        exit 1
    fi
}

preparar_directorio_destino() {
    DEST_DIR="$1"

    # Si el directorio no existe, se crea.
    if [[ ! -d "$DEST_DIR" ]]; then
        mkdir -p "$DEST_DIR" 2>/dev/null
    fi

    # Convertimos la ruta a absoluta para poder excluirla correctamente en `find`.
    DEST_DIR=$(realpath "$DEST_DIR" 2>/dev/null)

    # Limpiamos informes anteriores para no mezclar resultados viejos con nuevos.
    rm -f "$DEST_DIR"/informe_*.txt 2>/dev/null
}

obtener_primera_linea() {
    local fichero="$1"
    local linea

    # Lee solo la primera línea del fichero.
    IFS= read -r linea < "$fichero"
    echo "$linea"
}

quitar_espacios() {
    local texto="$1"

    # Elimina todos los espacios y tabulaciones del texto recibido.
    echo "$texto" | tr -d '[:space:]'
}

obtener_valor_cabecera() {
    local fichero="$1"
    local etiqueta="$2"
    local linea
    local valor

    # Recorre el fichero línea a línea hasta encontrar la cabecera pedida.
    while IFS= read -r linea; do
        case "$linea" in
            \#${etiqueta}:*|[[:space:]]*\#${etiqueta}:*)
                # Nos quedamos con todo lo que haya tras los dos puntos.
                valor=${linea#*:}
                echo "$valor"
                return
                ;;
        esac
    done < "$fichero"
}

obtener_shell_script() {
    local fichero="$1"
    local primera_linea

    # La shell se toma del shebang: por ejemplo, #!/bin/bash.
    primera_linea=$(obtener_primera_linea "$fichero")
    if [[ "$primera_linea" == '#!'* ]]; then
        echo "${primera_linea#\#!}"
    fi
}

calcular_hash_contenido() {
    local fichero="$1"
    local temporal
    local linea
    local hash

    # Creamos un fichero temporal donde guardaremos solo el contenido útil del script.
    temporal=$(mktemp)

    while IFS= read -r linea; do
        # Si la línea es comentario, no se usa para el hash.
        if [[ "$linea" == [[:space:]]*#* ]]; then
            continue
        fi

        # Si la línea está vacía o solo tiene espacios, tampoco cuenta.
        if [[ -z "$(echo "$linea" | tr -d '[:space:]')" ]]; then
            continue
        fi

        # Solo guardamos líneas reales de código.
        echo "$linea" >> "$temporal"
    done < "$fichero"

    # El hash sirve para detectar posibles copias entre scripts distintos.
    hash=$(md5sum "$temporal" | cut -d' ' -f1)
    rm -f "$temporal"
    echo "$hash"
}

guardar_datos_script() {
    local fichero="$1"
    local shell_val="$2"
    local tema_val="$3"
    local ejercicio_val="$4"
    local autores_val="$5"

    # Guardamos todos los datos del script para reutilizarlos después al crear informes.
    SCRIPT_HASH["$fichero"]=$(calcular_hash_contenido "$fichero")
    SCRIPT_AUTORES["$fichero"]="$autores_val"
    SCRIPT_SHELL["$fichero"]="$shell_val"
    SCRIPT_TEMA["$fichero"]="$tema_val"
    SCRIPT_EJERCICIO["$fichero"]="$ejercicio_val"
}

registrar_script_reciente_por_autor() {
    local fichero="$1"
    local tema_val="$2"
    local ejercicio_val="$3"
    local autores_val="$4"
    local mtime="$5"
    local autor
    local clave

    # Un mismo script puede tener varios autores.
    # Para cada autor guardamos cuál es su script más reciente en ese tema y ejercicio.
    for autor in $autores_val; do
        clave="${autor}|${tema_val}|${ejercicio_val}"

        if [[ -z "${BEST_TIME[$clave]}" ]] || (( mtime > BEST_TIME[$clave] )); then
            BEST_TIME["$clave"]="$mtime"
            BEST_FILE["$clave"]="$fichero"
        fi
    done
}

procesar_fichero_script() {
    local fichero="$1"
    local shell_val
    local tema_val
    local ejercicio_val
    local autores_val
    local mtime

    # 1. Comprobar que tiene shebang.
    shell_val=$(obtener_shell_script "$fichero")
    if [[ -z "$shell_val" ]]; then
        return
    fi

    # 2. Extraer el tema.
    tema_val=$(obtener_valor_cabecera "$fichero" "Tema")
    tema_val=$(quitar_espacios "$tema_val")
    if [[ -z "$tema_val" ]]; then
        return
    fi

    # 3. Extraer el ejercicio.
    ejercicio_val=$(obtener_valor_cabecera "$fichero" "Ejercicio")
    ejercicio_val=$(quitar_espacios "$ejercicio_val")
    if [[ -z "$ejercicio_val" ]]; then
        return
    fi

    # 4. Extraer autores.
    autores_val=$(obtener_valor_cabecera "$fichero" "Autores")
    if [[ -z "$autores_val" ]]; then
        return
    fi

    # 5. Obtener fecha de modificación para decidir cuál es el más reciente.
    mtime=$(stat -c %Y "$fichero" 2>/dev/null)
    if [[ -z "$mtime" ]]; then
        return
    fi

    # Si llega aquí, el script es válido y se guarda en memoria.
    guardar_datos_script "$fichero" "$shell_val" "$tema_val" "$ejercicio_val" "$autores_val"
    registrar_script_reciente_por_autor "$fichero" "$tema_val" "$ejercicio_val" "$autores_val" "$mtime"
}

buscar_scripts_alumnos() {
    local fichero

    echo "Buscando scripts de alumnos y procesando (puede tardar unos segundos)..."

    # Se recorre todo el sistema buscando ficheros cuyos dueños tengan UID entre 2000 y 2100.
    # Además se excluye el propio directorio de destino para no procesar los informes generados.
    while IFS= read -r -d '' fichero; do
        procesar_fichero_script "$fichero"
    done < <(find / -path "$DEST_DIR" -prune -o -uid +1999 -uid -2101 -type f -print0 2>/dev/null)
}

obtener_nombre_real() {
    local usuario="$1"
    local datos
    local nombre_real

    # `getent passwd` permite obtener la información del usuario del sistema.
    datos=$(getent passwd "$usuario" 2>/dev/null)
    nombre_real=$(echo "$datos" | cut -d: -f5 | cut -d, -f1)

    # Si no hay nombre real, usamos el login.
    if [[ -z "$nombre_real" ]]; then
        echo "$usuario"
    else
        echo "$nombre_real"
    fi
}

formatear_lista_con_comas() {
    local texto="$1"
    local palabra
    local resultado=""

    # Convierte una lista separada por espacios en otra separada por comas.
    for palabra in $texto; do
        if [[ -z "$resultado" ]]; then
            resultado="$palabra"
        else
            resultado="$resultado,$palabra"
        fi
    done

    # Si no hay elementos, devolvemos "Ninguno".
    if [[ -z "$resultado" ]]; then
        echo "Ninguno"
    else
        echo "$resultado"
    fi
}

obtener_coautores() {
    local usuario_actual="$1"
    local fichero="$2"
    local autor
    local nombres=""
    local nombre_real

    # Recorre todos los autores del script y excluye al usuario principal del informe.
    for autor in ${SCRIPT_AUTORES[$fichero]}; do
        if [[ "$autor" != "$usuario_actual" ]]; then
            nombre_real=$(obtener_nombre_real "$autor")
            nombres="$nombres $nombre_real"
        fi
    done

    formatear_lista_con_comas "$nombres"
}

usuario_es_coautor() {
    local usuario_buscado="$1"
    local lista_autores="$2"
    local autor

    # Devuelve éxito si el usuario buscado aparece en la lista de autores.
    for autor in $lista_autores; do
        if [[ "$autor" == "$usuario_buscado" ]]; then
            return 0
        fi
    done

    return 1
}

obtener_posibles_copias() {
    local usuario_actual="$1"
    local tema_actual="$2"
    local ejercicio_actual="$3"
    local fichero_actual="$4"
    local hash_actual
    local clave
    local usuario_otro
    local tema_otro
    local ejercicio_otro
    local fichero_otro
    local lista_copias=""

    # Tomamos la huella del script actual para compararla con otras.
    hash_actual="${SCRIPT_HASH[$fichero_actual]}"

    # Recorremos todos los scripts seleccionados como "mejores" o más recientes.
    for clave in "${!BEST_FILE[@]}"; do
        IFS='|' read -r usuario_otro tema_otro ejercicio_otro <<< "$clave"

        # No se compara el usuario consigo mismo.
        if [[ "$usuario_otro" == "$usuario_actual" ]]; then
            continue
        fi

        # Solo interesa comparar scripts del mismo tema.
        if [[ "$tema_otro" != "$tema_actual" ]]; then
            continue
        fi

        # Y del mismo ejercicio.
        if [[ "$ejercicio_otro" != "$ejercicio_actual" ]]; then
            continue
        fi

        # Si el otro usuario es coautor legítimo, no se considera copia.
        if usuario_es_coautor "$usuario_otro" "${SCRIPT_AUTORES[$fichero_actual]}"; then
            continue
        fi

        fichero_otro="${BEST_FILE[$clave]}"
        # Si ambos hashes coinciden, se marca como posible copia.
        if [[ "${SCRIPT_HASH[$fichero_otro]}" == "$hash_actual" ]]; then
            lista_copias="$lista_copias $usuario_otro"
        fi
    done

    formatear_lista_con_comas "$lista_copias"
}

volcar_contenido_sin_comentarios() {
    local fichero="$1"
    local linea

    # Escribe el contenido real del script ignorando comentarios y líneas en blanco.
    while IFS= read -r linea; do
        if [[ "$linea" == [[:space:]]*#* ]]; then
            continue
        fi

        if [[ -z "$(echo "$linea" | tr -d '[:space:]')" ]]; then
            continue
        fi

        echo "$linea"
    done < "$fichero"
}

generar_informe_para_clave() {
    local clave="$1"
    local usuario
    local tema
    local ejercicio
    local fichero
    local informe
    local nombre_script
    local autor_real
    local coautores
    local copias

    # La clave tiene el formato usuario|tema|ejercicio.
    IFS='|' read -r usuario tema ejercicio <<< "$clave"
    fichero="${BEST_FILE[$clave]}"
    informe="$DEST_DIR/informe_${usuario}.txt"

    # Reunimos todos los datos que se van a escribir en el informe.
    nombre_script=$(basename "$fichero")
    autor_real=$(obtener_nombre_real "$usuario")
    coautores=$(obtener_coautores "$usuario" "$fichero")
    copias=$(obtener_posibles_copias "$usuario" "$tema" "$ejercicio" "$fichero")

    # Escribimos el bloque del informe y, debajo, el contenido del script sin comentarios.
    {
        echo "############################################################################"
        echo "# Nombre del script: $nombre_script"
        echo "# Autor/es: $autor_real"
        echo "# Coautores: $coautores"
        echo "# Shell: ${SCRIPT_SHELL[$fichero]}"
        echo "# Tema:$tema Ejercicio:$ejercicio"
        echo "# Posible Copia de: $copias"
        echo "###########################################################################"
        volcar_contenido_sin_comentarios "$fichero"
        echo ""
        echo ""
    } >> "$informe"
}

generar_todos_los_informes() {
    local clave

    # Para cada combinación usuario-tema-ejercicio seleccionada, generamos un bloque de informe.
    for clave in "${!BEST_FILE[@]}"; do
        generar_informe_para_clave "$clave"
    done
}

main() {
    # Flujo principal del programa.
    comprobar_root
    comprobar_parametros "$@"
    preparar_directorio_destino "$1"
    buscar_scripts_alumnos
    generar_todos_los_informes
    echo "Proceso finalizado. Informes generados en '$DEST_DIR'."
}

main "$@"
exit 0
