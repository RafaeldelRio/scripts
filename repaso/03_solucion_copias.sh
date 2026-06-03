#!/bin/bash

# Version simplificada del ejercicio de copias y auditoria.
# Trabaja solo con los datos locales del repaso.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECTS_DIR="$SCRIPT_DIR/datos/ej3/proyectos"
SCRIPTS_DIR="$SCRIPT_DIR/datos/ej3/scripts_alumnos"
OUTPUT_DIR="$SCRIPT_DIR/salidas/ej3"
STORE_DIR="$OUTPUT_DIR/backups"
RESTORE_DIR="$OUTPUT_DIR/restaurados"
LOG_FILE="$OUTPUT_DIR/gestion_copias.log"
AUDIT_REPORT="$OUTPUT_DIR/informe_scripts.txt"
DEFAULT_KEEP=2

usage() {
	cat <<EOF
Uso: $0 [-b] [-r proyecto] [-a] [-t] [-h]
	-b   Crear copias de todos los proyectos.
	-r   Restaurar la ultima copia del proyecto indicado.
	-a   Generar un informe sencillo de scripts.
	-t   Mostrar las copias guardadas.
	-h   Mostrar esta ayuda.
EOF
}

preparar() {
	mkdir -p "$STORE_DIR" "$RESTORE_DIR" "$OUTPUT_DIR"
	touch "$LOG_FILE"
}

