#!/bin/bash

: << "FIN"
Realiza el siguiente MENÚ DIRECTORIOS y realiza las órdenes para que funcione:
MENÚ
    1. Crear Directorio.
    2. Borrar Directorio.
    3. Copiar archivo a directorio.
    4. Salir.
FIN

pausa() {
    echo ""
    read -p "Presiona Enter para continuar..."
    clear
}

pinta_menu() {
    cat << EOF
================================
    AGENDA ELECTRÓNICA
================================
1. Crear directorio
2. Borrar directorio
3. Copiar archivo a directorio
4. Salir
================================
EOF
}

while true; do
    pinta_menu

    read -p "Elige una opción: " opcion

    case $opcion in
        1) 
            echo "--- CREAR DIRECTORIO ---"
            read -p "Nombre del directorio a crear: " dir
            
            # Comprobamos si ya existe para no dar error
            if [ -d "$dir" ]; then
                echo "El directorio '$dir' ya existe."
            else
                # Intentamos crear. 'mkdir -p' evita errores si faltan padres
                if mkdir -p "$dir"; then
                    echo "Directorio '$dir' creado con éxito."
                else 
                    echo "Error al crear el directorio."
                fi
            fi
            pausa
            ;;
        
        2) 
            echo "--- BORRAR DIRECTORIO ---"
            read -p "Nombre del directorio a borrar: " dir
            
            # 1. Validamos que exista
            if [ ! -d "$dir" ]; then
                echo "Error: El directorio '$dir' no existe."
            else
                # 2. Preguntamos confirmación por seguridad
                read -p "¿Seguro que quieres borrar '$dir' y todo su contenido? (s/N): " confirm
                if [[ "${confirm,,}" == "s" ]]; then
                    if rm -R "$dir"; then
                        echo "Directorio borrado."
                    else
                        echo "Hubo un error al intentar borrar."
                    fi
                else
                    echo "Operación cancelada."
                fi
            fi
            pausa
            ;;

        3) 
            echo "--- COPIAR ARCHIVO ---"
            
            read -p "Introduce: [archivo_origen] [directorio_destino]: " fichero directorio
            
            # Validaciones antes de intentar copiar
            if [[ ! -f "$fichero" ]]; then
                echo "Error: El archivo '$fichero' no existe."
            elif [[ ! -d "$directorio" ]]; then
                echo "Error: El directorio destino '$directorio' no existe."
            else
                # Ejecutamos la copia controlando el éxito
                if cp -f "$fichero" "$directorio"; then
                    echo "Fichero copiado correctamente."
                else 
                    echo "Error al copiar el fichero."
                fi
            fi
            pausa
            ;;

        4) 
            echo "Adios"
            exit 0
            ;;
        *) 
            echo "Opción no válida"
            sleep 1
            ;;
    esac
done