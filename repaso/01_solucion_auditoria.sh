#!/bin/bash

# Script de repaso que simula un alta masiva de usuarios sin tocar el sistema real.
# Trabaja sobre un CSV local, construye un entorno de homes ficticios y deja trazas
# de aceptados, rechazados, permisos peligrosos e informe final firmado.

# `set -u` evita usar variables no inicializadas por accidente.
set -u
# `pipefail` hace que fallen tambien las tuberias si falla un eslabon intermedio.
set -o pipefail

# Todas las rutas se calculan de forma relativa al propio script para que el
# ejercicio sea portable y no dependa del directorio desde el que se invoque.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INPUT_FILE="$SCRIPT_DIR/datos/ej1/usuarios.csv"
WORK_DIR="$SCRIPT_DIR/trabajo/ej1"
OUTPUT_DIR="$SCRIPT_DIR/salidas/ej1"
TOKEN=""

# Estas variables se rellenan en `init_paths` para centralizar todas las salidas.
LOG_FILE=""
REGISTRY_FILE=""
REJECTED_FILE=""
PERMISSIONS_FILE=""
REPORT_FILE=""

# Genera una fecha homogena para logs e informes.
timestamp() {
	date '+%Y-%m-%d %H:%M:%S'
}

# Muestra la sintaxis aceptada por el script.
usage() {
	cat <<EOF
Uso: $0 [-i fichero_csv] [-w directorio_trabajo] [-o directorio_salida] [-t token]
EOF
}

# Elimina espacios laterales para no arrastrar basura al validar cada campo.
trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

# Normaliza una cadena a minusculas y caracteres alfanumericos.
# Se usa al fabricar logins reproducibles y comparables.
lower_alnum() {
	printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'
}

# Crea la estructura base de trabajo y deja calculadas todas las rutas de salida.
init_paths() {
	mkdir -p "$WORK_DIR" "$OUTPUT_DIR" "$WORK_DIR/sim_home" "$WORK_DIR/credenciales" "$WORK_DIR/metadatos"
	LOG_FILE="$OUTPUT_DIR/auditoria.log"
	REGISTRY_FILE="$OUTPUT_DIR/usuarios_importados.tsv"
	REJECTED_FILE="$OUTPUT_DIR/usuarios_rechazados.tsv"
	PERMISSIONS_FILE="$OUTPUT_DIR/permisos_peligrosos.txt"
	REPORT_FILE="$OUTPUT_DIR/informe_final.txt"
	touch "$LOG_FILE"
}

# Escribe una linea de log con nivel y marca temporal.
log_msg() {
	local level="$1"
	local message="$2"
	printf '[%s] [%s] %s\n' "$(timestamp)" "$level" "$message" >> "$LOG_FILE"
}

# El token sirve para firmar el informe final y forzar una pequena interaccion segura.
# Si ya vino por parametro no se vuelve a pedir.
prompt_token() {
	if [[ -n "$TOKEN" ]]; then
		return 0
	fi
	read -rs -p 'Token de auditoria: ' TOKEN
	echo
	if [[ -z "$TOKEN" ]]; then
		echo 'No se puede continuar sin token.'
		return 1
	fi
	return 0
}

# Genera un hash de uso general. Primero intenta usar openssl y, si no existe,
# cae a sha256sum para mantener el ejercicio portable.
hash_secret() {
	local text="$1"
	if command -v openssl >/dev/null 2>&1; then
		printf '%s' "$text" | openssl dgst -sha256 | awk '{print $2}'
	else
		printf '%s' "$text" | sha256sum | awk '{print $1}'
	fi
}

# Genera un hash para la clave del usuario. El objetivo no es autenticacion real,
# sino simular el patron de almacenar secretos de forma no reversible.
hash_password() {
	local login="$1"
	local password="$2"
	if command -v openssl >/dev/null 2>&1; then
		openssl passwd -6 -salt "${login:0:8}" "$password"
	else
		hash_secret "$login:$password"
	fi
}

# Un DNI valido para este ejercicio tiene 8 digitos y una letra final.
is_valid_dni() {
	[[ "$1" =~ ^[0-9]{8}[A-Za-z]$ ]]
}

# Solo se admiten los perfiles definidos por el enunciado.
is_valid_level() {
	case "$1" in
		admin|soporte|alumno) return 0 ;;
		*) return 1 ;;
	esac
}