registrar() {
	printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

leer_config() {
	local file="$1"
	local key="$2"
	grep -m1 "^$key=" "$file" 2>/dev/null | cut -d= -f2-
}

rotar_copias() {
	local dir="$1"
	local keep="$2"
	local total oldest

	while true; do
		total=$(ls -1 "$dir"/copia_*.tgz 2>/dev/null | wc -l)
		[[ "$total" =~ ^[0-9]+$ ]] || total=0
		(( total <= keep )) && break
		oldest=$(ls -1tr "$dir"/copia_*.tgz 2>/dev/null | head -n 1)
		[[ -n "$oldest" ]] || break
		rm -f "$oldest"
		registrar "Copia antigua eliminada: $oldest"
	done
}

hacer_copia_proyecto() {
	local dir="$1"
	local name config keep content item archive

	name=$(basename "$dir")
	config="$dir/.repasoBackup.conf"
	if [[ ! -f "$config" ]]; then
		echo "Proyecto omitido: $name (sin configuracion)"
		registrar "Proyecto omitido: $name sin configuracion"
		return
	fi

	keep=$(leer_config "$config" "numeroCopias")
	content=$(leer_config "$config" "contenidoCopia")
	[[ "$keep" =~ ^[0-9]+$ ]] || keep=$DEFAULT_KEEP
	[[ -n "$content" ]] || {
		echo "Proyecto omitido: $name (sin contenidoCopia)"
		registrar "Proyecto omitido: $name sin contenidoCopia"
		return
	}

	set -- .repasoBackup.conf
	for item in ${content//:/ }; do
		if [[ -e "$dir/$item" ]]; then
			set -- "$@" "$item"
		fi
	done

	if [[ $# -eq 1 ]]; then
		echo "Proyecto omitido: $name (sin rutas validas)"
		registrar "Proyecto omitido: $name sin rutas validas"
		return
	fi

	mkdir -p "$STORE_DIR/$name"
	archive="$STORE_DIR/$name/copia_$(date '+%Y%m%d_%H%M%S').tgz"
	if tar -czf "$archive" -C "$dir" "$@" 2>/dev/null; then
		echo "Copia creada: $archive"
		registrar "Copia creada para $name"
		rotar_copias "$STORE_DIR/$name" "$keep"
	else
		rm -f "$archive"
		echo "Error al crear la copia de $name" >&2
		registrar "Error al crear copia para $name"
		return 1
	fi
}

hacer_copias() {
	local dir
	for dir in "$PROJECTS_DIR"/*; do
		[[ -d "$dir" ]] || continue
		hacer_copia_proyecto "$dir"
	done
}

restaurar_proyecto() {
	local name="$1"
	local latest destination

	latest=$(ls -1t "$STORE_DIR/$name"/copia_*.tgz 2>/dev/null | head -n 1)
	if [[ -z "$latest" ]]; then
		echo "No existen copias para $name"
		registrar "Restauracion fallida para $name"
		return 1
	fi

	destination="$RESTORE_DIR/$name"
	rm -rf "$destination"
	mkdir -p "$destination"
	if tar -xzf "$latest" -C "$destination" 2>/dev/null; then
		echo "Restauracion completada en $destination"
		registrar "Restauracion completada para $name"
	else
		rm -rf "$destination"
		echo "No se pudo restaurar $name" >&2
		registrar "Error al restaurar $name"
		return 1
	fi
}

mostrar_copias() {
	if [[ ! -d "$STORE_DIR" ]] || [[ -z "$(find "$STORE_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
		echo 'No hay copias guardadas.'
		return
	fi

	find "$STORE_DIR" | sed "s|^$STORE_DIR|.|" | sort
	registrar 'Listado de copias mostrado'
}

leer_cabecera() {
	local file="$1"
	local label="$2"
	grep -m1 "^[[:space:]]*#${label}:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

hash_script() {
	grep -v '^[[:space:]]*#' "$1" | sed '/^[[:space:]]*$/d' | sha256sum | awk '{print $1}'
}

auditar_scripts() {
	local tmp file shell theme exercise authors hash repeated

	tmp=$(mktemp)
	{
		echo 'INFORME DE SCRIPTS'
		echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
		echo
	} > "$AUDIT_REPORT"

	find "$SCRIPTS_DIR" -type f -name '*.sh' | sort | while IFS= read -r file; do
		shell=$(head -n 1 "$file")
		theme=$(leer_cabecera "$file" 'Tema')
		exercise=$(leer_cabecera "$file" 'Ejercicio')
		authors=$(leer_cabecera "$file" 'Autores')

		if [[ "$shell" != '#!'* || -z "$theme" || -z "$exercise" || -z "$authors" ]]; then
			cat >> "$AUDIT_REPORT" <<EOF
--------------------------------------------------
Script ignorado: $file
Motivo: falta shebang o cabeceras minimas

EOF
			continue
		fi

		hash=$(hash_script "$file")
		repeated=$(awk -F '\t' -v hash="$hash" '$1 == hash {print $2; exit}' "$tmp")
		[[ -n "$repeated" ]] || repeated='ninguna'
		printf '%s\t%s\n' "$hash" "$file" >> "$tmp"

		cat >> "$AUDIT_REPORT" <<EOF
--------------------------------------------------
Script: $(basename "$file")
Ruta: $file
Tema: $theme
Ejercicio: $exercise
Autores: $authors
Shell: ${shell#\#!}
Posible copia de: $repeated

EOF
	done

	rm -f "$tmp"
	echo "Informe generado en $AUDIT_REPORT"
	registrar 'Auditoria de scripts completada'
}

DO_BACKUP=false
DO_AUDIT=false
DO_TREE=false
RESTORE_PROJECT=''

while [[ $# -gt 0 ]]; do
	case "$1" in
		-b)
			DO_BACKUP=true
			;;
		-a)
			DO_AUDIT=true
			;;
		-t)
			DO_TREE=true
			;;
		-r)
			shift
			if [[ -z "${1:-}" ]]; then
				echo 'La opcion -r necesita un proyecto.' >&2
				exit 1
			fi
			RESTORE_PROJECT="$1"
			;;
		-h)
			usage
			exit 0
			;;
		*)
			echo "Opcion no valida: $1" >&2
			exit 1
			;;
	esac
	shift
done

preparar

if ! $DO_BACKUP && ! $DO_AUDIT && ! $DO_TREE && [[ -z "$RESTORE_PROJECT" ]]; then
	usage >&2
	exit 1
fi

status=0

if $DO_BACKUP; then
	hacer_copias || status=1
fi

if [[ -n "$RESTORE_PROJECT" ]]; then
	restaurar_proyecto "$RESTORE_PROJECT" || status=1
fi

if $DO_AUDIT; then
	auditar_scripts || status=1
fi

if $DO_TREE; then
	mostrar_copias || status=1
fi

exit "$status"