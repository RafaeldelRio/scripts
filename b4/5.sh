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

#!/bin/bash

# Comprobar si se ejecuta con privilegios para poder examinar todo el sistema
if [ "$EUID" -ne 0 ]; then
    echo "Aviso: Es altamente recomendable ejecutar este script como root (sudo)."
    echo "De lo contrario, no se podrán contar los ficheros abiertos o modificables de otros usuarios."
    echo ""
fi

# Función encargada de generar el bloque del informe para un usuario dado
generar_informe() {
    local u="$1"

    # Verificar de forma silenciosa si el usuario existe
    if ! id "$u" >/dev/null 2>&1; then
        return
    fi

    echo "##################"
    echo "Usuario:$u"

    # Creamos un fichero temporal para guardar la lista de ficheros del usuario.
    # El formato que extraemos es: "Tamaño(bytes) Fecha_Modificacion(Unix_Epoch) Ruta_Fichero"
    local tmp_files
    tmp_files=$(mktemp)
    find / -type f -user "$u" -printf "%s %T@ %p\n" 2>/dev/null > "$tmp_files"

    # Nº ficheros de los que es propietario
    local total_propietario
    total_propietario=$(wc -l < "$tmp_files")
    echo "Nº ficheros de los que es propietario:$total_propietario"

    # Nº ficheros que puede modificar
    # Usamos su para hacernos pasar por el usuario y ver qué ficheros tienen permiso de escritura real para él
    local total_modificables
    total_modificables=$(su -s /bin/bash "$u" -c "find / -type f -writable 2>/dev/null" | wc -l)
    echo "Nº ficheros que puede modificar:$total_modificables"

    # Nº ficheros abiertos
    # Utilizamos lsof (-w para silenciar warnings), omitimos la cabecera (NR>1) y contamos líneas
    local total_abiertos=0
    if command -v lsof >/dev/null 2>&1; then
        total_abiertos=$(lsof -u "$u" -w 2>/dev/null | awk 'NR>1' | wc -l)
    fi
    echo "Nº ficheros abiertos:$total_abiertos"

    # Si el usuario tiene ficheros, calculamos las estadísticas sobre el fichero temporal
    if [ "$total_propietario" -gt 0 ]; then
        # Fichero más antiguo (-k2,2n ordena numéricamente por la 2ª columna, que es la fecha, de menor a mayor)
        local antiguo
        antiguo=$(sort -k2,2n "$tmp_files" | head -n 1 | cut -d' ' -f3-)

        # Fichero más reciente (-k2,2nr igual que el anterior pero r = reverse)
        local reciente
        reciente=$(sort -k2,2nr "$tmp_files" | head -n 1 | cut -d' ' -f3-)

        # Tamaño fichero más pequeño (-k1,1n ordena por la 1ª columna, el tamaño)
        local min_size
        min_size=$(sort -k1,1n "$tmp_files" | head -n 1 | cut -d' ' -f1)

        # Tamaño fichero más grande (-k1,1nr orden inverso)
        local max_size
        max_size=$(sort -k1,1nr "$tmp_files" | head -n 1 | cut -d' ' -f1)

        # Tamaño medio (sumamos todos los tamaños y dividimos por el número de registros)
        local avg_size
        avg_size=$(awk '{s+=$1} END {printf "%.0f\n", s/NR}' "$tmp_files")

        # Tipo de fichero más usual
        # 1. Extraemos las rutas (cut)
        # 2. Las pasamos al comando 'file' de forma segura aunque tengan espacios (tr \n \0 | xargs -0)
        # 3. Contamos las ocurrencias de cada tipo (uniq -c) y cogemos la que más se repita (tail -n 1)
        local tipo_usual
        tipo_usual=$(cut -d' ' -f3- "$tmp_files" | tr '\n' '\0' | xargs -0 file -b 2>/dev/null | sort | uniq -c | sort -nr | head -n 1 | awk '{$1=""; print substr($0,2)}')

        echo "Fichero más antiguo del usuario:$antiguo"
        echo "Fichero más reciente modificado:$reciente"
        echo "Tamaño fichero más pequeño:$min_size"
        echo "Tamaño medio de fichero:$avg_size"
        echo "Tamaño fichero más grande:$max_size"
        echo "Tipo de fichero más usual del usuario:$tipo_usual"
    else
        # Si no tiene ningún fichero, rellenamos con valores por defecto
        echo "Fichero más antiguo del usuario:Ninguno"
        echo "Fichero más reciente modificado:Ninguno"
        echo "Tamaño fichero más pequeño:0"
        echo "Tamaño medio de fichero:0"
        echo "Tamaño fichero más grande:0"
        echo "Tipo de fichero más usual del usuario:Ninguno"
    fi

    # Borramos el fichero temporal
    rm -f "$tmp_files"
}

# --- LÓGICA DE PARÁMETROS ---
case "$1" in
    "-c")
        # Recopila la información para todos los usuarios conectados actualmente (evitando duplicados)
        usuarios_conect=$(who 2>/dev/null | awk '{print $1}' | sort -u)
        for usuario in $usuarios_conect; do
            generar_informe "$usuario"
        done
        ;;
    "-u")
        if [ -n "$2" ]; then
            generar_informe "$2"
        else
            echo "Error: Falta el nombre del usuario."
            echo "Uso: $0 -u <usuario>"
            exit 1
        fi
        ;;
    "")
        # Sin parámetros: recopila la información para todos los usuarios regulares del sistema
        # Filtramos por UID >= 1000 para excluir usuarios del sistema como 'daemon', 'bin', etc.
        usuarios_todos=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd 2>/dev/null)
        for usuario in $usuarios_todos; do
            generar_informe "$usuario"
        done
        # Opcional: Podrías añadir a 'root' si quisieras analizando su uso también: generar_informe "root"
        ;;
    *)
        echo "Error: Parámetro desconocido '$1'"
        echo "Sintaxis: $0 [-u usuario | -c]"
        exit 1
        ;;
esac

exit 0
