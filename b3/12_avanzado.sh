#!/bin/bash

: << "FIN"
EJERCICIO 12. SIMULACRO EXAMEN. MAYO 2018.
Los creadores del programa maravil necesitan un script de instalación, llamado 12.sh. Debe realizar estas tareas:
1. Presentar como pantalla de bienvenida el archivo bienvenida.txt, que ocupa me nos de una pantalla; el usuario 
    deberá pulsar Enter para continuar.
2. Presentar una pantalla con la licencia, el archivo licencia.txt, también menor de una pantalla; el usuario 
    deberá digitar la tecla S para aceptar la licencia, si no la acepta el programa avisa y termina con código de error 1.
3. Inicializar una variable DIRINSTAL con el nombre del directorio de instalación por defecto, /usr/local/maravil.
4. Preguntar al usuario el directorio de instalación, mostrando el nombre sugerido (variable DIRINSTAL); 
    el usuario podrá digitar un nombre de directorio o Enter para aceptar el directorio sugerido. En cualquier caso,
    el nombre del directorio de instalación deberá quedar en la variable DIRINSTAL.
5. Verificar si existe ya el directorio de instalación; es así, continúa la instalación, y si no, deberá pedir 
    autorización al usuario, crearlo y verificar la creación exitosa. Si el usuario no autoriza la creación del directorio,
    el programa termina con error 2; si no se pudo crear el directorio el programa termina con error 3. 
    En todos los casos se informa lo realizado.
6. Copiar los archivos maravil.py, LEAME y manual.txt hacia el directorio de instalación. Si la copia no da error,
    se informa la terminación exitosa de la instalación; en otro caso, se informa el error y se borra el 
    directorio de instalación y todo su contenido.

FIN


# 1) Pantalla de bienvenida y espera de confirmación.
cat bienvenida.txt
read -r -p "Pulse Enter para continuar..." _

# 2) Licencia: solo continúa si el usuario acepta con S/s.
cat licencia.txt
read -r -n 1 -p "Pulse S para aceptar la licencia: " lic
echo
if [ "$lic" != "S" ] && [ "$lic" != "s" ]; then
    echo "Licencia no aceptada."
    exit 1
fi

# 3) Directorio de instalación por defecto.
DIRINSTAL="/usr/local/maravil"

# 4) Permite reemplazar el directorio por otro introducido por el usuario.
read -r -p "Directorio de instalación [$DIRINSTAL]: " dir_input
if [ -n "$dir_input" ]; then
    DIRINSTAL="$dir_input"
fi

created_now=0
# 5) Comprueba/crea directorio de instalación con los códigos de error pedidos.
if [ -d "$DIRINSTAL" ]; then
    echo "El directorio $DIRINSTAL ya existe. Se continúa la instalación."
else
    read -r -p "El directorio no existe. ¿Desea crearlo? (S/N): " crear
    if [ "$crear" != "S" ] && [ "$crear" != "s" ]; then
        echo "Creación no autorizada."
        exit 2
    fi

    if mkdir -p "$DIRINSTAL"; then
        echo "Directorio creado: $DIRINSTAL"
        created_now=1
    else
        echo "No se pudo crear el directorio de instalación."
        exit 3
    fi

    if [ ! -d "$DIRINSTAL" ]; then
        echo "No se pudo verificar la creación del directorio."
        exit 3
    fi
fi

# 6) Copia de ficheros de la aplicación y rollback en caso de error.
if cp maravil.py LEAME manual.txt "$DIRINSTAL"; then
    echo "Instalación completada correctamente en $DIRINSTAL"
else
    echo "Error al copiar ficheros. Se elimina $DIRINSTAL"
    if [ "$created_now" -eq 1 ]; then
        rm -rf "$DIRINSTAL"
    else
        rm -rf "$DIRINSTAL"
    fi
    exit 1
fi