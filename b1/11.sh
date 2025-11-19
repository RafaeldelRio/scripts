#!/bin/bash

: << "FIN"
Crea un script que nos permita realizar una AGENDA con las siguientes opciones:
Programa Agenda
    1. Añadir.
    2. Listar.
    3. Borrar contenido.
    4. Eliminar Registro.
    5. Salir.
FIN

ARCHIVO="agenda.txt"

pausa() {
    echo ""
    read -p "Presiona Enter para continuar..." dummy
    clear
}

pinta_menu() {
    cat << EOF
================================
    AGENDA ELECTRÓNICA
================================
1. Añadir contacto
2. Listar contactos
3. Borrar TODA la agenda
4. Eliminar un registro
5. Salir
================================
EOF
}


while true; do
    pinta_menu

    read -p "Introduce una opcion: " opcion

    case $opcion in
        1) 
            # Pedir datos por separado mejor, para que pueda haber espacios en nombres
            read -p "Nombre: " nombre
            read -p "Apellidos: " apellidos
            read -p "Teléfono: " tfno

            # Validación básica: que no estén vacíos
            if [[ -n "$nombre" && -n "$tfno" ]]; then
                echo "$nombre:$apellidos:$tfno" >> "$ARCHIVO"
                echo "Contacto guardado."
            else
                echo "Error: Nombre y teléfono son obligatorios."
            fi
            pausa
            ;;
        2)
            # Comprueba que exista y tenga tamaño > 0
            if [[ -s "$ARCHIVO" ]]; then 
                # 'column' formatea el texto separado por ':' (-s :) en una tabla (-t)
                # Mejor que cat en este caso
                column -t -s ':' "$ARCHIVO"
            else
                echo "La agenda está vacía o el archivo no existe."
            fi
            pausa
            ;;
        3) 
            read -p "¿Estás seguro de borrar TODO? (s/N): " confirm
            if [[ "${confirm,,}" == "s" ]]; then
                # 'truncate' o '>' vacía el archivo sin borrarlo (mantiene permisos)
                > "$ARCHIVO"
                echo "Agenda vaciada."
            else
                echo "Operación cancelada."
            fi
            pausa
            ;;
        4) 
            if [[ ! -s "$ARCHIVO" ]]; then
                echo "La agenda está vacía."
            else
                read -p "Introduce el Nombre o Teléfono a borrar: " buscar
                if [[ -z "$buscar" ]]; then
                    echo "No has introducido ningún dato."
                else
                    # Comprobamos si existe antes de intentar borrar
                    if grep -q "$buscar" "$ARCHIVO"; then
                        # Usar mktemp para archivo temporal seguro
                        temp_file=$(mktemp)
                        
                        # grep -v -i (ignora mayúsculas)
                        grep -v -i "$buscar" "$ARCHIVO" > "$temp_file"
                        mv "$temp_file" "$ARCHIVO"
                        echo "Registros que contenían '$buscar' eliminados."
                    else
                        echo "No se encontró ese contacto."
                    fi
                fi
            fi
            ;;
        5) 
            echo "Saliendo"
            exit 0
            ;;
        *) 
            echo "Opción incorrecta, intenta de nuevo"
            sleep 1
            ;;
    esac
done