#!/bin/bash

# 1. Definir la extensión y el nombre de la carpeta
EXTENSION="jpg"
CARPETA="Imagenes"

# 2. Crear la carpeta de destino si no existe
# -p asegura que no habrá error si ya existe.
mkdir -p "$CARPETA"

# 3. Informar al usuario
echo "--- Iniciando organización de archivos ---"
echo "Buscando archivos con extensión: **.${EXTENSION}**"
echo "Moviendo a la carpeta: **${CARPETA}/**"

# 4. Iniciar el bucle de búsqueda y movimiento
# La sintaxis for file in *."$EXTENSION" itera sobre todos los archivos que coinciden con el patrón
for file in *."$EXTENSION"; do
    # Comprobar si se encontró al menos un archivo.
    # Si no se encuentra ninguno, Bash a veces deja el patrón literal (*.jpg) en la variable $file.
    # El comando [ -f "$file" ] verifica si el elemento es un archivo regular.
    if [ -f "$file" ]; then
        # Mover el archivo
        mv "$file" "$CARPETA/"
        echo "Movido: **$file**"
    fi
done

# 5. Fin de la operación
echo "--- Organización completada ---"