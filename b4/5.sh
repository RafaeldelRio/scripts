#!/bin/bash

: <<"FIN"
Realizar un script llamado informe.sh que genere un informe de uso del sistema de ficheros por parte de los usuarios.
La sintaxis del script será:
        informe.sh [-u usuario | -c]
        -u usuario recopilará información del sistema para el usuario dado
        -c recopilará información del sistema para todos los usuarios conectados
        sin parámetro recopilará información del sistema para todos los usuarios del sistema
El contenido del informe será el siguiente:

##################
Usuario:xxxxxxx
Nº ficheros de los que es propietario:25
Nº ficheros que puede modificar:30
Nº ficheros abiertos:58
Fichero más antiguo del usuario:/home...
Fichero más reciente modificado:/home....
Tamaño fichero más pequeño:8
Tamaño medio de fichero 5487
Tamaño fichero más grande 254568
Tipo de fichero más usual del usuario: ASCII C program text
FIN

# Aquí iremos guardando las rutas que vamos a revisar para cada usuario.
# Se rellena en `preparar_rutas_usuario()`.
RUTAS_USUARIO=()

mostrar_aviso_root() {
    # Si no somos root, el script puede ejecutarse igual,
    # pero algunos datos de otros usuarios no serán completos.
    if (( EUID != 0 )); then
        echo "Aviso: Es recomendable ejecutar este script como root (sudo)."
        echo "Si no eres root, algunos datos de otros usuarios pueden salir a 0."
        echo ""
    fi
}

mostrar_uso() {
    # Muestra la forma correcta de usar el script.
    echo "Sintaxis: $0 [-u usuario | -c]"
}

usuario_existe() {
    # Comprueba silenciosamente si el usuario existe en el sistema.
    id "$1" >/dev/null 2>&1
}

obtener_home_usuario() {
    # Obtiene el directorio home del usuario leyendo la base de usuarios del sistema.
    getent passwd "$1" | cut -d: -f6
}

preparar_rutas_usuario() {
    local usuario="$1"
    local home_usuario

    # Reiniciamos el array para no mezclar rutas de un usuario con otro.
    RUTAS_USUARIO=()
    home_usuario=$(obtener_home_usuario "$usuario")

    # La ruta principal que interesa revisar es su directorio personal.
    if [[ -n "$home_usuario" ]] && [[ -d "$home_usuario" ]]; then
        RUTAS_USUARIO+=("$home_usuario")
    fi

    # Añadimos rutas temporales habituales por si el usuario tiene ficheros suyos allí.
    if [[ -d "/tmp" ]]; then
        RUTAS_USUARIO+=("/tmp")
    fi

    if [[ -d "/var/tmp" ]]; then
        RUTAS_USUARIO+=("/var/tmp")
    fi
}

crear_lista_ficheros_propios() {
    local usuario="$1"
    local salida="$2"
    local ruta

    # Vacía el fichero de salida antes de empezar a escribir.
    : > "$salida"

    # Recorremos cada ruta interesante y guardamos solo ficheros del usuario.
    # En cada línea escribimos: tamaño, fecha de modificación y ruta completa.
    for ruta in "${RUTAS_USUARIO[@]}"; do
        find "$ruta" -type f -user "$usuario" -printf '%s\t%T@\t%p\n' 2>/dev/null >> "$salida"
    done
}

contar_ficheros_modificables() {
    local usuario="$1"
    local ruta
    local total=0
    local cuenta_ruta
    local ruta_escapada

    # Sumamos cuántos ficheros puede escribir el usuario en cada ruta revisada.
    for ruta in "${RUTAS_USUARIO[@]}"; do
        # Si somos root, podemos preguntar directamente simulando ese usuario con `su`.
        if (( EUID == 0 )); then
            printf -v ruta_escapada '%q' "$ruta"
            cuenta_ruta=$(su -s /bin/bash "$usuario" -c "find $ruta_escapada -type f -writable -print 2>/dev/null | wc -l")
        # Si no somos root, solo podemos calcularlo de forma fiable para nuestro propio usuario.
        elif [[ "$usuario" == "$USER" ]]; then
            cuenta_ruta=$(find "$ruta" -type f -writable -print 2>/dev/null | wc -l)
        else
            # Para otros usuarios sin ser root, devolvemos 0 para no dar datos engañosos.
            cuenta_ruta=0
        fi

        total=$((total + cuenta_ruta))
    done

    echo "$total"
}