# La clave debe parecer razonablemente segura antes de ser almacenada.
is_valid_password() {
	local password="$1"
	[[ ${#password} -ge 8 ]] || return 1
	[[ "$password" =~ [A-Z] ]] || return 1
	[[ "$password" =~ [a-z] ]] || return 1
	[[ "$password" =~ [0-9] ]] || return 1
	return 0
}

# Este array asociativo evita colisiones de login dentro de la importacion actual.
declare -A USED_LOGINS=()

# Fabrica el login a partir de nombre, apellidos y DNI.
# Si ya existiera, anade un sufijo numerico incremental.
generate_login() {
	local nombre="$1"
	local apellido1="$2"
	local apellido2="$3"
	local dni="$4"
	local base
	local login
	local counter=1

	base="$(lower_alnum "${nombre:0:1}")$(lower_alnum "${apellido1:0:3}")$(lower_alnum "${apellido2:0:3}")${dni:5:3}"
	base=${base:-usr${dni:5:3}}
	login="$base"

	while [[ -n "${USED_LOGINS[$login]:-}" ]]; do
		login="${base}${counter}"
		counter=$((counter + 1))
	done

	USED_LOGINS["$login"]=1
	printf '%s' "$login"
}

# Reinicia todo el entorno generado por una importacion anterior.
# Esto permite repetir el ejercicio desde cero sin residuos viejos.
reset_workspace() {
	rm -rf "$WORK_DIR/sim_home" "$WORK_DIR/credenciales" "$WORK_DIR/metadatos"
	mkdir -p "$WORK_DIR/sim_home" "$WORK_DIR/credenciales" "$WORK_DIR/metadatos"
	: > "$REGISTRY_FILE"
	: > "$REJECTED_FILE"
	: > "$PERMISSIONS_FILE"
	: > "$REPORT_FILE"
	USED_LOGINS=()
	log_msg INFO 'Entorno de trabajo reiniciado.'
}

# Guarda una linea rechazada junto con su motivo para poder auditar errores.
record_rejection() {
	local line_number="$1"
	local raw_line="$2"
	local reason="$3"
	printf '%s\t%s\t%s\n' "$line_number" "$reason" "$raw_line" >> "$REJECTED_FILE"
	log_msg WARN "Linea $line_number rechazada: $reason"
}

# Construye el home ficticio de un usuario ya validado.
# Si cualquier paso falla, se borran los restos generados para simular rollback.
create_user_layout() {
	local login="$1"
	local full_name="$2"
	local level="$3"
	local password="$4"
	local dni="$5"
	local home_dir="$WORK_DIR/sim_home/$login"
	local cred_file="$WORK_DIR/credenciales/$login.cred"
	local metadata_file="$WORK_DIR/metadatos/$login.env"

	# Estructura base minima del usuario simulado.
	if ! mkdir -p "$home_dir/.ssh" "$home_dir/documentos"; then
		return 1
	fi

	# Perfil sencillo que hace visible la informacion principal del usuario.
	if ! printf 'Usuario: %s\nNivel: %s\nDNI: %s\n' "$full_name" "$level" "$dni" > "$home_dir/perfil.txt"; then
		rm -rf "$home_dir"
		return 1
	fi

	# La clave publica es ficticia, pero sirve para practicar estructura y permisos.
	if ! printf 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ%s %s@repaso\n' "${dni:0:6}" "$login" > "$home_dir/.ssh/authorized_keys"; then
		rm -rf "$home_dir" "$cred_file" "$metadata_file"
		return 1
	fi

	# Se guarda solo la version hasheada de la clave.
	if ! printf '%s:%s\n' "$login" "$(hash_password "$login" "$password")" > "$cred_file"; then
		rm -rf "$home_dir" "$cred_file" "$metadata_file"
		return 1
	fi

	# Metadatos auxiliares para consultas posteriores.
	if ! printf 'LOGIN=%s\nNIVEL=%s\nHOME=%s\n' "$login" "$level" "$home_dir" > "$metadata_file"; then
		rm -rf "$home_dir" "$cred_file" "$metadata_file"
		return 1
	fi

	# Permisos conservadores por defecto.
	chmod 700 "$home_dir" "$home_dir/.ssh"
	chmod 600 "$home_dir/.ssh/authorized_keys" "$cred_file"
	chmod 640 "$home_dir/perfil.txt"

	# Cada perfil genera un fichero distinto para practicar casos variados.
	# En `alumno` se deja a proposito un caso inseguro para que el analisis de
	# permisos tenga algo real que detectar.
	case "$level" in
		admin)
			printf 'revision-seguridad\n' > "$home_dir/documentos/panel_admin.txt"
			chmod 640 "$home_dir/documentos/panel_admin.txt"
			;;
		soporte)
			printf 'ticket,estado\n1001,abierto\n' > "$home_dir/documentos/tickets.csv"
			chmod 660 "$home_dir/documentos/tickets.csv"
			;;
		alumno)
			printf '#!/bin/bash\necho practica\n' > "$home_dir/documentos/entrega.sh"
			chmod 775 "$home_dir/documentos"
			chmod 666 "$home_dir/documentos/entrega.sh"
			;;
	esac

	return 0
}

