#!/bin/bash

# Escribe un script que registre en un archivo de texto los usuarios conectados al sistema y la hora de ejecución.

LOGFILE="registro_usuarios.txt"

# Agrupamos los comandos para redirigir su salida al archivo de log
{
    echo "================================="
    echo "Fecha y hora: $(date)"
    echo "Usuarios conectados:"
    # El comando who muestra quién está conectado
    # Alternativa: w -h (muestra más detalles e ignora encabezado)
    # Alternativa: users (muestra solo lista simple de nombres en una línea)
    who
    echo "================================="
} >> "$LOGFILE"

echo "Registro guardado en $LOGFILE"