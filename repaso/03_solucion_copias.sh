#!/bin/bash

# Script de repaso que mezcla tres bloques tipicos de administracion:
# backup rotativo, restauracion y auditoria de scripts de alumnos.
# Todo se hace sobre datos locales para no depender de usuarios reales.

# Activa comprobaciones estrictas basicas.
set -u
set -o pipefail

# Directorios base del ejercicio.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECTS_DIR="$SCRIPT_DIR/datos/ej3/proyectos"
SCRIPTS_DIR="$SCRIPT_DIR/datos/ej3/scripts_alumnos"
OUTPUT_DIR="$SCRIPT_DIR/salidas/ej3"
STORE_DIR="$OUTPUT_DIR/backups"
RESTORE_DIR="$OUTPUT_DIR/restaurados"
LOG_FILE="$OUTPUT_DIR/gestion_copias.log"
AUDIT_REPORT="$OUTPUT_DIR/informe_scripts.txt"
DEFAULT_KEEP=2

# Estos arrays asociativos sostienen la parte de deduplicacion y auditoria.
# La clave principal es `autor|tema|ejercicio`.
declare -A BEST_FILE=()
declare -A BEST_TIME=()
declare -A SCRIPT_HASH=()
declare -A SCRIPT_AUTORES=()
declare -A SCRIPT_SHELL=()
declare -A SCRIPT_TEMA=()
declare -A SCRIPT_EJERCICIO=()

# Marca temporal comun para todas las operaciones.
timestamp() {
	date '+%Y-%m-%d %H:%M:%S'
}

# Registro persistente de acciones y errores.
log_msg() {
	mkdir -p "$OUTPUT_DIR"
	printf '[%s] %s\n' "$(timestamp)" "$1" >> "$LOG_FILE"
}

# Ayuda de uso por linea de comandos.
usage() {
	cat <<EOF
Uso: $0 [-b] [-r proyecto] [-a] [-t] [-h]
EOF
}

# Prepara la jerarquia de salida del ejercicio.
init_paths() {
	mkdir -p "$STORE_DIR" "$RESTORE_DIR" "$OUTPUT_DIR"
	touch "$LOG_FILE"
}

