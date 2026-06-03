#!/bin/bash

# Solucion reducida para que sea mucho mas facil de entender.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CSV="$SCRIPT_DIR/datos/ej1/usuarios.csv"
BASE="$SCRIPT_DIR/trabajo/ej1"
HOMES="$BASE/homes"
SALIDA="$SCRIPT_DIR/salidas/ej1"
REGISTRO="$SALIDA/usuarios_importados.tsv"
RECHAZADOS="$SALIDA/usuarios_rechazados.tsv"
PERMISOS="$SALIDA/permisos_peligrosos.txt"
INFORME="$SALIDA/informe_final.txt"

trim() {
	local texto="$1"
	texto="${texto#"${texto%%[![:space:]]*}"}"
	texto="${texto%"${texto##*[![:space:]]}"}"
	printf '%s' "$texto"
}

preparar() {
	mkdir -p "$HOMES" "$SALIDA"
	: > "$REGISTRO"
	: > "$RECHAZADOS"
	: > "$PERMISOS"
}

crear_login() {
	local nombre="$1"
	local ape1="$2"
	local ape2="$3"
	local dni="$4"
	local base
	local login
	local numero=1

	base=$(printf '%s%s%s%s' "${nombre:0:1}" "${ape1:0:3}" "${ape2:0:3}" "${dni:5:3}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
	login="$base"

	while [[ -e "$HOMES/$login" ]]; do
		login="${base}${numero}"
		numero=$((numero + 1))
	done

	printf '%s' "$login"
}

importar_usuarios() {
	local nombre ape1 ape2 dni nivel clave
	local login hash
	local buenos=0
	local malos=0

	if [[ ! -f "$CSV" ]]; then
		echo "No existe $CSV"
		return 1
	fi

	rm -rf "$HOMES"
	mkdir -p "$HOMES"
	: > "$REGISTRO"
	: > "$RECHAZADOS"
	: > "$PERMISOS"

	while IFS=';' read -r nombre ape1 ape2 dni nivel clave || [[ -n "$nombre$ape1$ape2$dni$nivel$clave" ]]; do
		[[ "$nombre" == "nombre" ]] && continue
		[[ -z "$nombre" ]] && continue

		nombre=$(trim "$nombre")
		ape1=$(trim "$ape1")
		ape2=$(trim "$ape2")
		dni=$(trim "$dni")
		nivel=$(trim "$nivel")
		clave=$(trim "$clave")

		if [[ -z "$nombre" || -z "$ape1" || -z "$ape2" || -z "$dni" || -z "$nivel" || -z "$clave" ]]; then
			printf '%s;%s;%s;%s;%s;%s\tcampos incompletos\n' "$nombre" "$ape1" "$ape2" "$dni" "$nivel" "$clave" >> "$RECHAZADOS"
			malos=$((malos + 1))
			continue
		fi

		if ! [[ "$dni" =~ ^[0-9]{8}[A-Za-z]$ ]]; then
			printf '%s;%s;%s;%s;%s;%s\tdni invalido\n' "$nombre" "$ape1" "$ape2" "$dni" "$nivel" "$clave" >> "$RECHAZADOS"
			malos=$((malos + 1))
			continue
		fi

		login=$(crear_login "$nombre" "$ape1" "$ape2" "$dni")
		mkdir -p "$HOMES/$login"
		printf 'Nombre: %s %s %s\nNivel: %s\nDNI: %s\n' "$nombre" "$ape1" "$ape2" "$nivel" "$dni" > "$HOMES/$login/datos.txt"
		hash=$(printf '%s' "$clave" | sha256sum | awk '{print $1}')
		printf '%s\n' "$hash" > "$HOMES/$login/clave.txt"

		if [[ "$nivel" == "alumno" ]]; then
			printf '#!/bin/bash\necho practica\n' > "$HOMES/$login/tarea.sh"
			chmod 666 "$HOMES/$login/tarea.sh"
		fi

		printf '%s\t%s %s %s\t%s\t%s\n' "$login" "$nombre" "$ape1" "$ape2" "$nivel" "$HOMES/$login" >> "$REGISTRO"
		buenos=$((buenos + 1))
	done < "$CSV"

	echo "Importados: $buenos"
	echo "Rechazados: $malos"
}

consultar_usuario() {
	local login

	if [[ ! -s "$REGISTRO" ]]; then
		echo 'Primero importa usuarios.'
		return 1
	fi

	read -r -p 'Login: ' login
	if ! awk -F '\t' -v buscado="$login" '$1 == buscado {print "Login: "$1"\nNombre: "$2"\nNivel: "$3"\nHome: "$4; found=1} END {exit !found}' "$REGISTRO"; then
		echo 'No existe ese login.'
	fi
}

buscar_permisos() {
	local total

	find "$HOMES" -type f -perm -0002 2>/dev/null | sort > "$PERMISOS"
	total=$(grep -c '.' "$PERMISOS" 2>/dev/null || true)

	if [[ "$total" -eq 0 ]]; then
		echo 'No hay permisos peligrosos.'
	else
		echo "Incidencias: $total"
		cat "$PERMISOS"
	fi
}

generar_informe() {
	local validos rechazados peligrosos

	if [[ ! -s "$REGISTRO" ]]; then
		echo 'Primero importa usuarios.'
		return 1
	fi

	buscar_permisos >/dev/null
	validos=$(grep -c '.' "$REGISTRO" 2>/dev/null || true)
	rechazados=$(grep -c '.' "$RECHAZADOS" 2>/dev/null || true)
	peligrosos=$(grep -c '.' "$PERMISOS" 2>/dev/null || true)

	cat > "$INFORME" <<EOF
INFORME DE AUDITORIA

Usuarios validos: $validos
Usuarios rechazados: $rechazados
Permisos peligrosos: $peligrosos

Registro: $REGISTRO
Rechazados: $RECHAZADOS
Permisos: $PERMISOS
EOF

	echo "Informe generado en $INFORME"
}

menu() {
	local opcion

	while true; do
		echo
		echo '1. Importar usuarios'
		echo '2. Consultar usuario'
		echo '3. Ver permisos peligrosos'
		echo '4. Generar informe y salir'
		echo '5. Salir'
		read -r -p 'Opcion: ' opcion

		case "$opcion" in
			1) importar_usuarios ;;
			2) consultar_usuario ;;
			3) buscar_permisos ;;
			4)
				generar_informe && break
				;;
			5) break ;;
			*) echo 'Opcion no valida.' ;;
		esac
	done
}

preparar
menu