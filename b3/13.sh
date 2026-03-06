#!/bin/bash

: << "FIN"
EJERCICIO 13. EXAMEN OPOSICIONES SAI. 2006. EJERCICIO 1.
El ejercicio práctico se realizará bajo sistema operativo LINUX. Se podrá hacer uso del comando man.

Elabora un shell script que nos permitirá hacer un seguimiento de los scripts realizados por los alumnos
    de 2° de Ciclo Formativo de Grado Superior de Desarrollo de Aplicaciones Informáticas.

Admitirá como argumento el nombre de un grupo de alumnos y generará un fichero denominado grupoMesActual 
    que contendrá: Login, nombre de los alumnos, número de scripts incluidos de cada alumno, nombre y 
    contenido de los mismos.

Además, se marcará cada script como copiado con un comentario con la fecha.

Contenido del fichero:
- Seguimiento a fecha del Grupo: xxxxxxx
- Usuario: Login del Alumno / Nombre del Alumno Nombre Script: xxxxxxxxxx Contenido del script

Total scripts incluidos para Nombre del Alumno: ##
Justificación del ejercicio, aclaraciones (si son necesarias) y representaciones gráficas.

FIN


# Comprobar que se recibe exactamente un argumento: el nombre del grupo.
if [[ "$#" -ne 1 ]]; then
    echo "Uso: $0 grupo" >&2
    exit 2
fi

group_name="$1"
# Consultar la entrada del grupo en la base de datos del sistema.
group_entry="$(getent group "$group_name" || true)"
if [[ -z "$group_entry" ]]; then
    echo "Error: el grupo $group_name no existe." >&2
    exit 1
fi

# Nombre del fichero de salida: nombre del grupo + número de mes actual.
month="$(date +%m)"
today="$(date +%F)"
output_file="${group_name}${month}"

# Array asociativo para guardar usuarios sin duplicados.
declare -A users

# Extraer GID y lista de miembros suplementarios del grupo.
group_gid="$(echo "$group_entry" | cut -d: -f3)"
group_members="$(echo "$group_entry" | cut -d: -f4)"

# Incluye usuarios con grupo principal igual al grupo solicitado.
while IFS=: read -r user _ _ gid _ _ _; do
    if [[ "$gid" = "$group_gid" ]]; then
        users["$user"]=1
    fi
done < /etc/passwd

# Incluye también usuarios del grupo suplementario.
IFS=',' read -r -a members_arr <<< "$group_members"
for user in "${members_arr[@]}"; do
    [[ -n "$user" ]] && users["$user"]=1
done

# Crear o sobrescribir el fichero de salida con la cabecera del informe.
{
    echo "Seguimiento a fecha del Grupo: $group_name ($today)"
    echo
} > "$output_file"

# Recorrer cada alumno detectado en el grupo.
# Se anota su login, nombre completo, scripts encontrados y su contenido.
for user in "${!users[@]}"; do
    # Campo GECOS: suele contener el nombre completo del usuario.
    gecos="$(getent passwd "$user" | cut -d: -f5 | cut -d, -f1)"
    # Obtener el directorio personal del alumno.
    home_dir="$(getent passwd "$user" | cut -d: -f6)"

    echo "Usuario: $user / ${gecos:-Sin nombre}" >> "$output_file"

    script_count=0
    # Buscar scripts .sh en el home del alumno, sin bajar a subdirectorios.
    while IFS= read -r -d '' script_path; do
        script_name="$(basename "$script_path")"
        script_count=$((script_count + 1))

        # Añadir al informe el nombre del script y su contenido completo.
        {
            echo "Nombre Script: $script_name"
            echo "Contenido del script:"
            cat "$script_path"
            echo
        } >> "$output_file"

        # Marca cada script como copiado en la fecha actual.
        if ! tail -n 1 "$script_path" | grep -q "copiado: $today"; then
            echo "# copiado: $today" >> "$script_path"
        fi
    done < <(find "$home_dir" -maxdepth 1 -type f -name '*.sh' -print0 2>/dev/null)

    # Resumen final del número de scripts encontrados para ese alumno.
    echo "Total scripts incluidos para ${gecos:-$user}: $script_count" >> "$output_file"
    echo >> "$output_file"
done

# Informar por pantalla del fichero generado.
echo "Fichero generado: $output_file"