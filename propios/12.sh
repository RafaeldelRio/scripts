#!/bin/bash

# 1. Solicitar al usuario la ruta completa del archivo original
read -p "Introduce la ruta completa del archivo a copiar: " ARCHIVO_ORIGINAL

# 2. Verificar si el archivo original existe
if [ ! -f "$ARCHIVO_ORIGINAL" ]; then
    echo "⛔ Error: El archivo '$ARCHIVO_ORIGINAL' no existe o no es un archivo válido."
    exit 1
fi

# 3. Construir la ruta y el nombre del archivo de copia
# Simplemente se añade ".bak" al final del nombre del archivo original
ARCHIVO_COPIA="${ARCHIVO_ORIGINAL}.bak"

# 4. Mostrar información de la operación
echo "Archivo original: **$ARCHIVO_ORIGINAL**"
echo "Archivo de copia (backup): **$ARCHIVO_COPIA**"

# 5. Ejecutar el comando de copia
# El comando 'cp' copia el primer argumento (ORIGEN) al segundo (DESTINO)
if cp "$ARCHIVO_ORIGINAL" "$ARCHIVO_COPIA"; then
    echo "✅ Éxito: Se ha creado la copia de seguridad correctamente."
else
    echo "❌ Error: Fallo al crear la copia de seguridad."
    exit 1
fi