#!/bin/bash

# Introducida una letra por teclado liste todos los meses que empiezan por esa letra o
# mensaje de error sí no coincide la letra con ningún mes.

# Solicitamos la letra al usuario
read -p "Introduce una letra: " entrada

# Nos aseguramos de coger solo el primer carácter (por si el usuario escribe una palabra entera)
letra="${entrada:0:1}"

# Verificamos que no esté vacío
if [[ -z "$letra" ]]; then
    echo "Error: No has introducido ninguna letra."
    exit 1
fi

echo "--- Meses que empiezan por '$letra' ---"

# Estructura CASE
# Usamos patrones como [Aa] para que acepte tanto mayúsculas como minúsculas
case "$letra" in
    [Ee])
        echo "📅 Enero"
        ;;
    [Ff])
        echo "📅 Febrero"
        ;;
    [Mm])
        echo "📅 Marzo"
        echo "📅 Mayo"
        ;;
    [Aa])
        echo "📅 Abril"
        echo "📅 Agosto"
        ;;
    [Jj])
        echo "📅 Junio"
        echo "📅 Julio"
        ;;
    [Ss])
        echo "📅 Septiembre"
        ;;
    [Oo])
        echo "📅 Octubre"
        ;;
    [Nn])
        echo "📅 Noviembre"
        ;;
    [Dd])
        echo "📅 Diciembre"
        ;;
    *)
        # El asterisco (*) actúa como el "else" (cualquier otro caso)
        echo "❌ Error: No hay ningún mes que empiece por la letra '$letra'."
        ;;
esac