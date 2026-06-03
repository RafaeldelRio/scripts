#!/bin/bash

# Version simplificada del ejercicio de redes.
# Trabaja solo con los ficheros locales del directorio repaso.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA_DIR="$SCRIPT_DIR/datos/ej2"
OUT_DIR="$SCRIPT_DIR/salidas/ej2"

DNS_FILE="$DATA_DIR/dns_reverso.tsv"
CONNECTIONS_FILE="$DATA_DIR/conexiones_tcp.tsv"
NEIGH_FILE="$DATA_DIR/vecinos_arp.tsv"
INTERFACES_FILE="$DATA_DIR/interfaces.tsv"
REPORT_FILE="$OUT_DIR/informe_redes.txt"

ultimo_calculo='sin_datos'
ultimo_dns='sin_datos'
ultimo_conexiones='sin_datos'
ultimo_vecino='sin_datos'
ultima_interfaz='sin_datos'

preparar() {
	mkdir -p "$OUT_DIR"
}

es_ipv4() {
	local ip="$1"
	local IFS='.'
	local a b c d
	read -r a b c d <<< "$ip"
	for n in "$a" "$b" "$c" "$d"; do
		[[ "$n" =~ ^[0-9]+$ ]] || return 1
		(( n >= 0 && n <= 255 )) || return 1
	done
	[[ -n "$a" && -n "$b" && -n "$c" && -n "$d" ]]
}

ip_a_entero() {
	local ip="$1"
	local IFS='.'
	local a b c d
	read -r a b c d <<< "$ip"
	echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

entero_a_ip() {
	local n="$1"
	printf '%d.%d.%d.%d\n' \
		$(( (n >> 24) & 255 )) \
		$(( (n >> 16) & 255 )) \
		$(( (n >> 8) & 255 )) \
		$(( n & 255 ))
}

bits_a_mascara() {
	local bits="$1"
	local mask=0
	if (( bits == 0 )); then
		echo 0.0.0.0
		return
	fi
	mask=$(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
	entero_a_ip "$mask"
}

octeto_a_bits() {
	local n="$1"
	local txt=''
	local bit
	for ((bit = 7; bit >= 0; bit--)); do
		txt+=$(( (n >> bit) & 1 ))
	done
	printf '%s' "$txt"
}

mascara_a_bits() {
	local mask="$1"
	local IFS='.'
	local a b c d bits=0
	read -r a b c d <<< "$mask"
	for n in "$a" "$b" "$c" "$d"; do
		case "$n" in
			255) bits=$((bits + 8)) ;;
			254) bits=$((bits + 7)) ;;
			252) bits=$((bits + 6)) ;;
			248) bits=$((bits + 5)) ;;
			240) bits=$((bits + 4)) ;;
			224) bits=$((bits + 3)) ;;
			192) bits=$((bits + 2)) ;;
			128) bits=$((bits + 1)) ;;
			0) ;;
			*) return 1 ;;
		esac
	done
	echo "$bits"
}

bits_por_clase() {
	local first="$1"
	if (( first >= 1 && first <= 126 )); then
		echo 8
	elif (( first >= 128 && first <= 191 )); then
		echo 16
	else
		echo 24
	fi
}

