#!/bin/bash

# Enunciado: Crea un script que genere automáticamente 10 archivos vacíos con
# nombres secuenciales (archivo1.txt, archivo2.txt, ..., archivo10.txt) utilizando
# un bucle.

# Definir cuántos archivos crear
NUM_ARCHIVOS=10
# Definir el prefijo del nombre
PREFIJO="archivo"
# Definir la extensión
EXTENSION=".txt"

echo "--- Iniciando la creación de **$NUM_ARCHIVOS** archivos ---"

# Bucle 'for' para iterar de 1 a 10
for ((i=0; i<$NUM_ARCHIVOS; i++)); do
    
    # 1. Construir el nombre completo del archivo
    NOMBRE_ARCHIVO="${PREFIJO}$((i+1))${EXTENSION}"
    
    # 2. Crear el archivo vacío usando 'touch'
    touch "$NOMBRE_ARCHIVO"
    
    echo "Creado: $NOMBRE_ARCHIVO"
    
done

echo "--- Operación completada ---"