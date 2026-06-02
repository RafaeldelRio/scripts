#!/bin/bash

# Script de repaso para practicar redes sin tocar interfaces ni sockets reales.
# Toda la informacion sale de capturas locales para que el ejercicio sea repetible.

# Activa un modo mas estricto para detectar fallos antes.
set -u
set -o pipefail

# Directorio base y rutas de datos simulados.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA_DIR="$SCRIPT_DIR/datos/ej2"
OUTPUT_DIR="$SCRIPT_DIR/salidas/ej2"
LOG_FILE="$OUTPUT_DIR/redes.log"
REPORT_FILE="$OUTPUT_DIR/informe_redes.txt"

DNS_FILE="$DATA_DIR/dns_reverso.tsv"
CONNECTIONS_FILE="$DATA_DIR/conexiones_tcp.tsv"
NEIGH_FILE="$DATA_DIR/vecinos_arp.tsv"
INTERFACES_FILE="$DATA_DIR/interfaces.tsv"

# `LAST_STATE` guarda el ultimo resultado de cada apartado del menu.
# Asi el informe final puede exportarse sin recalcular nada.
declare -A LAST_STATE=(
	[entrada]=sin_datos
	[mascara]=sin_datos
	[cidr]=sin_datos
	[red]=sin_datos
	[broadcast]=sin_datos
	[rango]=sin_datos
	[hosts]=sin_datos
	[binario]=sin_datos
	[hex]=sin_datos
	[ipv6_6to4]=sin_datos
	[ipv6_mapeada]=sin_datos
	[dns]=sin_datos
	[conexiones]=sin_datos
	[vecino]=sin_datos
	[interfaz]=sin_datos
)

# Marca temporal comun para log e informe.
timestamp() {
	date '+%Y-%m-%d %H:%M:%S'
}

# Registra lo que va haciendo el script.
log_msg() {
	mkdir -p "$OUTPUT_DIR"
	printf '[%s] %s\n' "$(timestamp)" "$1" >> "$LOG_FILE"
}

# Ayuda minima de uso por linea de comandos.
usage() {
	cat <<EOF
Uso: $0 [-d directorio_datos] [-o directorio_salida]
EOF
}

# Prepara la carpeta de salida y limpia el log para la sesion actual.
init_paths() {
	mkdir -p "$OUTPUT_DIR"
	: > "$LOG_FILE"
}

