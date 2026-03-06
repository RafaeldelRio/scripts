#!/bin/bash

: <<"FIN"
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

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Simula un instalador en modo texto:
# - muestra pantalla de bienvenida,
# - muestra licencia y pide aceptación,
# - propone un directorio de instalación,
# - lo crea si no existe y el usuario lo autoriza,
# - copia varios archivos a ese directorio,
# - si falla la copia, deshace lo realizado borrando el directorio.

# pantalla de bienvenida

# `clear` limpia la pantalla del terminal para que la presentación sea más limpia.
clear

# `cat fichero` muestra el contenido del fichero por pantalla.
cat bienvenida.txt
echo "Digite Enter para continuar"

# `read` sin variable guarda lo escrito en la variable especial `REPLY`, pero aquí
# lo importante es simplemente pausar hasta que el usuario pulse Enter.
read
# pantalla de licencia
clear
cat licencia.txt
echo "Digite la tecla S para aceptar las condiciones de licencia."

# Se lee la respuesta en la variable `LICENCIA`.
read LICENCIA

# `-a` es un AND lógico dentro de `[ ]`.
# Si no es ni S ni s, la licencia se considera no aceptada.
if [ ! "$LICENCIA" = "S" -a ! "$LICENCIA" = "s" ]; then
    echo "No se aceptó la licencia."
    exit 1
fi
# directorio de instalación por defecto

# Directorio sugerido inicialmente por el instalador.
DIRINSTAL=./maravi
# preguntar directorio de instalación
echo Digite directorio de instalación, o tecla Enter
echo si acepta la opción propuesta.
echo -n "Directorio de instalación [$DIRINSTAL]: "
read OTRODIR

# Si el usuario escribe algo, sustituimos el valor por defecto.
if [ $OTRODIR ]; then
    DIRINSTAL=$OTRODIR
fi
# verificar si existe directorio de instalación

# `-d` comprueba si existe un directorio con ese nombre.
if [ -d $DIRINSTAL ]; then
    echo El directorio $DIRINSTAL existe, continúa instalación.
else
    # pedir permiso para crear directorio
    echo -n "El directorio $DIRINSTAL no existe. ¿Crear(sS)?: "
    read CREARDIR

    # Si la respuesta no autoriza, se sale con código 2.
    if [ ! "$CREARDIR" = "s" -a ! "$CREARDIR" = "S" ]; then
        echo "No se autorizó crear directorio. ¡Adiós!"
        exit 2
    fi

    # `mkdir` crea el directorio. `2>/dev/null` oculta mensajes de error del sistema.
    mkdir $DIRINSTAL 2>/dev/null

    # verificar creación correcta de directorio de instalación
    if [ $? -ne 0 ]; then
        # `$?` contiene el código de salida del último comando ejecutado.
        echo Error: no fue posible crear el directorio $DIRINSTAL
        exit 3
    else
        echo Fue creado el directorio ${DIRINSTAL}.
    fi
fi
# copiar el archivo de programa hacia el directorio de instalación
echo Copiando archivos.

# `cp` copia varios archivos al directorio destino.
cp maravil.py LEAME manual.txt $DIRINSTAL
if [ $? -eq 0 ]; then
    echo "Instalación terminada. ¡Felicitaciones!"
else
    echo Ha ocurrido un error al copiar los archivos.
    echo El programa no fue instalado correctamente.

    # Si hubo fallo, se borra el directorio de instalación completo.
    rm -r $DIRINSTAL
    echo Fue borrado el directorio de instalación y todo su contenido.
fi
