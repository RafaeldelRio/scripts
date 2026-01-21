#!/bin/bash

# Crea un script que pida al usuario un número y genere una tabla de multiplicar hasta el 10.

read -p "Introduce un número: " num

# Validamos que la entrada sea un número
if ! [[ "$num" =~ ^[0-9]+$ ]]; then
   echo "Por favor, introduce un número válido."
   exit 1
fi

echo "Tabla de multiplicar del $num:"
# Bucle del 1 al 10 para generar la tabla
# Alternativa: for ((i=1; i<=10; i++)); do ... (sintaxis estilo C)
# Alternativa: seq 1 10 | xargs -I {} bash -c "echo $num x {} = \$(($num * {}))" (usando seq y xargs)
for i in {1..10}; do
   result=$((num * i))
   echo "$num x $i = $result"
done