calcular_red() {
	local entrada="$1"
	local ip bits mask ip_n mask_n red_n bc_n host1 host2 hosts
	local IFS='.'
	local a b c d
	local binario hexadecimal ipv6_6to4 ipv6_mapeada

	if [[ "$entrada" == */* ]]; then
		ip=${entrada%/*}
		bits=${entrada#*/}
	elif [[ "$entrada" == *" "* ]]; then
		ip=${entrada%% *}
		mask=${entrada#* }
		bits=$(mascara_a_bits "$mask") || return 1
	else
		ip="$entrada"
		read -r a b c d <<< "$ip"
		bits=$(bits_por_clase "$a")
	fi

	es_ipv4 "$ip" || return 1
	[[ "$bits" =~ ^[0-9]+$ ]] || return 1
	(( bits >= 0 && bits <= 32 )) || return 1

	mask=$(bits_a_mascara "$bits")
	ip_n=$(ip_a_entero "$ip")
	mask_n=$(ip_a_entero "$mask")
	red_n=$(( ip_n & mask_n ))
	bc_n=$(( red_n | (0xFFFFFFFF ^ mask_n) ))

	if (( bits >= 31 )); then
		host1=$(entero_a_ip "$red_n")
		host2=$(entero_a_ip "$bc_n")
		hosts=$(( 2 ** (32 - bits) ))
	else
		host1=$(entero_a_ip $((red_n + 1)))
		host2=$(entero_a_ip $((bc_n - 1)))
		hosts=$(( (2 ** (32 - bits)) - 2 ))
	fi

	binario=$(printf '%s.%s.%s.%s' \
		"$(octeto_a_bits $(( (ip_n >> 24) & 255 )))" \
		"$(octeto_a_bits $(( (ip_n >> 16) & 255 )))" \
		"$(octeto_a_bits $(( (ip_n >> 8) & 255 )))" \
		"$(octeto_a_bits $(( ip_n & 255 )))")
	hexadecimal=$(printf '%02X%02X:%02X%02X' \
		$(( (ip_n >> 24) & 255 )) \
		$(( (ip_n >> 16) & 255 )) \
		$(( (ip_n >> 8) & 255 )) \
		$(( ip_n & 255 )))
	ipv6_6to4=$(printf '2002:%02X%02X:%02X%02X::/48' \
		$(( (ip_n >> 24) & 255 )) \
		$(( (ip_n >> 16) & 255 )) \
		$(( (ip_n >> 8) & 255 )) \
		$(( ip_n & 255 )))
	ipv6_mapeada=$(printf '::ffff:%02X%02X:%02X%02X' \
		$(( (ip_n >> 24) & 255 )) \
		$(( (ip_n >> 16) & 255 )) \
		$(( (ip_n >> 8) & 255 )) \
		$(( ip_n & 255 )))

	ultimo_calculo=$(cat <<EOF
IP: $ip
Mascara: $mask
CIDR: /$bits
Red: $(entero_a_ip "$red_n")
Broadcast: $(entero_a_ip "$bc_n")
Rango util: $host1 - $host2
Hosts utiles: $hosts
Binario: $binario
Hexadecimal: $hexadecimal
IPv6 6to4: $ipv6_6to4
IPv6 mapeada: $ipv6_mapeada
EOF
)

	echo "$ultimo_calculo"
}

buscar_dns() {
	local ip="$1"
	ultimo_dns=$(awk -F '\t' -v ip="$ip" '$1 == ip {print $2; found=1} END {if (!found) print "sin_datos"}' "$DNS_FILE")
	echo "DNS inversa: $ultimo_dns"
}

contar_conexiones() {
	local puerto="$1"
	local total
	total=$(awk -F '\t' -v puerto="$puerto" '$3 == "ESTAB" && $2 == puerto {count++} END {print count+0}' "$CONNECTIONS_FILE")
	ultimo_conexiones="Puerto $puerto -> $total conexiones ESTAB"
	echo "$ultimo_conexiones"
}

consultar_vecino_interfaz() {
	local ip="$1"
	ultimo_vecino=$(awk -F '\t' -v ip="$ip" '$1 == ip {print $2; found=1} END {if (!found) print "sin_datos"}' "$NEIGH_FILE")
	ultima_interfaz=$(awk -F '\t' -v ip="$ip" '$1 == ip {print $2; found=1} END {if (!found) print "sin_datos"}' "$INTERFACES_FILE")
	echo "MAC/Vecino: $ultimo_vecino"
	echo "Interfaz: $ultima_interfaz"
}

exportar_informe() {
	cat > "$REPORT_FILE" <<EOF
INFORME LOCAL DE REDES
Fecha: $(date '+%Y-%m-%d %H:%M:%S')

Ultimo calculo de red:
$ultimo_calculo

Ultimos resultados adicionales:
- DNS inversa: $ultimo_dns
- Conexiones: $ultimo_conexiones
- Vecino: $ultimo_vecino
- Interfaz: $ultima_interfaz
EOF
	echo "Informe generado en $REPORT_FILE"
}

menu() {
	local opcion entrada puerto ip
	while true; do
		echo
		echo '=== Analizador local de redes ==='
		echo '1. Calcular datos de red'
		echo '2. Resolver DNS inversa'
		echo '3. Contar conexiones ESTAB por puerto'
		echo '4. Consultar vecino ARP e interfaz'
		echo '5. Exportar informe y salir'
		echo '6. Salir sin exportar'
		read -r -p 'Opcion: ' opcion

		case "$opcion" in
			1)
				read -r -p 'IP o IP/CIDR o IP mascara: ' entrada
				calcular_red "$entrada" || echo 'Entrada no valida'
				;;
			2)
				read -r -p 'IP: ' ip
				buscar_dns "$ip"
				;;
			3)
				read -r -p 'Puerto: ' puerto
				contar_conexiones "$puerto"
				;;
			4)
				read -r -p 'IP: ' ip
				consultar_vecino_interfaz "$ip"
				;;
			5)
				exportar_informe
				break
				;;
			6)
				break
				;;
			*)
				echo 'Opcion no valida'
				;;
		esac
	done
}

preparar
menu
