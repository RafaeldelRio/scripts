#!/bin/bash

: <<"FIN"
1. Recopilar un script para automatizar la realización de las copias de seguridad del sistema con las siguientes características:
- Debe salvaguardarse toda la información existente en el directorio ./arespaldar. Si no existe dicho directorio debe dar un error.
- Almacenar las copias de seguridad en un directorio "./backups". Si no existe el directorio debe ser creado.
- Debe generarse un fichero diario con el nombre "CSeg<YYYYMMDD>.tar.gz" donde <YYYYMMDD> corresponde al año, mes y día de la
    realización de la copia. Dichos ficheros se almacenarán en el directorio anterior.
- Solo se almacenarán las copias de los últimos 30 días.
- El script debe ir escribiendo en un fichero de log "./CSeg.log" la confirmación de la copia realizada con éxito
    o bien el error obtenido.
- En cada ejecución del script se deberá escribir en el log anterior una línea inicial que indique a qué copia de seguridad 
    (CSeg<YYYYMMDD>) se refieren el resto de líneas.
- Todos los mensajes generados por el script deberán escribirse en el log y no mostrarse en la línea de comandos.

2. Indicar cómo configurar el sistema para que el proceso de copia de seguridad se realice de forma totalmente automática,
    de manera que se programe su ejecución todos los días a las 2:00 AM.

FIN


# Configuración de variables (rutas relativas tal y como se solicita)
DIR_ORIGEN="./arespaldar"
DIR_DESTINO="./backups"
LOG_FILE="./CSeg.log"
FECHA=$(date +%Y%m%d)
NOMBRE_ARCHIVO="CSeg${FECHA}.tar.gz"

# Redirigir TODA la salida (estándar y errores) al archivo de log (modo append)
# De esta forma garantizamos que no sale nada por la consola.
exec >> "$LOG_FILE" 2>&1

# Línea inicial indicando a qué copia se refieren los mensajes siguientes
echo "------------------------------------------------------------------------"
echo "=== Registro de operaciones para la copia de seguridad: CSeg${FECHA} ==="
echo "=== Fecha y hora de inicio: $(date '+%Y-%m-%d %H:%M:%S') ==="

# 1. Comprobar si el directorio a respaldar existe
if [ ! -d "$DIR_ORIGEN" ]; then
    echo "ERROR: El directorio origen '$DIR_ORIGEN' no existe. Abortando script."
    exit 1
fi

# 2. Comprobar si el directorio destino existe. Si no, crearlo.
if [ ! -d "$DIR_DESTINO" ]; then
    echo "AVISO: El directorio de destino '$DIR_DESTINO' no existe. Procediendo a crearlo..."
    mkdir -p "$DIR_DESTINO"
    if [ $? -ne 0 ]; then
        echo "ERROR: Falló la creación del directorio '$DIR_DESTINO'. Abortando script."
        exit 1
    fi
    echo "ÉXITO: Directorio de destino creado correctamente."
fi

# 3. Generar la copia de seguridad (Comprimir y empaquetar)
echo "INFO: Iniciando la compresión de '$DIR_ORIGEN' en '$DIR_DESTINO/$NOMBRE_ARCHIVO'..."
tar -czf "$DIR_DESTINO/$NOMBRE_ARCHIVO" "$DIR_ORIGEN"

# 4. Confirmación de éxito o error
if [ $? -eq 0 ]; then
    echo "ÉXITO: Copia de seguridad CSeg${FECHA} generada correctamente."
else
    echo "ERROR: Ocurrió un problema al generar la copia de seguridad."
    exit 1
fi

# 5. Borrado de copias con más de 30 días de antigüedad
echo "INFO: Buscando copias de seguridad de más de 30 días para su eliminación..."
# Utilizamos find para buscar ficheros en ./backups que empiecen por CSeg y tengan más de 30 días (-mtime +30)
find "$DIR_DESTINO" -type f -name "CSeg*.tar.gz" -mtime +30 -exec rm -f {} \;

if [ $? -eq 0 ]; then
    echo "ÉXITO: Proceso de limpieza finalizado (si existían ficheros antiguos, han sido borrados)."
else
    echo "ERROR: Ocurrió un problema durante la limpieza de los ficheros antiguos."
fi

echo "=== Fin del proceso para CSeg${FECHA} ==="