#!/bin/bash

: << "FIN"
EJERCICIO 13. EXAMEN OPOSICIONES SAI. 2006. EJERCICIO 1.
El ejercicio práctico se realizará bajo sistema operativo LINUX. Se podrá hacer uso del comando man.

Elabora un shell script que nos permitirá hacer un seguimiento de los scripts realizados por los alumnos
    de 2° de Ciclo Formativo de Grado Superior de Desarrollo de Aplicaciones Informáticas.

Admitirá como argumento el nombre de un grupo de alumnos y generará un fichero denominado grupoMesActual 
    que contendrá: Login, nombre de los alumnos, número de scripts incluidos de cada alumno, nombre y 
    contenido de los mismos.

Además, se marcará cada script como copiado con un comentario con la fecha.

Contenido del fichero:
- Seguimiento a fecha del Grupo: xxxxxxx
- Usuario: Login del Alumno / Nombre del Alumno Nombre Script: xxxxxxxxxx Contenido del script

Total scripts incluidos para Nombre del Alumno: ##
Justificación del ejercicio, aclaraciones (si son necesarias) y representaciones gráficas.

FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# La idea de este ejercicio es generar un fichero de seguimiento para un grupo:
# - localizar los alumnos pertenecientes al grupo,
# - buscar sus scripts,
# - copiar nombre y contenido de esos scripts a un fichero resumen,
# - y dejar una marca en cada script indicando que fue copiado.
# Este archivo tiene varias partes todavía frágiles, pero la intención de cada
# bloque queda documentada a continuación.

#Suposicion: el grupo es un grupo de usuarios del sistema
#Suposicion: los archivos scripts se localizaran en
# /home/usuario/bin y tendran permiso de ejecución,
# o .sh, o 1ªlinea #con interprete de comandos #!/bin/bash

# Cadena de ayuda para mostrar el uso esperado del script.
USO="sintaxis $0 grupo_usuario"

# Aquí se pretendía comprobar que se recibe exactamente un argumento.
if [ $# -neq 1 ]
then
    echo $USO
else
    # Se exige ejecución como root para poder inspeccionar directorios y grupos.
    if [ $UID != "0" ]
    then
        echo "El script debe ejecutarse por el usuario root"
    else
        #Buscar dentro de los grupos del sistema el grupo #introducido en $1

        # Se localiza la línea del grupo en /etc/group.
        gruposist=`cat /etc/group | grep ^$1:`
        if [ -z $gruposist ] then
            #grupo2, alumnos que pertenecen al grupo de forma 2ª

            # Aquí se intenta extraer la lista de miembros suplementarios del grupo.
            grupo2=`cat /etc/group | grep ^$1: | cut -d ":" -f 4 | tr "," ’ ‘`‘`
            
            #ngrupo 1 contiene el gid del grupo

            # El tercer campo de /etc/group es el GID numérico del grupo.
            ngrupo1=`cat /etc/group | grep ^$1: | cut -d ":" –f3`
            
            #Lista de alumnos tienen como grupo primario el grupo $1

            # En /etc/passwd, el cuarto campo es el GID principal del usuario.
            grupo1=`cat /etc/passwd | cut –d: -f1,4 | grep :$ngrupo1$ | cut –d: –f1`
            
            # alumnosdelgrupo=”$grupo2 $grupo1“

            # Se combina la lista de usuarios con grupo principal y suplementario.
            alumnos=`echo $grupo1 $grupo2 | uniq`
            mesactual=`date | cut -d ' ' -f 2`

            # se considera una copia de mantenimiento por mes
            echo “Seguimiento a fecha `date` del Grupo:$1” > /home/admin/backup/$1$mesactual
            
            for users in $alumnos
            do
                # Contador de scripts encontrados para ese usuario.
                cont=0

                # Aquí se intenta reunir scripts ejecutables, *.sh o con shebang bash.
                for archivo in `find /home/$users/bin -user $users -type f -perm 700` `ls /home/$users/bin | grep “\.sh”` `find /home/$users/bin -user $users -exec cat {} | grep /bin/bash`; do

                    # Se vuelca al informe el nombre del usuario, su nombre real y el script.
                    echo Usuario: $users `cat /etc/passwd | grep ^$users: | cut –d: -f5 | cut –d’,’ –f1` Contenido del script $archivo>> /home/admin/backup/$1$mesactual

                    # Se copia el contenido completo del script al fichero de seguimiento.
                    cat $archivo>>/home/admin/backup/$1$mesactual

                    #Archivo copiado en fecha
                    echo `date`>>$archivo

                    # Se incrementa el contador de scripts encontrados.
                    cont=$(($cont+1))
                done

                # Se pretendía guardar el total de scripts copiados por usuario.
                echo Total scripts incluidos de $users
                $cont>>/home/admin/backup/$1$mesactual
            done
        fi
    fi
fi
