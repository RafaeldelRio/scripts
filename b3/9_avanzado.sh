#!/bin/bash

: << "FIN"
EJERCICIO 9.
Defina una función llamada netaddr que calcula la dirección de red a partir de cualquier
dirección de equipo expresada en notación CIDR. Deberá poder usarse así:
netaddr 192.168.25.4/23

Nota:
El estándar POSIX define la calculadora bc que le puede servir para hacer cambios de
base muy fácilmente. Sin embargo, esta orden no tiene por qué estar disponible en el sistema.
En debian no forma parte de la instalación mínima y busybox no tiene la implementada.
FIN

set -euo pipefail

# Convierte IPv4 decimal punteada a entero de 32 bits.
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

# Convierte entero de 32 bits a IPv4 decimal punteada.
int_to_ip() {
	local value="$1"
	echo "$(( (value >> 24) & 255 )).$(( (value >> 16) & 255 )).$(( (value >> 8) & 255 )).$(( value & 255 ))"
}

# Calcula dirección de red a partir de IP/CIDR.
netaddr() {
	local cidr="$1"
	local ip="${cidr%/*}"
	local bits="${cidr#*/}"

	if [ "$ip" = "$cidr" ] || ! [[ "$bits" =~ ^[0-9]+$ ]] || [ "$bits" -lt 0 ] || [ "$bits" -gt 32 ]; then
		return 1
	fi

	local ip_int
	ip_int="$(ip_to_int "$ip")" || return 1

	# Construye máscara en entero a partir del prefijo CIDR.
	local mask=0
	if [ "$bits" -eq 0 ]; then
		mask=0
	else
		mask=$(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
	fi

	local net_int=$(( ip_int & mask ))
	int_to_ip "$net_int"
}

# Entrada: un único argumento en notación CIDR.
if [ "$#" -ne 1 ]; then
	echo "Uso: $0 IP/MASCARA" >&2
	exit 2
fi

if ! netaddr "$1"; then
	echo "Entrada no válida" >&2
	exit 1
fi