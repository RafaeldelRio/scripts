#!/bin/bash

: <<"FIN"
EJERCICIO 1.
Realizar un shell script llamado copiaSeguridad.sh para automatizar
las copias de seguridad de las cuentas de usuario (UID>1000) de un servidor.
El script debe admitir dos parámetros obligatorios acción y directorio, es decir:
    ./copiaSeguridad.sh acción directorio
acción será -c (para crear la copia de seguridad en el directorio) o
    -r (para restaurar la copia de seguridad desde el directorio).

La copia de seguridad consistirá en un fichero llamado usuarios y en un fichero por
usuario del sistema xxxxxx.tgz y empaquetado en el que se encontrará su
directorio de trabajo, es decir, el usuario manolo con directorio de trabajo
/home/manolo creará un fichero manolo.tgz que contendrá esta carpeta.

El fichero usuarios tendrá la siguiente estructura:
    usuario1;nombre_completo1;clave_encriptada1;directorio_home1;shell1
    usuario2;nombre_completo2;clave_encriptada2;directorio_home2;shell2

-c Buscará en los ficheros adecuados la información necesaria para generar el
    fichero usuarios con la estructura anterior. Localizará el directorio de trabajo
    de estos y generará los ficheros xxxxxx.tgz

-r Restaurará la copia de seguridad que se encuentra en directorio y dejará el
    sistema tal y como se encontraba en el momento de sacar la copia de seguridad

El script deberá tener en cuenta todos los posibles fallos para que no muestra
ningún mensaje que no esté generado por el script
(no existe directorio, no existe permisos...)
FIN

# Comprobar que el script se ejecuta como root (EUID 0)
if [ "$EUID" -ne 0 ]; then
    echo "Error: Este script debe ejecutarse con privilegios de administrador (root)."
    exit 1
fi

# Comprobar el número de parámetros (tienen que ser exactamente 2)
if [ "$#" -ne 2 ]; then
    echo "Error: Parámetros incorrectos."
    echo "Uso: $0 <-c|-r> <directorio>"
    exit 1
fi

ACCION=$1
DIR=$2

if [ "$ACCION" = "-c" ]; then
    # --- CREAR COPIA DE SEGURIDAD ---

    # Si el directorio no existe, intentamos crearlo de forma silenciosa
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR" 2>/dev/null
        if [ "$?" -ne 0 ]; then
            echo "Error: No se pudo crear el directorio '$DIR'."
            exit 1
        fi
    fi

    # Comprobar que tenemos permisos de escritura en el directorio
    if [ ! -w "$DIR" ]; then
        echo "Error: No hay permisos de escritura en el directorio '$DIR'."
        exit 1
    fi

    # Limpiar o crear el archivo "usuarios" vacío
    > "$DIR/usuarios" 2>/dev/null
    if [ "$?" -ne 0 ]; then
         echo "Error: No se puede escribir el archivo 'usuarios' en '$DIR'."
         exit 1
    fi

    # Filtrar usuarios con UID >= 1000 (excluyendo "nobody" que suele ser 65534)
    # Nota: Usamos >= 1000 porque en Linux el primer usuario estándar es el 1000.
    awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$5":"$6":"$7}' /etc/passwd 2>/dev/null | while IFS=: read -r user gecos home shell; do

        # Extraer la clave encriptada de /etc/shadow
        enc_pass=$(awk -v u="$user" -F: '$1 == u {print $2}' /etc/shadow 2>/dev/null)

        # Escribir la línea estructurada en el fichero
        echo "$user;$gecos;$enc_pass;$home;$shell" >> "$DIR/usuarios" 2>/dev/null

        # Empaquetar el directorio de trabajo del usuario
        if [ -d "$home" ]; then
            # Quitamos la barra inicial (/) de la ruta para empaquetarlo de forma segura
            home_relativo="${home#/}"
            # Se usa -C / para posicionarse en la raíz y empaquetar "home/usuario"
            tar -czf "$DIR/${user}.tgz" -C / "$home_relativo" 2>/dev/null
        fi

    done

    echo "Copia de seguridad creada correctamente en '$DIR'."

elif [ "$ACCION" = "-r" ]; then
    # --- RESTAURAR COPIA DE SEGURIDAD ---

    # Comprobar que el directorio existe y tiene permisos de lectura
    if [ ! -d "$DIR" ] || [ ! -r "$DIR" ]; then
        echo "Error: El directorio '$DIR' no existe o no tiene permisos de lectura."
        exit 1
    fi

    # Comprobar que existe el archivo de usuarios base
    if [ ! -f "$DIR/usuarios" ]; then
        echo "Error: No se encuentra el fichero 'usuarios' dentro de '$DIR'."
        exit 1
    fi

    # Leer línea por línea el archivo de usuarios y restaurar
    while IFS=';' read -r user gecos enc_pass home shell; do

        # Evitar procesar líneas vacías si las hubiera
        if [ -z "$user" ]; then
            continue
        fi

        # Comprobar si el usuario ya existe en el sistema
        if id "$user" >/dev/null 2>&1; then
            # Si existe, se actualizan sus propiedades
            usermod -c "$gecos" -d "$home" -s "$shell" -p "$enc_pass" "$user" 2>/dev/null
        else
            # Si no existe, se crea el usuario con su clave encriptada
            useradd -m -c "$gecos" -d "$home" -s "$shell" -p "$enc_pass" "$user" 2>/dev/null
        fi

        # Descomprimir su directorio home de vuelta a su ubicación original
        if [ -f "$DIR/${user}.tgz" ]; then
            tar -xzf "$DIR/${user}.tgz" -C / 2>/dev/null
        fi

    done < "$DIR/usuarios"

    echo "Sistema restaurado correctamente desde la copia en '$DIR'."

else
    # Error de parámetro de acción
    echo "Error: La acción '$ACCION' no es válida."
    echo "Uso: $0 <-c|-r> <directorio>"
    exit 1
fi
