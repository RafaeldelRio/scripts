#!/bin/bash

: << "FIN"
Con “case” queremos saber, una vez introducido un tipo de carnet de conducir a que co-
rresponde. Sabiendo:
- E: remolques.
- D: Autobuses.
- C1-C5. Camiones.
- B1-B2: automóviles.
- A: motocicletas.
- En caso de introducir uno distinto “Categoría no contemplada”.

Como extra, queremos que se pase el parámetro en la invocación
FIN


if [[ ! $# -eq 1 ]]; then
    echo "El formato de invocación del script es con 1 parámetro"
    exit 1
fi

# Convertimos la entrada a mayúsculas para evitar errores
# Esto asegura que 'a' se trate igual que 'A'
carnet="${1^^}"

# Estructura CASE
case "$carnet" in
    "E")
        echo "Remolques"
        ;;

    "D")
        echo "Autobuses"
        ;;

    # Usamos patrones para agrupar rangos:
    # C[1-5] coincide con C1, C2, C3, C4, C5
    C[1-5])
        echo "🚛 Camiones"
        ;;

    # B[1-2] coincide con B1 y B2
    B[1-2])
        echo "Automóviles"
        ;;

    "A")
        echo "Motocicletas"
        ;;

    *)
        echo "Categoría no contemplada"
        ;;
esac