# Valida el formato decimal clasico de una IPv4.
is_valid_ipv4() {
	local ip="$1"
	local IFS='.'
	local -a octets
	local octet
	read -r -a octets <<< "$ip"
	[[ ${#octets[@]} -eq 4 ]] || return 1
	for octet in "${octets[@]}"; do
		[[ "$octet" =~ ^[0-9]+$ ]] || return 1
		(( octet >= 0 && octet <= 255 )) || return 1
	done
	return 0
}

# Convierte IPv4 decimal en entero de 32 bits para operar con mascaras.
ip_to_int() {
	local ip="$1"
	local IFS='.'
	local -a octets
	read -r -a octets <<< "$ip"
	echo $(( (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3] ))
}

# Operacion inversa: reconstruye la IPv4 desde un entero.
int_to_ip() {
	local value="$1"
	printf '%d.%d.%d.%d\n' \
		$(( (value >> 24) & 255 )) \
		$(( (value >> 16) & 255 )) \
		$(( (value >> 8) & 255 )) \
		$(( value & 255 ))
}

# Genera la mascara como entero a partir de los bits CIDR.
bits_to_mask_int() {
	local bits="$1"
	[[ "$bits" =~ ^[0-9]+$ ]] || return 1
	(( bits >= 0 && bits <= 32 )) || return 1
	if (( bits == 0 )); then
		echo 0
	else
		echo $(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
	fi
}

# Comprueba que una mascara decimal sea contigua y devuelve sus bits CIDR.
mask_int_to_bits() {
	local mask_int="$1"
	local bits=0
	local seen_zero=0
	local bit
	for ((bit = 31; bit >= 0; bit--)); do
		if (( (mask_int >> bit) & 1 )); then
			(( seen_zero == 0 )) || return 1
			bits=$((bits + 1))
		else
			seen_zero=1
		fi
	done
	echo "$bits"
}

mask_ip_to_bits() {
	local mask_ip="$1"
# Pasa una mascara decimal, como 255.255.255.0, a longitud de prefijo.
	local mask_int
	is_valid_ipv4 "$mask_ip" || return 1
	mask_int=$(ip_to_int "$mask_ip")
	mask_int_to_bits "$mask_int"
}

# Mascara por defecto de clase tradicional si el usuario da solo una IP.
classful_bits() {
	local first_octet="$1"
	if (( first_octet >= 1 && first_octet <= 126 )); then
		echo 8
	elif (( first_octet >= 128 && first_octet <= 191 )); then
		echo 16
	elif (( first_octet >= 192 && first_octet <= 223 )); then
		echo 24
	else
		return 1
	fi
}

# Atajo para obtener la mascara decimal a partir de un prefijo.
mask_from_bits() {
	int_to_ip "$(bits_to_mask_int "$1")"
}

# Construye un octeto binario con padding manual a 8 bits.
binary_octet() {
	local value="$1"
	local result=""
	local bit
	for ((bit = 7; bit >= 0; bit--)); do
		result+=$(( (value >> bit) & 1 ))
	done
	printf '%s' "$result"
}

# Convierte toda la direccion IPv4 en notacion binaria pura.
ipv4_to_binary() {
	local ip="$1"
	local IFS='.'
	local -a octets
	read -r -a octets <<< "$ip"
	printf '%s.%s.%s.%s\n' \
		"$(binary_octet "${octets[0]}")" \
		"$(binary_octet "${octets[1]}")" \
		"$(binary_octet "${octets[2]}")" \
		"$(binary_octet "${octets[3]}")"
}

# Devuelve el formato hexadecimal que luego se reutiliza en 6to4 y mapped IPv6.
ipv4_to_hex() {
	local ip="$1"
	local IFS='.'
	local -a octets
	read -r -a octets <<< "$ip"
	printf '%02X%02X:%02X%02X\n' "${octets[0]}" "${octets[1]}" "${octets[2]}" "${octets[3]}"
}

# Conversion didactica a prefijo 6to4.
ipv4_to_6to4() {
	printf '2002:%s::/48\n' "$(ipv4_to_hex "$1")"
}

# Conversion a IPv4 mapeada en IPv6.
ipv4_to_mapped() {
	printf '::ffff:%s\n' "$(ipv4_to_hex "$1")"
}

# Resuelve las tres formas de entrada admitidas:
# - IP/CIDR
# - IP + mascara decimal
# - solo IP con mascara por defecto de clase
calculate_network() {
	local raw_input="$1"
	local raw_mask="${2:-}"
	local ip bits mask_int ip_int network_int broadcast_int host_min host_max usable_hosts first_octet

	if [[ "$raw_input" == */* ]]; then
		ip="${raw_input%/*}"
		bits="${raw_input#*/}"
	elif [[ -n "$raw_mask" ]]; then
		ip="$raw_input"
		bits=$(mask_ip_to_bits "$raw_mask") || return 1
	else
		ip="$raw_input"
		# Si no hay mascara explicita, se intenta deducir la clase historica.
		first_octet=${ip%%.*}
		bits=$(classful_bits "$first_octet") || return 1
	fi

	# A partir de aqui todo se hace en entero para simplificar AND y OR bit a bit.
	is_valid_ipv4 "$ip" || return 1
	mask_int=$(bits_to_mask_int "$bits") || return 1
	ip_int=$(ip_to_int "$ip")
	network_int=$(( ip_int & mask_int ))
	broadcast_int=$(( network_int | (0xFFFFFFFF ^ mask_int) ))

	# Los prefijos /31 y /32 tienen un tratamiento especial en numero de hosts.
	if (( bits == 32 )); then
		host_min=$(int_to_ip "$network_int")
		host_max="$host_min"
		usable_hosts=1
	elif (( bits == 31 )); then
		host_min=$(int_to_ip "$network_int")
		host_max=$(int_to_ip "$broadcast_int")
		usable_hosts=2
	else
		host_min=$(int_to_ip $((network_int + 1)))
		host_max=$(int_to_ip $((broadcast_int - 1)))
		usable_hosts=$(( (1 << (32 - bits)) - 2 ))
	fi

	# Se guarda todo en memoria para que el informe final reutilice el ultimo calculo.
	LAST_STATE[entrada]="$ip"
	LAST_STATE[mascara]="$(int_to_ip "$mask_int")"
	LAST_STATE[cidr]="/$bits"
	LAST_STATE[red]="$(int_to_ip "$network_int")"
	LAST_STATE[broadcast]="$(int_to_ip "$broadcast_int")"
	LAST_STATE[rango]="$host_min - $host_max"
	LAST_STATE[hosts]="$usable_hosts"
	LAST_STATE[binario]="$(ipv4_to_binary "$ip")"
	LAST_STATE[hex]="$(ipv4_to_hex "$ip")"
	LAST_STATE[ipv6_6to4]="$(ipv4_to_6to4 "$ip")"
	LAST_STATE[ipv6_mapeada]="$(ipv4_to_mapped "$ip")"

	cat <<EOF
IP: ${LAST_STATE[entrada]}
Mascara: ${LAST_STATE[mascara]}
CIDR: ${LAST_STATE[cidr]}
Red: ${LAST_STATE[red]}
Broadcast: ${LAST_STATE[broadcast]}
Rango util: ${LAST_STATE[rango]}
Hosts utiles: ${LAST_STATE[hosts]}
Binario: ${LAST_STATE[binario]}
Hexadecimal: ${LAST_STATE[hex]}
IPv6 6to4: ${LAST_STATE[ipv6_6to4]}
IPv6 mapeada: ${LAST_STATE[ipv6_mapeada]}
EOF
	log_msg "Calculo de red ejecutado para $ip/$bits"
	return 0
}

# Busca una entrada de DNS inversa dentro de la tabla local.
lookup_dns() {
	local ip="$1"
	local result
	is_valid_ipv4 "$ip" || return 1
	result=$(awk -F '\t' -v wanted="$ip" '$1 == wanted {print $2}' "$DNS_FILE")
	if [[ -z "$result" ]]; then
		LAST_STATE[dns]='sin datos'
		echo 'No existe una entrada DNS local para esa IP.'
		log_msg "DNS inversa sin resultado para $ip"
		return 0
	fi
	LAST_STATE[dns]="$ip -> $result"
	echo "$result"
	log_msg "DNS inversa resuelta para $ip"
	return 0
}

# Cuenta conexiones ESTAB en un puerto concreto usando la captura local.
# Se revisan tanto el extremo local como el remoto por simplicidad didactica.
count_connections() {
	local port="$1"
	local total
	[[ "$port" =~ ^[0-9]+$ ]] || return 1
	(( port >= 1 && port <= 65535 )) || return 1
	total=$(awk -F '\t' -v port=":$port" '$1 == "ESTAB" && ($2 ~ port "$" || $3 ~ port "$") {count++} END {print count + 0}' "$CONNECTIONS_FILE")
	LAST_STATE[conexiones]="Puerto $port -> $total conexiones ESTAB"
	echo "$total"
	log_msg "Conteo de conexiones para puerto $port: $total"
	return 0
}

# Consulta a la vez un vecino ARP y una interfaz para practicar parseo de TSV.
lookup_neighbor_and_interface() {
	local ip="$1"
	local iface="$2"
	local neighbor interface_line
	is_valid_ipv4 "$ip" || return 1
	[[ "$iface" =~ ^[[:alnum:]_.-]+$ ]] || return 1
	neighbor=$(awk -F '\t' -v wanted="$ip" '$1 == wanted {print "IP: "$1" | MAC: "$2" | Interfaz: "$3" | Estado: "$4}' "$NEIGH_FILE")
	interface_line=$(awk -F '\t' -v wanted="$iface" '$1 == wanted {print "Interfaz: "$1" | RX bytes: "$2" | TX bytes: "$3" | RX err: "$4" | TX err: "$5" | Dropped: "$6}' "$INTERFACES_FILE")

	LAST_STATE[vecino]="${neighbor:-sin datos}"
	LAST_STATE[interfaz]="${interface_line:-sin datos}"

	printf '%s\n' "${LAST_STATE[vecino]}"
	printf '%s\n' "${LAST_STATE[interfaz]}"
	log_msg "Consulta de vecino $ip e interfaz $iface"
	return 0
}

# Vuelca el ultimo estado conocido del menu a un informe legible.
export_report() {
	cat > "$REPORT_FILE" <<EOF
INFORME LOCAL DE REDES
Fecha: $(timestamp)

Ultimo calculo de red:
- Entrada: ${LAST_STATE[entrada]}
- Mascara: ${LAST_STATE[mascara]}
- CIDR: ${LAST_STATE[cidr]}
- Red: ${LAST_STATE[red]}
- Broadcast: ${LAST_STATE[broadcast]}
- Rango util: ${LAST_STATE[rango]}
- Hosts utiles: ${LAST_STATE[hosts]}
- Binario: ${LAST_STATE[binario]}
- Hexadecimal: ${LAST_STATE[hex]}
- IPv6 6to4: ${LAST_STATE[ipv6_6to4]}
- IPv6 mapeada: ${LAST_STATE[ipv6_mapeada]}

Ultimos resultados adicionales:
- DNS inversa: ${LAST_STATE[dns]}
- Conexiones: ${LAST_STATE[conexiones]}
- Vecino: ${LAST_STATE[vecino]}
- Interfaz: ${LAST_STATE[interfaz]}
EOF
	log_msg 'Informe de redes exportado.'
	echo "Informe generado en $REPORT_FILE"
}

# Menu interactivo principal del analizador.
main_menu() {
	local option raw_input raw_mask ip port iface
	while true; do
		echo
		echo '=== Analizador local de redes ==='
		echo '1. Calcular datos de red'
		echo '2. Resolver DNS inversa'
		echo '3. Contar conexiones ESTAB por puerto'
		echo '4. Consultar vecino ARP e interfaz'
		echo '5. Exportar informe y salir'
		echo '6. Salir sin exportar'
		read -r -p 'Opcion: ' option

		case "$option" in
			1)
				read -r -p 'Introduce IP/CIDR o solo IP: ' raw_input
				# Solo se pide mascara si la entrada no la trae ya integrada.
				if [[ "$raw_input" != */* ]]; then
					read -r -p 'Mascara decimal opcional: ' raw_mask
				else
					raw_mask=''
				fi
				if ! calculate_network "$raw_input" "$raw_mask"; then
					echo 'Entrada de red no valida.'
				fi
				;;
			2)
				read -r -p 'IP para DNS inversa: ' ip
				if ! lookup_dns "$ip"; then
					echo 'IP no valida.'
				fi
				;;
			3)
				read -r -p 'Puerto a revisar: ' port
				if ! count_connections "$port"; then
					echo 'Puerto no valido.'
				fi
				;;
			4)
				read -r -p 'IP del vecino: ' ip
				read -r -p 'Interfaz: ' iface
				if ! lookup_neighbor_and_interface "$ip" "$iface"; then
					echo 'Parametros no validos.'
				fi
				;;
			5)
				export_report
				break
				;;
			6)
				log_msg 'Salida sin informe.'
				break
				;;
			*) echo 'Opcion no valida.' ;;
		esac
	done
}

# Permite cambiar directorios de datos y de salida sin tocar el codigo.
while getopts ':d:o:h' option; do
	case "$option" in
		d) DATA_DIR="$OPTARG" ;;
		o) OUTPUT_DIR="$OPTARG" ;;
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

# Se recalculan las rutas por si el usuario ha pasado un directorio alternativo.
DNS_FILE="$DATA_DIR/dns_reverso.tsv"
CONNECTIONS_FILE="$DATA_DIR/conexiones_tcp.tsv"
NEIGH_FILE="$DATA_DIR/vecinos_arp.tsv"
INTERFACES_FILE="$DATA_DIR/interfaces.tsv"

# Inicializa salidas y abre el menu.
init_paths
main_menu