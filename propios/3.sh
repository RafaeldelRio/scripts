#!/bin/bash

# Enunciado: Crea un script que organice automáticamente los archivos de una extensión específica 
# (por ejemplo, .jpg) moviéndolos a una carpeta dedicada (por ejemplo, 'Imagenes'). 
# El script debe crear la carpeta si no existe e informar al usuario de las acciones realizadas.

# 1. Definir la extensión y el nombre de la carpeta
read -p "Indica qué tipo de archivos quieres mover: " extension
read -p "Indica a qué carpeta movemos los archivos: " carpeta   

# 2. Crear la carpeta de destino si no existe
# -p asegura que no habrá error si ya existe.
mkdir -p "$carpeta"

# 3. Informar al usuario
echo "--- Iniciando organización de archivos ---"
echo "Buscando archivos con extensión: **.${extension}**"
echo "Moviendo a la carpeta: **${carpeta}/**"

# 4. Iniciar el bucle de búsqueda y movimiento
# La sintaxis for file in *."$extension" itera sobre todos los archivos que coinciden con el patrón
for file in *."$extension"; do
    # Comprobar si se encontró al menos un archivo.
    # Si no se encuentra ninguno, Bash a veces deja el patrón literal (*.jpg) en la variable $file.
    # El comando [ -f "$file" ] verifica si el elemento es un archivo regular.
    if [[ -f "$file" ]]; then
        # Mover el archivo
        mv "$file" "$carpeta/"
        echo "Movido: **$file**"
    fi
done

# 5. Fin de la operación
echo "--- Organización completada ---"