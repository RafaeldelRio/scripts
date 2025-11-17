#!/bin/bash

# Definir cuántos archivos crear
NUM_ARCHIVOS=10
# Definir el prefijo del nombre
PREFIJO="archivo"
# Definir la extensión
EXTENSION=".txt"

echo "--- Iniciando la creación de **$NUM_ARCHIVOS** archivos ---"

# Bucle 'for' para iterar de 1 a 10
# {1..$NUM_ARCHIVOS} crea una secuencia numérica de 1 al valor de la variable.
for i in $(seq 1 $NUM_ARCHIVOS); do
    
    # 1. Construir el nombre completo del archivo
    NOMBRE_ARCHIVO="${PREFIJO}${i}${EXTENSION}"
    
    # 2. Crear el archivo vacío usando 'touch'
    touch "$NOMBRE_ARCHIVO"
    
    echo "✅ Creado: $NOMBRE_ARCHIVO"
    
done

echo "--- Operación completada ---"