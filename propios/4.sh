#!/bin/bash

# Enunciado: Crea un juego interactivo de "Adivina el Número" donde el script genere un 
# número aleatorio entre 1 y 10, y el usuario deba adivinarlo recibiendo 
# pistas (mayor/menor) y contando los intentos.

# 1. Generar un número aleatorio entre 1 y 10.
# $RANDOM genera un número entre 0 y 32767.
# % 10 genera el módulo (resto) de la división por 10, es decir, un número entre 0 y 9.
# Sumamos 1 para obtener un número entre 1 y 10.
NUMERO_SECRETO=$(( (RANDOM % 10) + 1 ))
INTENTOS=0
ADIVINADO=0

echo "--- ¡Adivina el Número! ---"
echo "He generado un número entre 1 y 10. Tienes que adivinarlo."

# 2. Bucle principal del juego
# El bucle 'while' continuará ejecutándose mientras la variable ADIVINADO no sea igual a 1
while (( $ADIVINADO == 0 )); do
    # Incrementar el contador de intentos
    INTENTOS=$((INTENTOS + 1))
    
    # 3. Pedir la entrada al usuario
    read -p "Intento $INTENTOS: Introduce tu adivinanza (1-10): " ADIVINANZA
    
    # 4. Validar que la entrada sea un número
    if ! [[ "$ADIVINANZA" =~ ^[0-9]+$ ]]; then
        echo "Error: Por favor, introduce solo números."
        # Decrementar el contador ya que la entrada no fue válida
        INTENTOS=$((INTENTOS - 1))
        continue # Volver al inicio del bucle
    fi

    # 5. Comparar la adivinanza con el número secreto
    if (( $ADIVINANZA < $NUMERO_SECRETO )); then
        echo "Demasiado Bajo."
    elif (( $ADIVINANZA > $NUMERO_SECRETO )); then
        echo "Demasiado Alto."
    else
        # 6. Adivinanza correcta
        echo "¡Felicidades! ¡Has adivinado el número $NUMERO_SECRETO en $INTENTOS intentos!"
        ADIVINADO=1 # Cambia la condición para salir del bucle
    fi
done

echo "--- Fin del juego ---"