#!/bin/bash

: << "FIN"
EJERCICIO 10.
Modifique el ejercicio anterior para que:
- Cuando no se incluye la máscara, se sobreentienda que es la predeterminada.
- La función, además, de admitir un único argumento (IP en notación CIDR), admita dos que representen
 respectivamente la dirección y la máscara (en forma de dirección IP):
netaddr 192.168.25.4 255.255.254.0
FIN

# Utilidades de conversión IPv4 <-> entero para operar con bit a bit.
ip_to_int() {
	local IFS='.'
	local -a o
	read -r -a o <<< "$1"
	[ "${#o[@]}" -eq 4 ] || return 1
	for part in "${o[@]}"; do
		if ! [[ "$part" =~ ^[0-9]+$ ]] || [ "$part" -lt 0 ] || [ "$part" -gt 255 ]; then
			return 1
		fi
	done
	echo $(( (o[0] << 24) | (o[1] << 16) | (o[2] << 8) | o[3] ))
}

int_to_ip() {
	local value="$1"
	echo "$(( (value >> 24) & 255 )).$(( (value >> 16) & 255 )).$(( (value >> 8) & 255 )).$(( value & 255 ))"
}

# Convierte prefijo CIDR (0..32) en máscara entera.
bits_to_mask_int() {
	local bits="$1"
	if ! [[ "$bits" =~ ^[0-9]+$ ]] || [ "$bits" -lt 0 ] || [ "$bits" -gt 32 ]; then
		return 1
	fi
	if [ "$bits" -eq 0 ]; then
		echo 0
	else
		echo $(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
	fi
}

# Máscara por defecto según clase tradicional (A/B/C).
classful_bits() {
	local first_octet="$1"
	if [ "$first_octet" -ge 1 ] && [ "$first_octet" -le 126 ]; then
		echo 8
	elif [ "$first_octet" -ge 128 ] && [ "$first_octet" -le 191 ]; then
		echo 16
	elif [ "$first_octet" -ge 192 ] && [ "$first_octet" -le 223 ]; then
		echo 24
	else
		return 1
	fi
}

# Soporta:
# 1) netaddr IP/CIDR
# 2) netaddr IP        (máscara por defecto)
# 3) netaddr IP MASK   (máscara en formato IP)
netaddr() {
	local ip mask_int ip_int net_int bits
	local IFS='.'
	local -a oct

	if [ "$#" -eq 1 ]; then
		if [[ "$1" == */* ]]; then
			ip="${1%/*}"
			bits="${1#*/}"
			mask_int="$(bits_to_mask_int "$bits")" || return 1
		else
			ip="$1"
			read -r -a oct <<< "$ip"
			[ "${#oct[@]}" -eq 4 ] || return 1
			bits="$(classful_bits "${oct[0]}")" || return 1
			mask_int="$(bits_to_mask_int "$bits")" || return 1
		fi
	elif [ "$#" -eq 2 ]; then
		ip="$1"
		mask_int="$(ip_to_int "$2")" || return 1
	else
		return 1
	fi

	ip_int="$(ip_to_int "$ip")" || return 1
	net_int=$(( ip_int & mask_int ))
	int_to_ip "$net_int"
}

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
	echo "Uso: $0 IP[/M] | IP MASCARA" >&2
	exit 2
fi

if ! netaddr "$@"; then
	echo "Entrada no válida" >&2
	exit 1
fi