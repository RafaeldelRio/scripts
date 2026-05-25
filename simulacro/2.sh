#!/bin/bash

# En primer lugar comprobamos si el usuario que ejecuta el script es root.
# Esto es debido a que tiene que acceder a las rutas /root para crear los archivos
if (("$EUID" != 0)); then
    echo "Error: debe ser ejecutado como root."
    exit 1
fi

# Hay dos opciones: permisos y usuarios
ejecutar_permisos=false
ejecutar_usuarios=false

# Obtenemos los parámetros que ha introducido el usuario al llamar al script
while getopts "pua" opcion; do
    case $opcion in
        p)
            # Parámetro -p para ejecutar la opción de permisos
            ejecutar_permisos=true
            ;;
        u)
            # Parámetro -u para ejecutar la opción de usuarios
            ejecutar_usuarios=true
            ;;
        a)
            # Parámetro -a para ejecutar ambas opciones
            ejecutar_permisos=true
            ejecutar_usuarios=true
            ;;
        *)
            # Si se introducen otros parámetros devolvemos un error.
            echo "Error con los parámetros de entrada"
            exit 1
            ;;
    esac
done

# Si no se han introducido parámetros, devolvemos un error
if ! $ejecutar_permisos && ! $ejecutar_usuarios; then
    echo "Debe especificar el parámetro -p, -u o -a"
    exit 1
fi

# Si se ha introducido la opción -p se ejecuta el escaneo de archivos
if $ejecutar_permisos; then
    echo "Buscando en archivos..."

    # El -type f es para buscar ficheros.
    # El -perm 0777 es para buscar el permiso 777.
    # El 2>/dev/null sirve para no mostrar posibles errores por pantalla
    find /home/ -type f -perm 0777 > /root/archivos_peligrosos.txt 2>/dev/null

    echo "Escaneo completado. Resultados en /root/archivos_peligrosos.txt"
fi


if $ejecutar_usuarios; then
    echo "Analizando usuarios"
    # Definimos el nombre del archivo
    archivo_informe="/root/auditoria_usuarios.txt"
    # Creamos y/o limpiamos el archivo definido anteriormente
    : > "$archivo_informe"

    # Recorremos con un while el archivo /etc/passwd
    # Creando las variables a partir de dicho archivo.
    while IFS=: read -r usuario password uid gid info home shell; do
        # Comprueba el uid y que la shell sea la correcta de un usuario normal
       if (( "$uid" >= 1000 )) && [[ "$shell" = "/bin/bash" ]] || [[ "$shell" = "/bin/sh" ]]; then
           # Si existe el directorio lo enviamos al informe
           if [[ -d "$home/.ssh" ]]; then
               ls -la "$home/.ssh" >> "$archivo_informe" 2>/dev/null
           else
               # Si no existe, detallamos que no existe en el informe
               "El usuario '$usuario' no tiene directorio '$home/.ssh'." >> "$archivo_informe" 2>/dev/null
           fi

           echo "-----------------------" >> "$archivo_informe" 2>/dev/null
       fi

    done < /etc/passwd

    echo "Informe completado. Resultados en '$archivo_informe'."
fi


exit 0
