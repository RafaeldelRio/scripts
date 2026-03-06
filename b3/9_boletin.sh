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

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este archivo contiene el comienzo de una función `netaddr` para calcular la
# dirección de red a partir de una IP en notación CIDR. Aunque actualmente está
# incompleto, las funciones auxiliares que sí aparecen sirven para entender el
# enfoque usado: convertir IP decimal -> binario -> operar con bits -> volver a
# decimal.

# Obtiene la dirección de red a partir de una IP en notación CIDR:
# 10.11.12.13/24 ---> 10.11.12.0/24
# $1: La IP.
#
netaddr() {
	# Variables principales de trabajo.
	# - IP almacenará la dirección.
	# - MASK almacenará la máscara o prefijo.
	# - octeto se usará al recorrer los 4 bytes de una IPv4.
	# - bits serviría para manejar la parte binaria.
	local IP MASK
	local octeto # Cada uno de los cuatro bytes de la dirección IP
	local bits

	# Almacena la IP como 32 bits.
	es_entero() {
		# `grep -E '^[0-9]+$'` comprueba que la cadena tenga solo dígitos.
		echo "$1" | grep -Eq '^[0-9]+$'
	}

	# Junta los elementos que se le proporcionan con una cadena.
	# $1: La cadena que sirve de pegamento.
	# $@: El resto de argumentos.
	join() {
		# Cambiando `IFS` se consigue que `printf "$*"` una los argumentos con
		# el separador indicado (por ejemplo, el punto en una dirección IP).
		local IFS="$1"
		shift
		printf "$*"
	}

	{
		# Evitamos usar la calculadora (bc, dc, etc.)
		d2b() { # Conversión decimal -> binario
			# Esta función convierte un número decimal en su representación binaria.
			# Se va dividiendo entre 2 y acumulando restos.
			local r num="$1"
			while [ "$num" -gt 0 ]; do
				r="$((num%2))$r"
				num=$((num >> 1))
			done
			printf "%08d" "$r"
		}

		b2d() { # Conversión binario -> decimal
			# Aquí se hace el proceso contrario: binario -> decimal.
			# `fold -b1` separa la cadena en un bit por línea.
			set -- $(echo "$1" | fold -b1)

			local r=0
			while [ $# -gt 0 ]; do
				r=$((r * 2 + $1))
				shift
			done
			echo "$r"
		}
	}

	# Convierte una IPv4 en 32 bits.
	ipd2b() {
		# Cambiamos `IFS` a punto para que el `for` recorra cada octeto.
		local IFS="."
		for octeto in $1; do
			# Se valida que cada octeto sea numérico y esté entre 0 y 255.
			es_entero "$octeto" || return 1
			[ "$octeto" -lt 0 -o "$octeto" -gt 255 ] && return 1
			# Se convierte cada octeto a binario de 8 bits.
			d2b "$octeto"
		done
	}
}