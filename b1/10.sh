#!/bin/bash

: << "FIN"
Crear una calculadora con funciones. Crea el siguiente menú para ello.
- CALCULADORA.
- 1. SUMA.
- 2. RESTA.
- 3. DIVISIÓN.
- 4. MULTIPLICACIÓN.
- 5. SALIR.
FIN

# Función para pedir los números (para no repetir código)
pedir_numeros() {
    read -p "Introduce el primer número: " n1
    read -p "Introduce el segundo número: " n2
}

func_suma() {
    # $1 es el primer argumento (n1) y $2 es el segundo (n2)
    resultado=$(($1 + $2))
    echo "Resultado de la SUMA: $resultado"
}

func_resta() {
    resultado=$(($1 - $2))
    echo "Resultado de la RESTA: $resultado"
}

func_multiplicacion() {
    resultado=$(($1 * $2))
    echo "Resultado de la MULTIPLICACIÓN: $resultado"
}

func_division() {
    # Comprobamos que no se divida por cero
    if (( $2 == 0 )); then
        echo "Error: No se puede dividir por cero."
    else
        resultado=$(($1 / $2))
        echo "Resultado de la DIVISIÓN: $resultado"
        # Opcional: Mostrar el resto
        echo "   (Resto: $(($1 % $2)))"
    fi
}

# -----------------------------------------
# BLOQUE PRINCIPAL (MENÚ)
# -----------------------------------------

while true; do
    echo "---------------------------"
    echo "       CALCULADORA         "
    echo "---------------------------"
    echo "1. SUMA"
    echo "2. RESTA"
    echo "3. DIVISIÓN"
    echo "4. MULTIPLICACIÓN"
    echo "5. SALIR"
    echo "---------------------------"
    
    read -p "Selecciona una opción: " opcion

    # Estructura de control para el menú
    case "$opcion" in
        1)
            pedir_numeros
            # Llamamos a la función pasando los números como argumentos
            func_suma $n1 $n2
            ;;
        2)
            pedir_numeros
            func_resta $n1 $n2
            ;;
        3)
            pedir_numeros
            func_division $n1 $n2
            ;;
        4)
            pedir_numeros
            func_multiplicacion $n1 $n2
            ;;
        5)
            echo "¡Adiós!"
            break  # Rompe el bucle while y sale del script
            ;;
        *)
            echo "Opción no válida. Por favor, elige entre 1 y 5."
            ;;
    esac
    
    # Pausa para que el usuario vea el resultado antes de volver a mostrar el menú
    echo ""
    read -p "Presiona Enter para continuar..." dummy
    clear  # Limpia la pantalla (opcional)
done