contar_ficheros_abiertos() {
    local usuario="$1"

    # Si `lsof` no está instalado, no podemos calcular este dato.
    if ! command -v lsof >/dev/null 2>&1; then
        echo "0"
        return
    fi

    # `lsof -u usuario` lista los ficheros abiertos de ese usuario.
    # Quitamos la cabecera y contamos líneas.
    lsof -u "$usuario" -w 2>/dev/null | tail -n +2 | wc -l
}

analizar_ficheros_propios() {
    local lista_ficheros="$1"
    local total_propietario="$2"
    local size
    local fecha
    local fecha_entera
    local ruta
    local suma_tamanos=0

    # Variables globales de salida que luego imprimirá el informe.
    REP_ANTIGUO="Ninguno"
    REP_RECIENTE="Ninguno"
    REP_MIN_SIZE=0
    REP_MAX_SIZE=0
    REP_AVG_SIZE=0

    # Si no hay ficheros, dejamos los valores por defecto.
    if [[ "$total_propietario" -eq 0 ]]; then
        return
    fi

    local fecha_antigua=""
    local fecha_reciente=""

    # Recorremos uno a uno todos los ficheros guardados en la lista temporal.
    while IFS=$'\t' read -r size fecha ruta; do
        [[ -z "$ruta" ]] && continue

        # Nos quedamos con la parte entera de la fecha para compararla más rápido.
        fecha_entera=${fecha%.*}

        # Acumulamos tamaños para calcular luego la media.
        suma_tamanos=$((suma_tamanos + size))

        # Si es el primero o es más antiguo que el guardado, actualizamos.
        if [[ -z "$fecha_antigua" ]] || (( fecha_entera < fecha_antigua )); then
            fecha_antigua="$fecha_entera"
            REP_ANTIGUO="$ruta"
        fi

        # Si es el primero o es más reciente que el guardado, actualizamos.
        if [[ -z "$fecha_reciente" ]] || (( fecha_entera > fecha_reciente )); then
            fecha_reciente="$fecha_entera"
            REP_RECIENTE="$ruta"
        fi

        # Buscamos el tamaño mínimo.
        if [[ "$REP_MIN_SIZE" -eq 0 ]] || [[ "$size" -lt "$REP_MIN_SIZE" ]]; then
            REP_MIN_SIZE="$size"
        fi

        # Buscamos el tamaño máximo.
        if [[ "$size" -gt "$REP_MAX_SIZE" ]]; then
            REP_MAX_SIZE="$size"
        fi
    done < "$lista_ficheros"

    # La media es suma total dividido entre número de ficheros.
    REP_AVG_SIZE=$((suma_tamanos / total_propietario))
}

obtener_tipo_mas_usual() {
    local lista_ficheros="$1"
    local tipo_mas_usual
    local ruta
    local tipo_actual
    local cantidad_maxima=0
    local -A contador_tipos=()

    # Para que el informe no se quede bloqueado con miles de ficheros,
    # se toma una muestra de los primeros 200.
    # Recorremos esa muestra línea a línea, detectamos el tipo de cada fichero
    # y contamos cuántas veces aparece cada tipo.
    while IFS=$'\t' read -r _ _ ruta; do
        [[ -z "$ruta" ]] && continue

        tipo_actual=$(file -b "$ruta" 2>/dev/null)
        [[ -z "$tipo_actual" ]] && continue

        ((contador_tipos["$tipo_actual"]++))
    done < <(head -n 200 "$lista_ficheros")

    # Buscamos el tipo que más veces se repite.
    for tipo_actual in "${!contador_tipos[@]}"; do
        if (( contador_tipos["$tipo_actual"] > cantidad_maxima )); then
            cantidad_maxima=${contador_tipos["$tipo_actual"]}
            tipo_mas_usual="$tipo_actual"
        fi
    done

    # Si no se pudo detectar ningún tipo, devolvemos "Ninguno".
    if [[ -z "$tipo_mas_usual" ]]; then
        echo "Ninguno"
    else
        echo "$tipo_mas_usual"
    fi
}

