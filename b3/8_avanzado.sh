#!/bin/bash

: << "FIN"
EJERCICIO 8.
Definir una función que calcule la clase a la que pertenece una IP determinada.
FIN

set -euo pipefail

# Determina la clase (A-E) de una dirección IPv4 válida.
ip_class() {
	local ip="$1"
	local IFS='.'
	local -a oct
	read -r -a oct <<< "$ip"

	if [ "${#oct[@]}" -ne 4 ]; then
		return 1
	fi

	for part in "${oct[@]}"; do
		if ! [[ "$part" =~ ^[0-9]+$ ]] || [ "$part" -lt 0 ] || [ "$part" -gt 255 ]; then
			return 1
		fi
	done

	# Clasificación clásica por primer octeto.
	if [ "${oct[0]}" -ge 1 ] && [ "${oct[0]}" -le 126 ]; then
		echo "A"
	elif [ "${oct[0]}" -ge 128 ] && [ "${oct[0]}" -le 191 ]; then
		echo "B"
	elif [ "${oct[0]}" -ge 192 ] && [ "${oct[0]}" -le 223 ]; then
		echo "C"
	elif [ "${oct[0]}" -ge 224 ] && [ "${oct[0]}" -le 239 ]; then
		echo "D"
	elif [ "${oct[0]}" -ge 240 ] && [ "${oct[0]}" -le 255 ]; then
		echo "E"
	else
		return 1
	fi
}

if [ "$#" -ne 1 ]; then
	echo "Uso: $0 IP" >&2
	exit 2
fi

# Muestra clase o termina con error si la IP no es válida.
if clase="$(ip_class "$1")"; then
	echo "Clase $clase"
else
	echo "IP no válida" >&2
	exit 1
fi