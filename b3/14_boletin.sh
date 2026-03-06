#!/bin/bash

: << "FIN"
EJERCICIO 14. EXAMEN OPOSICIONES SAI. 2006. EJERCICIO 2.
El ejercicio práctico se realizará bajo sistema operativo LÍNUX. Se podrá hacer uso del comando man.

Elabora un script para automatizar las tareas de mantenimiento de usuarios en un servidor Linux, en el
    que realizan prácticas de scripts diversos grupos de alumnos.

Recibirá como parámetro el curso actual y admitirá además las siguientes opciones:

-f Creación del fichero de grupos del curso actual. Tendrá el siguiente formato: claveGrupo:numeroAlumnos
-c Creación de cuentas de usuario y grupos. El login reflejará grupo al que pertenece, curso académico y 
    número de alumno. Además, los directorios home estarán organizados por grupos, garantizando al máximo la privacidad.
-b Eliminación de cuentas, grupos y directorios.


FIN

# -----------------------------------------------------------------------------
# RESUMEN DE LO QUE HACE ESTE SCRIPT
# -----------------------------------------------------------------------------
# Este script intenta automatizar tres tareas sobre un curso concreto:
# - `-f`: registrar grupos y número de alumnos,
# - `-c`: crear grupos, cuentas y directorios personales,
# - `-b`: borrar cuentas, grupos y directorios.
# Aunque el archivo necesita correcciones funcionales, aquí quedan explicados
# los comandos y el objetivo de cada bloque para que se entienda mejor.

# Suposicion: Se solicitará para un curso los grupos y el
# numero de alumnos de los mismos.

# Mensaje de ayuda mostrado cuando la sintaxis no es la esperada.
USO="Sintaxis incorrecta: $0 curso [-c]|[-f]|[-b]"

# Se intenta validar que se hayan pasado exactamente 2 argumentos:
# 1) curso actual
# 2) opción -f, -c o -b
if [ $# = “2” ]
then
    # También se comprueba que el script lo ejecute root.
    if [ $UID = “0” ]; then
        case $2 in
            -f)
                # En modo `-f` se piden grupos y número de alumnos para el curso.
                read -p "Numero de nuevos grupos a introducir en el curso $1 " num
                until [ $num -eq 0 ]
                do
                    read -p "Grupo de alumnos " grupo
                    read -p "Numero de alumnos " nalumnos

                    # Se construye una línea de fichero con formato grupo-curso:numero.
                    cadena=$grupo-$1:$nalumnos

                    # Se comprueba si ese grupo ya aparece en el fichero del curso.
                    existegrupo=`cat /etc/grupos$1 | grep ^$grupo-$1`
                    if [ -z existegrupo ]; then
                        echo $cadena>>/etc/grupos$1

                        # Si se insertó, disminuye el número de grupos pendientes.
                        num=$(($num-1))
                    else
                        echo “El grupo que ha intentado introducir existe”
                    fi
                done
                ;;
          
            -c)
              # En modo `-c` se recorren los grupos definidos y se crean cuentas.
              for grupo_alumno in `cat /etc/grupos$1`
            do
                # Se separa el número de alumnos y el nombre base del grupo.
                n_alumnos=`echo $grupo_alumno | cut -d ':' -f 2`
                grupo=`echo $grupo_alumno | cut -d '-' -f 1`

                # `groupadd` crea el grupo Unix del curso.
                groupadd $grupo$1 >> /dev/null 2 >>/dev/null
                if [ $? = “0” ]; then

                    # Si el grupo se creó correctamente, se crea su directorio base.
                    mkdir /home/$grupo$1
                fi

                # Se crean tantos usuarios como indique `n_alumnos`.
                until [ $n_alumnos -eq 0 ]
                do

                    # `useradd` crea el usuario con grupo principal y HOME propio.
                    useradd $grupo$1_$n_alumnos -g $grupo$1 -d /home/$grupo$1/$grupo$1_$n_alumnos –m

                    # `passwd usuario contraseña` pretende asignar una contraseña.
                    passwd $grupo$1_$n_alumnos $grupo$1_$n_alumnos
                    n_alumnos=$(($n_alumnos-1))
                done
            done
                ;;
            -b)
                # En modo `-b` se recorren los grupos para borrar usuarios y carpetas.
                for grupo_alumno in `cat /etc/grupos$1`
                do
                    n_alumnos=`echo $grupo_alumno$1 | cut -d ':' -f 2`
                    grupo=`echo $grupo_alumno$1 | cut -d '-' -f 1`
                    until [ $n_alumnos -eq 0 ]
                    do

                        # `userdel -fr` intenta borrar usuario y su HOME recursivamente.
                        userdel -fr $grupo$1_$n_alumnos
                        n_alumnos=$(($n_alumnos-1))
                    done

                    # Después se elimina el grupo y el directorio base del grupo.
                    groupdel $grupo$1
                    rmdir /home/$grupo$1
                done
                ;;
            *)
                echo $USO
                ;;
        esac
    else
        echo $USO
    fi
fi