# Recorre el CSV completo, valida cada fila y construye el entorno simulado.
import_users() {
	local line_number=0
	local imported=0
	local rejected=0
	local raw_line
	local nombre apellido1 apellido2 dni nivel clave
	local login full_name

	if [[ ! -s "$INPUT_FILE" ]]; then
		echo "No existe un CSV valido en $INPUT_FILE"
		log_msg ERROR "CSV no disponible: $INPUT_FILE"
		return 1
	fi

	prompt_token || return 1
	reset_workspace

	while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
		line_number=$((line_number + 1))
		[[ -z "$raw_line" ]] && continue

		# Se trocea la fila y luego se limpia cada campo para evitar espacios residuales.
		IFS=';' read -r nombre apellido1 apellido2 dni nivel clave <<< "$raw_line"
		nombre=$(trim "$nombre")
		apellido1=$(trim "$apellido1")
		apellido2=$(trim "$apellido2")
		dni=$(trim "$dni")
		nivel=$(trim "$nivel")
		clave=$(trim "$clave")

		# Si la primera linea es cabecera, se ignora.
		if [[ "$line_number" -eq 1 && "$nombre" == 'nombre' ]]; then
			continue
		fi

		# Cada regla de negocio rechaza la linea inmediatamente si falla.
		if [[ -z "$nombre" || -z "$apellido1" || -z "$apellido2" || -z "$dni" || -z "$nivel" || -z "$clave" ]]; then
			rejected=$((rejected + 1))
			record_rejection "$line_number" "$raw_line" 'campos incompletos'
			continue
		fi

		if ! is_valid_dni "$dni"; then
			rejected=$((rejected + 1))
			record_rejection "$line_number" "$raw_line" 'dni invalido'
			continue
		fi

		if ! is_valid_level "$nivel"; then
			rejected=$((rejected + 1))
			record_rejection "$line_number" "$raw_line" 'nivel invalido'
			continue
		fi

		if ! is_valid_password "$clave"; then
			rejected=$((rejected + 1))
			record_rejection "$line_number" "$raw_line" 'clave insegura'
			continue
		fi

		login=$(generate_login "$nombre" "$apellido1" "$apellido2" "$dni")
		full_name="$nombre $apellido1 $apellido2"

		# Solo si la construccion completa tiene exito se registra el usuario.
		if ! create_user_layout "$login" "$full_name" "$nivel" "$clave" "$dni"; then
			rejected=$((rejected + 1))
			record_rejection "$line_number" "$raw_line" 'fallo al crear el entorno simulado'
			continue
		fi

		printf '%s\t%s\t%s\t%s\t%s\n' "$login" "$full_name" "$nivel" "$dni" "$WORK_DIR/sim_home/$login" >> "$REGISTRY_FILE"
		log_msg INFO "Usuario importado: $login ($nivel)"
		imported=$((imported + 1))
	done < "$INPUT_FILE"

	echo "Importacion completada: $imported validos, $rejected rechazados."
	log_msg INFO "Importacion completada: $imported validos, $rejected rechazados."
	return 0
}

# Busca un usuario ya importado a partir del TSV de registro.
consult_user() {
	local login
	local line
	if [[ ! -s "$REGISTRY_FILE" ]]; then
		echo 'Todavia no hay usuarios importados.'
		return 1
	fi

	read -r -p 'Login a consultar: ' login
	line=$(awk -F '\t' -v wanted="$login" '$1 == wanted {print $0}' "$REGISTRY_FILE")
	if [[ -z "$line" ]]; then
		echo "No existe el login $login en el registro actual."
		return 1
	fi

	awk -F '\t' 'BEGIN {OFS="\n"} {print "Login: "$1, "Nombre: "$2, "Nivel: "$3, "DNI: "$4, "Home: "$5}' <<< "$line"
	return 0
}