imprimir_bloque_usuario() {
    local usuario="$1"
    local lista_ficheros="$2"
    local total_propietario
    local total_modificables
    local total_abiertos

    # Número total de ficheros propios encontrados.
    total_propietario=$(wc -l < "$lista_ficheros")

    # Imprimimos primero la cabecera y los datos más rápidos.
    echo "##################"
    echo "Usuario:$usuario"
    echo "Nº ficheros de los que es propietario:$total_propietario"

    # Calculamos cuántos puede modificar.
    total_modificables=$(contar_ficheros_modificables "$usuario")
    echo "Nº ficheros que puede modificar:$total_modificables"

    # Calculamos cuántos tiene abiertos ahora mismo.
    total_abiertos=$(contar_ficheros_abiertos "$usuario")
    echo "Nº ficheros abiertos:$total_abiertos"

    # Analizamos los tamaños y fechas de sus ficheros.
    analizar_ficheros_propios "$lista_ficheros" "$total_propietario"
    echo "Fichero más antiguo del usuario:$REP_ANTIGUO"
    echo "Fichero más reciente modificado:$REP_RECIENTE"
    echo "Tamaño fichero más pequeño:$REP_MIN_SIZE"
    echo "Tamaño medio de fichero:$REP_AVG_SIZE"
    echo "Tamaño fichero más grande:$REP_MAX_SIZE"

    # El tipo más usual se calcula al final porque puede ser lo más costoso.
    echo "Tipo de fichero más usual del usuario:$(obtener_tipo_mas_usual "$lista_ficheros")"
}

generar_informe_usuario() {
    local usuario="$1"
    local lista_ficheros

    # Si el usuario no existe, no hacemos nada.
    if ! usuario_existe "$usuario"; then
        return
    fi

    # Preparamos rutas a revisar para ese usuario.
    preparar_rutas_usuario "$usuario"

    # Creamos un fichero temporal con sus ficheros para reutilizarlo varias veces.
    lista_ficheros=$(mktemp)
    crear_lista_ficheros_propios "$usuario" "$lista_ficheros"
    imprimir_bloque_usuario "$usuario" "$lista_ficheros"

    # Limpiamos el temporal al terminar.
    rm -f "$lista_ficheros"
}

procesar_usuarios_conectados() {
    local usuario
    local anteriores=""

    # `who` puede devolver el mismo usuario varias veces.
    # Por eso guardamos cuáles ya hemos mostrado.
    while read -r usuario _; do
        [[ -z "$usuario" ]] && continue
        if [[ " $anteriores " != *" $usuario "* ]]; then
            generar_informe_usuario "$usuario"
            anteriores="$anteriores $usuario"
        fi
    done < <(who 2>/dev/null)
}

procesar_usuarios_sistema() {
    local usuario
    local uid

    # Leemos /etc/passwd campo a campo.
    # Solo procesamos usuarios "normales" (UID >= 1000), excluyendo normalmente a nobody (65534).
    while IFS=: read -r usuario _ uid _ _ _ _; do
        if [[ "$uid" -ge 1000 ]] && [[ "$uid" -ne 65534 ]]; then
            generar_informe_usuario "$usuario"
        fi
    done < /etc/passwd
}

main() {
    # Mostramos aviso inicial si no se ejecuta como root.
    mostrar_aviso_root

    # Sin parámetros: todos los usuarios normales del sistema.
    if [[ "$#" -eq 0 ]]; then
        procesar_usuarios_sistema
        return
    fi

    # Con -c: usuarios conectados actualmente.
    if [[ "$1" == "-c" ]] && [[ "$#" -eq 1 ]]; then
        procesar_usuarios_conectados
        return
    fi

    # Con -u usuario: solo ese usuario.
    if [[ "$1" == "-u" ]] && [[ -n "$2" ]] && [[ "$#" -eq 2 ]]; then
        generar_informe_usuario "$2"
        return
    fi

    # Cualquier otra combinación se considera error de sintaxis.
    echo "Error: parámetros no válidos."
    mostrar_uso
    exit 1
}

main "$@"
exit 0