# Lee el fichero oculto de configuracion del proyecto y vuelca sus claves
# en variables globales temporales para la copia actual.
read_config() {
	local config_file="$1"
	CFG_NUM_COPIAS=''
	CFG_CONTENIDO_COPIA=''
	local key value
	while IFS='=' read -r key value || [[ -n "${key:-}${value:-}" ]]; do
		key=${key//[[:space:]]/}
		value=${value#"${value%%[![:space:]]*}"}
		value=${value%"${value##*[![:space:]]}"}
		[[ -z "$key" || "$key" == \#* ]] && continue
		case "$key" in
			numeroCopias) CFG_NUM_COPIAS="$value" ;;
			contenidoCopia) CFG_CONTENIDO_COPIA="${value// /}" ;;
		esac
	done < "$config_file"
}

# Mantiene solo las `N` copias mas recientes de cada proyecto.
rotate_backups() {
	local project_name="$1"
	local keep_count="$2"
	local project_store="$STORE_DIR/$project_name"
	local -a copies
	mapfile -t copies < <(ls -1tr "$project_store"/copia_*.tgz 2>/dev/null)
	while (( ${#copies[@]} > keep_count )); do
		rm -f "${copies[0]}"
		log_msg "Rotada copia antigua para $project_name: ${copies[0]}"
		copies=("${copies[@]:1}")
	done
}

# Crea la copia de un proyecto concreto.
# Devuelve:
# - 0 si la copia se ha creado
# - 1 si hubo fallo real al copiar
# - 2 si el proyecto se omite por configuracion incompleta o invalida
backup_project() {
	local project_dir="$1"
	local project_name config_file keep_count archive_name temp_archive final_archive
	local -a items valid_items
	local item absolute_path

	project_name=$(basename "$project_dir")
	config_file="$project_dir/.repasoBackup.conf"
	if [[ ! -f "$config_file" ]]; then
		log_msg "Proyecto omitido sin configuracion: $project_name"
		return 2
	fi

	read_config "$config_file"
	keep_count="$CFG_NUM_COPIAS"
	if [[ ! "$keep_count" =~ ^[0-9]+$ ]] || (( keep_count < 1 )); then
		keep_count=$DEFAULT_KEEP
	fi

	# Sin `contenidoCopia` no hay nada que respaldar.
	if [[ -z "$CFG_CONTENIDO_COPIA" ]]; then
		log_msg "Proyecto omitido sin contenidoCopia: $project_name"
		return 2
	fi

	# Solo se respaldan rutas que existan dentro del propio proyecto.
	IFS=':' read -r -a items <<< "$CFG_CONTENIDO_COPIA"
	valid_items=()
	for item in "${items[@]}"; do
		absolute_path="$project_dir/$item"
		if [[ -e "$absolute_path" ]]; then
			valid_items+=("$item")
		fi
	done

	if (( ${#valid_items[@]} == 0 )); then
		log_msg "Sin rutas validas para copia en $project_name"
		return 2
	fi

	mkdir -p "$STORE_DIR/$project_name"
	# Primero se genera un temporal oculto y solo al final se renombra.
	# Eso evita dejar copias parciales si `tar` falla a mitad.
	archive_name="copia_$(date '+%Y%m%d_%H%M%S').tgz"
	temp_archive="$STORE_DIR/$project_name/.${archive_name}.tmp"
	final_archive="$STORE_DIR/$project_name/$archive_name"

	if tar -czf "$temp_archive" -C "$project_dir" .repasoBackup.conf "${valid_items[@]}" 2>/dev/null; then
		mv "$temp_archive" "$final_archive"
		log_msg "Copia creada para $project_name: $final_archive"
		rotate_backups "$project_name" "$keep_count"
	else
		rm -f "$temp_archive"
		log_msg "Fallo al crear copia para $project_name. Rollback aplicado."
		return 1
	fi
	return 0
}

# Recorre todos los proyectos configurados y cuenta solo los realmente respaldados.
backup_all_projects() {
	local project_dir count=0
	while IFS= read -r -d '' project_dir; do
		if backup_project "$project_dir"; then
			count=$((count + 1))
		fi
	done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
	echo "Proyectos respaldados: $count"
}

# Extrae la copia mas reciente de un proyecto a una carpeta de restauracion local.
restore_latest() {
	local project_name="$1"
	local latest_backup destination
	latest_backup=$(ls -1t "$STORE_DIR/$project_name"/copia_*.tgz 2>/dev/null | head -n 1)
	if [[ -z "$latest_backup" ]]; then
		echo "No existen copias para $project_name"
		log_msg "Restauracion fallida sin copias para $project_name"
		return 1
	fi

	destination="$RESTORE_DIR/$project_name"
	rm -rf "$destination"
	mkdir -p "$destination"
	if tar -xzf "$latest_backup" -C "$destination" 2>/dev/null; then
		echo "Restauracion completada en $destination"
		log_msg "Restauracion completada para $project_name desde $latest_backup"
		return 0
	fi
	rm -rf "$destination"
	log_msg "Restauracion fallida para $project_name. Rollback aplicado."
	return 1
}

# Dibuja un arbol textual sin depender del comando externo `tree`.
# La recursion permite practicar el patron que aparece en varios scripts del repo.
tree_dir() {
	local directory="$1"
	local prefix="${2:-}"
	local entry
	shopt -s nullglob dotglob
	for entry in "$directory"/*; do
		[[ -e "$entry" ]] || continue
		if [[ -d "$entry" ]]; then
			printf '%s+ %s\n' "$prefix" "$(basename "$entry")"
			tree_dir "$entry" "$prefix    "
		else
			printf '%s- %s\n' "$prefix" "$(basename "$entry")"
		fi
	done
	shopt -u nullglob dotglob
}

# Punto de entrada de la visualizacion del arbol de copias.
show_backup_tree() {
	if [[ ! -d "$STORE_DIR" ]]; then
		echo 'No existe el directorio de copias.'
		return 1
	fi
	tree_dir "$STORE_DIR"
	log_msg 'Arbol de copias mostrado.'
}

# Lee solo la primera linea para extraer el shebang de un script candidato.
get_first_line() {
	local file="$1"
	IFS= read -r line < "$file"
	printf '%s' "$line"
}

# Busca el valor de una cabecera concreta, por ejemplo `Tema` o `Autores`.
get_header_value() {
	local file="$1"
	local label="$2"
	local line value
	while IFS= read -r line || [[ -n "$line" ]]; do
		case "$line" in
			\#${label}:*|[[:space:]]*\#${label}:*)
				value=${line#*:}
				printf '%s' "$value"
				return 0
				;;
		esac
	done < "$file"
	return 1
}

# Elimina todos los espacios para normalizar temas y ejercicios.
trim_spaces() {
	printf '%s' "$1" | tr -d '[:space:]'
}

# Recupera la shell a partir del shebang.
script_shell() {
	local first_line
	first_line=$(get_first_line "$1")
	if [[ "$first_line" == '#!'* ]]; then
		printf '%s' "${first_line#\#!}"
	fi
}

# Calcula un hash solo del contenido util del script.
# Se excluyen comentarios y lineas vacias para detectar posibles copias por logica,
# no por metadatos o cabeceras diferentes.
content_hash() {
	local file="$1"
	local tmp line
	tmp=$(mktemp)
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		[[ -z "${line//[[:space:]]/}" ]] && continue
		printf '%s\n' "$line" >> "$tmp"
	done < "$file"
	sha256sum "$tmp" | awk '{print $1}'
	rm -f "$tmp"
}

# Registra en memoria todos los metadatos del script y actualiza, por autor,
# cual es la version mas reciente de un tema y ejercicio dados.
register_script() {
	local file="$1" theme="$2" exercise="$3" authors="$4" shell_name="$5" mtime="$6" author key
	SCRIPT_HASH["$file"]=$(content_hash "$file")
	SCRIPT_AUTORES["$file"]="$authors"
	SCRIPT_SHELL["$file"]="$shell_name"
	SCRIPT_TEMA["$file"]="$theme"
	SCRIPT_EJERCICIO["$file"]="$exercise"
	for author in $authors; do
		key="$author|$theme|$exercise"
		if [[ -z "${BEST_TIME[$key]:-}" ]] || (( mtime > BEST_TIME[$key] )); then
			BEST_TIME["$key"]="$mtime"
			BEST_FILE["$key"]="$file"
		fi
	done
}

# Valida si un fichero tiene la cabecera minima exigida por el ejercicio.
# Solo los scripts validos pasan a la fase de deduplicacion.
process_script_file() {
	local file="$1" shell_name theme exercise authors mtime
	shell_name=$(script_shell "$file")
	[[ -n "$shell_name" ]] || return 0
	theme=$(trim_spaces "$(get_header_value "$file" 'Tema' || true)")
	exercise=$(trim_spaces "$(get_header_value "$file" 'Ejercicio' || true)")
	authors=$(get_header_value "$file" 'Autores' || true)
	[[ -n "$theme" && -n "$exercise" && -n "$authors" ]] || return 0
	mtime=$(stat -c %Y "$file" 2>/dev/null || printf '0')
	register_script "$file" "$theme" "$exercise" "$authors" "$shell_name" "$mtime"
}

# Recorre el arbol de entregas, se queda con los scripts seleccionados y genera
# un informe que intenta detectar posibles copias por hash normalizado.
audit_scripts() {
	local file key selected hash other_file possible_copies authors primary_author candidate
	local -a selected_files=()
	declare -A SEEN_SELECTED=()
	: > "$AUDIT_REPORT"
	BEST_FILE=()
	BEST_TIME=()
	SCRIPT_HASH=()
	SCRIPT_AUTORES=()
	SCRIPT_SHELL=()
	SCRIPT_TEMA=()
	SCRIPT_EJERCICIO=()

	while IFS= read -r -d '' file; do
		process_script_file "$file"
	done < <(find "$SCRIPTS_DIR" -type f -name '*.sh' -print0)

	# Aqui se eliminan duplicados exactos de ruta al construir la seleccion final.
	for key in "${!BEST_FILE[@]}"; do
		if [[ -z "${SEEN_SELECTED[${BEST_FILE[$key]}]:-}" ]]; then
			SEEN_SELECTED["${BEST_FILE[$key]}"]=1
			selected_files+=("${BEST_FILE[$key]}")
		fi
	done

	for selected in "${selected_files[@]}"; do
		hash=$(content_hash "$selected")
		authors=${SCRIPT_AUTORES[$selected]}
		primary_author=${authors%% *}
		possible_copies=''
		for other_file in "${selected_files[@]}"; do
			[[ "$other_file" == "$selected" ]] && continue
			# Si dos scripts tienen el mismo hash normalizado, se marcan como sospechosos.
			if [[ "$(content_hash "$other_file")" == "$hash" ]]; then
				candidate=${SCRIPT_AUTORES[$other_file]%% *}
				[[ "$candidate" == "$primary_author" ]] && continue
				[[ " $possible_copies " == *" $candidate "* ]] || possible_copies+="$candidate "
			fi
		done
		possible_copies=${possible_copies% }
		[[ -n "$possible_copies" ]] || possible_copies='ninguna'

		cat >> "$AUDIT_REPORT" <<EOF
########################################################################
Nombre del script: $(basename "$selected")
Ruta: $selected
Autores: ${SCRIPT_AUTORES[$selected]}
Shell: ${SCRIPT_SHELL[$selected]}
Tema: ${SCRIPT_TEMA[$selected]}
Ejercicio: ${SCRIPT_EJERCICIO[$selected]}
Posible copia de: $possible_copies
########################################################################
EOF
		awk '!/^[[:space:]]*#/ && NF {print}' "$selected" >> "$AUDIT_REPORT"
		printf '\n' >> "$AUDIT_REPORT"
	done

	echo "Informe de scripts generado en $AUDIT_REPORT"
	log_msg 'Auditoria de scripts completada.'
}

# Flags de ejecucion: se activan segun las opciones pasadas por el usuario.
DO_BACKUP=false
DO_AUDIT=false
DO_TREE=false
RESTORE_PROJECT=''

# Parseo simple de opciones. El ejercicio mezcla acciones combinables.
while getopts ':bar:th' option; do
	case "$option" in
		b) DO_BACKUP=true ;;
		a) DO_AUDIT=true ;;
		r) RESTORE_PROJECT="$OPTARG" ;;
		t) DO_TREE=true ;;
		h)
			usage
			exit 0
			;;
		:)
			echo "Falta valor para -$OPTARG" >&2
			exit 1
			;;
		\?)
			echo "Opcion no valida: -$OPTARG" >&2
			exit 1
			;;
	esac
done

# Prepara carpetas antes de cualquier accion.
init_paths

# Si no se ha pedido nada, se muestra ayuda y se aborta.
if ! $DO_BACKUP && ! $DO_AUDIT && ! $DO_TREE && [[ -z "$RESTORE_PROJECT" ]]; then
	usage >&2
	exit 1
fi

# Se permiten combinaciones: por ejemplo, copiar, auditar y luego mostrar el arbol.
$DO_BACKUP && backup_all_projects
[[ -n "$RESTORE_PROJECT" ]] && restore_latest "$RESTORE_PROJECT"
$DO_AUDIT && audit_scripts
$DO_TREE && show_backup_tree