# Busca permisos demasiado abiertos dentro del entorno simulado.
# Se inspeccionan tanto ficheros como directorios con bit de escritura global.
scan_permissions() {
	local total
	if [[ ! -d "$WORK_DIR/sim_home" ]]; then
		echo 'Todavia no existe un entorno simulado para analizar.'
		return 1
	fi

	find "$WORK_DIR/sim_home" \( -type f -perm -0002 -o -type d -perm -0002 \) -print | sort > "$PERMISSIONS_FILE"
	total=$(grep -c '.' "$PERMISSIONS_FILE" 2>/dev/null || true)
	if [[ "$total" -eq 0 ]]; then
		echo 'No se han detectado permisos peligrosos.'
		log_msg INFO 'Analisis de permisos sin incidencias.'
	else
		echo "Incidencias detectadas: $total"
		cat "$PERMISSIONS_FILE"
		log_msg WARN "Analisis de permisos con $total incidencias."
	fi
	return 0
}

	# Resume el estado completo de la auditoria y firma el resultado con el token.
generate_report() {
	local valid_count rejected_count ssh_count danger_count signed_summary biggest_file
	declare -A level_count=( [admin]=0 [soporte]=0 [alumno]=0 )
	local login full_name level dni home_dir

	if [[ ! -s "$REGISTRY_FILE" ]]; then
		echo 'No hay datos importados para generar el informe.'
		return 1
	fi

	prompt_token || return 1
	# Se recalculan permisos antes del informe para que el estado refleje lo ultimo.
	scan_permissions >/dev/null
	# Estas cuentas sintetizan lo producido por la importacion y el analisis.
	valid_count=$(grep -c '.' "$REGISTRY_FILE" 2>/dev/null || true)
	rejected_count=$(grep -c '.' "$REJECTED_FILE" 2>/dev/null || true)
	ssh_count=$(find "$WORK_DIR/sim_home" -type d -name '.ssh' | wc -l)
	danger_count=$(grep -c '.' "$PERMISSIONS_FILE" 2>/dev/null || true)
	biggest_file=$(find "$WORK_DIR/sim_home" -type f -printf '%s\t%p\n' | sort -n | tail -n 1 | awk -F '\t' '{print $2 " (" $1 " bytes)"}')

	# Se agrupa por nivel para producir un resumen mas util que una lista plana.
	while IFS=$'\t' read -r login full_name level dni home_dir; do
		[[ -z "$login" ]] && continue
		level_count["$level"]=$((level_count["$level"] + 1))
	done < "$REGISTRY_FILE"

	# La firma no pretende ser PKI real, solo una huella reproducible del informe.
	signed_summary=$(hash_secret "$TOKEN|$valid_count|$rejected_count|$danger_count")

	cat > "$REPORT_FILE" <<EOF
INFORME FINAL DE AUDITORIA
Fecha: $(timestamp)

Usuarios validos: $valid_count
Usuarios rechazados: $rejected_count

Distribucion por nivel:
- admin: ${level_count[admin]}
- soporte: ${level_count[soporte]}
- alumno: ${level_count[alumno]}

Usuarios con carpeta .ssh: $ssh_count
Incidencias de permisos: $danger_count
Fichero de mayor tamano: ${biggest_file:-sin datos}

Ficheros de salida:
- Registro: $REGISTRY_FILE
- Rechazados: $REJECTED_FILE
- Permisos: $PERMISSIONS_FILE

Firma: $signed_summary
EOF

	log_msg INFO 'Informe final generado.'
	echo "Informe generado en $REPORT_FILE"
	return 0
}

# Menu principal del ejercicio.
# Cada opcion llama a una funcion autocontenida para que el flujo sea claro.
main_menu() {
	local option
	while true; do
		echo
		echo '=== Auditoria segura de altas ==='
		echo '1. Importar usuarios validos'
		echo '2. Consultar usuario por login'
		echo '3. Detectar permisos peligrosos'
		echo '4. Generar informe final y salir'
		echo '5. Salir sin generar informe'
		read -r -p 'Opcion: ' option

		case "$option" in
			1) import_users ;;
			2) consult_user ;;
			3) scan_permissions ;;
			4)
				generate_report && break
				;;
			5)
				log_msg INFO 'Salida sin informe final.'
				break
				;;
			*) echo 'Opcion no valida.' ;;
		esac
	done
}

# Procesa los argumentos opcionales para reutilizar el script con otras rutas.
while getopts ':i:w:o:t:h' option; do
	case "$option" in
		i) INPUT_FILE="$OPTARG" ;;
		w) WORK_DIR="$OPTARG" ;;
		o) OUTPUT_DIR="$OPTARG" ;;
		t) TOKEN="$OPTARG" ;;
		h)
			usage
			exit 0
			;;
		:)
			echo "Falta valor para -$OPTARG" >&2
			usage >&2
			exit 1
			;;
		\?)
			echo "Opcion no valida: -$OPTARG" >&2
			usage >&2
			exit 1
			;;
	esac
done

# Solo despues de resolver opciones se crean las rutas y arranca el menu.
init_paths
main_menu