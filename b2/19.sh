#!/bin/bash

# Información del sistema.
# Escribe un script que muestre:
# - El usuario actual.
# - El espacio libre en disco.
# - Los procesos en ejecución.

echo "=== Información del sistema ==="
# Muestra el usuario actual
echo "Usuario actual: $(whoami)"
echo ""
echo "=== Espacio en disco ==="
# df -h muestra el uso de disco en formato legible (h=human readable)
df -h
echo ""
echo "=== Procesos en ejecución (top 10 por uso de CPU) ==="
# ps -eo personaliza la salida, --sort ordena, head limita a las primeras líneas
# Alternativa: top -b -n 1 | head -n 17 (muestra una instantánea similar a top interactivo)
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11