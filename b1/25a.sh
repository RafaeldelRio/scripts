#!/bin/bash

# ==============================================================================
# Script: Gestión de Sistema
# Descripción: Menú interactivo para gestión de archivos, directorios y usuarios.
# ==============================================================================

# --- Funciones ---

# Muestra las opciones del menú principal
f_menu () {
    echo -e "\n=== Menú de opciones ==="
    echo "1) Listar archivos."
    echo "2) Ver directorio de trabajo."
    echo "3) Crear directorio."
    echo "4) Borrar directorio."
    echo "5) Crear usuario."
    echo "6) Borrar usuario."
    echo "7) Salir."
    echo -n "Introduce opción: "
}

# Lista los archivos en el directorio actual
f_listar_archivos () {
    ls
}

# Muestra la ruta del directorio de trabajo actual (pwd)
f_ver_directorio_t () {
    pwd
}

# Crea un nuevo directorio con el nombre proporcionado
f_crea_directorio () {
    read -p "Introduce el nombre del directorio: " dir_name
    mkdir "$dir_name"
}

# Borra un directorio y todo su contenido (Cuidado: usa rm -rf)
f_borra_directorio () {
    read -p "Introduce el nombre del directorio: " dir_name
    rm -rf "$dir_name"
}

# Crea un nuevo usuario (Verifica si se ejecuta como root)
f_crea_usuario () {
    # Comprueba si el ID del usuario es 0 (root)
    if id | grep -q uid=0
    then
        read -p "Introduce el nombre del usuario: " user_name
        useradd "$user_name"
    else
        echo "No tienes permisos para crear usuarios."
    fi
}

# Borra un usuario existente (Verifica si se ejecuta como root)
f_borra_usuario () {
    if id | grep -q uid=0
    then
        read -p "Introduce el nombre del usuario: " user_name
        userdel "$user_name"
    else
        echo "No tienes permisos para borrar usuarios."
    fi
}

# --- Bucle Principal ---
while true; do
    f_menu
    read OPC # Lee la opción del usuario
    case $OPC in
        1) f_listar_archivos ;;
        2) f_ver_directorio_t ;;
        3) f_crea_directorio ;;
        4) f_borra_directorio ;;
        5) f_crea_usuario ;;
        6) f_borra_usuario ;;
        7) exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
    echo # línea en blanco para separar iteraciones
done
exit 0