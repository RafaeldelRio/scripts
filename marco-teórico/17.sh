#!/bin/bash

# Operaciones aritméticas
Suma (+) . 2+3
Resta (-) . 2-3
Multiplicación (*) . 3*5
División entera (/) . 3/2
Resto de división entera (%) . 3%2
Exponenciación (**) . 3**2

# Uso de bc (basic calculator) para decimales
# Suma con decimales
echo "10.5 + 2.3" | bc
# Salida: 12.8

# Sin scale
echo "10 / 3" | bc
# Salida: 3 (¡Mal!)

# Con scale
echo "scale=2; 10 / 3" | bc
# Salida: 3.33 (¡Bien!)


umbral=80.5
cpu_actual=82.3

# Preguntamos a bc: ¿Es 82.3 mayor que 80.5?
if [ $(echo "$cpu_actual > $umbral" | bc) -eq 1 ]; then
    echo "¡ALERTA! CPU alta."
fi


# Calcular la raíz cuadrada (sqrt) de 2
echo "sqrt(2)" | bc -l
# Salida: 1.41421356...