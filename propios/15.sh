#!/bin/bash

# Bucle principal que se ejecuta hasta que la variable 'OPCION' sea 3
while [ "$OPCION" != "3" ]; do
    
    # 1. Mostrar el menú
    echo "-----------------------------------"
    echo "      **Menú de Utilidades** "
    echo "-----------------------------------"
    echo "1) Listar el contenido del directorio actual (ls -l)"
    echo "2) Mostrar la fecha y hora actual (date)"
    echo "3) Salir"
    echo "-----------------------------------"
    
    # 2. Leer la opción del usuario
    read -p "Elige una opción (1, 2 o 3): " OPCION
    
    # 3. Evaluar la opción usando la estructura 'case'
    case $OPCION in
        1)
            echo ""
            echo "📋 **Contenido del Directorio Actual:**"
            # Comando para listar el contenido
            ls -l
            echo ""
            ;;
        2)
            echo ""
            echo "🗓️ **Fecha y Hora Actual:**"
            # Comando para mostrar la fecha
            date
            echo ""
            ;;
        3)
            echo "👋 Saliendo del script. ¡Hasta pronto!"
            ;;
        *)
            echo "❌ Opción no válida. Por favor, elige 1, 2 o 3."
            ;;
    esac
    
    # Pausar un momento después de ejecutar una acción, excepto al salir
    if [ "$OPCION" != "3" ]; then
        echo ""
        read -p "Presiona [Enter] para continuar..."
    fi

done