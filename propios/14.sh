#!/bin/bash

# Inicializar un contador
CONTADOR=0

echo "--- Contando archivos en el directorio actual (./) ---"

# Iterar sobre todos los elementos (*) en el directorio actual
# Se usa la opción -d (que es el delimitador interno) para manejar archivos con espacios
IFS=$'\n'
for ELEMENTO in *; do
    # Comprobar si el elemento es un archivo regular (-f)
    if [ -f "$ELEMENTO" ]; then
        CONTADOR=$((CONTADOR + 1))
    fi
done

# Mostrar el resultado
echo "--------------------------------------------------------"
echo "✅ Número total de **archivos regulares** encontrados: **$CONTADOR**"
echo "--------------------------------------------------------"