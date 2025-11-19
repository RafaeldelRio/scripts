#!/bin/bash

: <<"FIN"
Programe un script llamado 'estadística_dir' que realice un estudio de todo el árbol de
directorios y ficheros partiendo del directorio pasado como parámetro de forma que obtenga-
mos la siguiente información:
- Número de ficheros en los cuales:
- Número disponemos de permiso de lectura.
- Número disponemos de permiso de escritura.
- Número disponemos de permiso de ejecución.
- Número carecemos de permiso de lectura.
- Número carecemos de permiso de escritura.
- Número carecemos de permiso de ejecución.
- Número de ficheros regulares encontrados.
- Número de directorios encontrados.
- Número de dispositivos de bloques encontrados.
- Número de dispositivos de caracteres encontrados.
- Número de fifos encontrados.
FIN

# Declarar variables enteras para contar permisos
# p_lec: con permiso de lectura
# p_esc: con permiso de escritura  
# p_eje: con permiso de ejecución
# np_lec: sin permiso de lectura
# np_esc: sin permiso de escritura
# np_eje: sin permiso de ejecución
typeset -i p_lec p_esc p_eje np_lec np_esc np_eje

# Declarar variables enteras para contar tipos de archivos
# f_reg: ficheros regulares
# dir: directorios
# dis_b: dispositivos de bloques
# dis_c: dispositivos de caracteres
# fifo: named pipes (FIFOs)
# slink: enlaces simbólicos
typeset -i f_reg dir dis_b dis_c fifo slink

# Recorrer todos los archivos y directorios encontrados recursivamente
# desde el directorio pasado como parámetro ($1)
# El comando 'find $1' lista todos los elementos del árbol de directorios
for i in $(find "$1"); do
    
    # Verificar permisos de LECTURA
    if [[ -r $i ]]; then
        # Incrementar contador de archivos con permiso de lectura
        let p_lec+=1      
    else 
        # Incrementar contador de archivos sin permiso de lectura
        let np_lec+=1     
    fi
    
    # Verificar permisos de ESCRITURA
    if [[ -w $i ]]; then
        # Incrementar contador de archivos con permiso de escritura
        let p_esc+=1      
    else 
        # Incrementar contador de archivos sin permiso de escritura
        let np_esc+=1     
    fi
    
    # Verificar permisos de EJECUCIÓN
    if [[ -x $i ]]; then
        # Incrementar contador de archivos con permiso de ejecución
        let p_eje+=1      
    else 
        # Incrementar contador de archivos sin permiso de ejecución
        let np_eje+=1     
    fi
    
    # Clasificar por TIPO DE ARCHIVO
    # Nota: El orden importa, ya que algunos tests pueden solaparse
    if [[ -f $i ]]; then
        # Es un fichero regular
        let f_reg+=1      
    elif [[ -d $i ]]; then
        # Es un directorio
        let dir+=1        
    elif [[ -L $i ]]; then
        # Es un enlace simbólico
        let slink+=1      
    elif [[ -b $i ]]; then
        # Es un dispositivo de bloques
        let dis_b+=1      
    elif [[ -c $i ]]; then
        # Es un dispositivo de caracteres
        let dis_c+=1      
    elif [[ -p $i ]]; then
        # Es un FIFO (named pipe)
        let fifo+=1       
    fi
done

# Mostrar resultados de permisos
echo "Con permisos: de lect $p_lec , esc $p_esc , ejec $p_eje "
echo "Sin permisos: no_lect $np_lec , no escrit $np_esc , no ejec $np_eje"

# Mostrar resultados de tipos de archivos
echo "Numero de fich $f_reg , dir $dir , enlaces $slink , dispositivos $dis_b $dis_c"
echo "Fifo $fifo"