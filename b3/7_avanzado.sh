#!/bin/bash

: << "FIN"
EJERCICIO 7.
Se desea crear un script para automatizar la creación de usuarios para el servidor FTP,
de manera que:
- Los usuarios son usuarios reales (aparecen en /etc/passwd).
- Sus directorios personales son /srv/ftp/NOMBRE_USUARIO.
- Su grupo principal es ftpusers.
- Si el usuario ya existe, se genera un error.
- Además, si se añade el argumento --no-password, no se pide contraseña y el usuario se crea con la contraseña deshabilitada.
FIN

set -euo pipefail

# Ayuda de uso en caso de parámetros incorrectos.
usage() {
	echo "Uso: $0 [--no-password] usuario" >&2
}

# Requiere privilegios de administración para crear usuarios reales.
if [ "$EUID" -ne 0 ]; then
	echo "Error: este script debe ejecutarse como root." >&2
	exit 1
fi

no_password=0
if [ "$#" -eq 2 ] && [ "$1" = "--no-password" ]; then
	no_password=1
	usuario="$2"
elif [ "$#" -eq 1 ]; then
	usuario="$1"
else
	usage
	exit 2
fi

# Valida grupo de trabajo y existencia previa del usuario.
if ! getent group ftpusers >/dev/null; then
	echo "Error: el grupo ftpusers no existe." >&2
	exit 1
fi

if id "$usuario" >/dev/null 2>&1; then
	echo "Error: el usuario $usuario ya existe." >&2
	exit 1
fi

# Crea usuario con home en /srv/ftp/NOMBRE y shell no interactivo.
home_dir="/srv/ftp/$usuario"
useradd -m -d "$home_dir" -g ftpusers -s /usr/sbin/nologin "$usuario"

# Con --no-password bloquea contraseña; en caso contrario la solicita y aplica.
if [ "$no_password" -eq 1 ]; then
	passwd -l "$usuario" >/dev/null
	echo "Usuario $usuario creado con contraseña deshabilitada."
else
	while :; do
		read -r -s -p "Contraseña para $usuario: " p1
		echo
		read -r -s -p "Repita la contraseña: " p2
		echo
		[ "$p1" = "$p2" ] && break
		echo "Las contraseñas no coinciden." >&2
	done
	printf '%s:%s\n' "$usuario" "$p1" | chpasswd
	echo "Usuario $usuario creado correctamente."
fi