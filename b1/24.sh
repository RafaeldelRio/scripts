#!/usr/bin/env bash

# Verificar que se haya pasado al menos un nombre de usuario
if [[ $# -eq 0 ]]; then
  echo "Uso: $0 usuario1 [usuario2 ...]"
  exit 1
fi

# Recorrer cada usuario recibido de forma segura
for user in "$@"; do
  # Obtener el UID usando getent (más fiable que cat/grep)
  uid=$(getent passwd "$user" | cut -d: -f3)

  if [[ -z $uid ]]; then
    printf "Usuario '%s' no encontrado en /etc/passwd.\n" "$user"
  else
    printf "El UID del usuario %s es %s\n" "$user" "$uid"
  fi
done