#!/bin/bash

: <<"FIN"
Existe un archivo llamado "usuarios.txt" con los siguientes datos:
Atienza:Gonzalez:Gloria:12345678A
Lorenzo:Garrido:Francisco:98765432B
Ferrer:Davila:Mario:12121212C

a) El script debe mostrar el siguiente menú:
1- Generar login de usuarios
2- Comprobación de red
0- Salir
Elija su opción

Si elije una opción diferente se muestra error, se espera 2 segundos y se borra la pantalla para mostrar de nuevo el menú.
Si introduce una opción válida mostrará el resultado, no borrará la pantalla y volverá a mostrar el menú

b) Si se elije 0 se sale del programa devolviendo un 0
c) Si presiona 1 se debe generar el login de los usuarios cogiendo el archivo "usuarios.txt". El login queda así:
Primera letra del nombre, 3 letras primer apellido, 3 letras segundo apellido y 3 últimos dígitos DNI (sin incluir letra).
Ejemplo:
gatigon678
florgar432
mferdav212
El resultado de los login generados se guardará en un archivo llamado loginServ.txt en el mismo directorio donde se ejecute el script.
Si ya existe, se sobrescribirá.
d) Si presiona la opción del menú 2 deberá solicitar una dirección IP y un número entero. Una vez introducidos los datos, deberá recorrer
desde la IP indicada, incrementando de un en uno, hasta el número entero introducido como cantidad, y comprobar si esas IP están activas o no (usando ping).
Él único resultado que debe mostrar es la IP y la frase "IP activa" o "IP no activa"
Ejemplo:
Introduzca una IP: 172.22.1.1
Introduzca un número: 3
172.22.1.1 está activa
172.22.1.2 está activa
172.22.1.3 no está activa
No hace falta comprobar que la IP sea válida, ni un entero válido, ni que al incrementar la cifra supere 254. Se supone datos válidos.
FIN


# Borramos la pantalla al iniciar por primera vez para limpiar la terminal
clear

while true; do
    echo "1- Generar login de usuarios"
    echo "2- Comprobación de red"
    echo "0- Salir"
    read -p "Elija su opción: " opcion

    case $opcion in
        1)
            # Sobrescribimos o creamos el archivo vacío para guardar los nuevos logins
            > loginServ.txt

            # Leemos el archivo delimitado por ":"
            while IFS=":" read -r ap1 ap2 nom dni; do

                # 1. Primera letra del nombre
                l_nom="${nom:0:1}"
                # 2. Tres primeras letras del primer apellido
                l_ap1="${ap1:0:3}"
                # 3. Tres primeras letras del segundo apellido
                l_ap2="${ap2:0:3}"

                # 4. Quitamos la letra del DNI (eliminamos cualquier carácter alfabético final)
                dni_num="${dni%[a-zA-Z]}"
                # Cogemos los 3 últimos dígitos de la parte numérica
                l_dni="${dni_num: -3}"

                # Juntamos todas las partes
                login="${l_nom}${l_ap1}${l_ap2}${l_dni}"

                # Convertimos todo a minúsculas y lo guardamos en el fichero
                echo "${login,,}" >> loginServ.txt

            done < usuarios.txt

            echo "Los logins se han generado y guardado en 'loginServ.txt' correctamente."
            echo "" # Espacio para que el menú se lea mejor al reaparecer
            ;;

        2)
            read -p "Introduzca una IP: " ip
            read -p "Introduzca un número: " num

            # Separamos la IP en la base (ej: 172.22.1) y el último octeto (ej: 1)
            ip_base="${ip%.*}"
            octeto="${ip##*.}"

            # Iteramos tantas veces como indique la cantidad introducida
            for (( i=0; i<num; i++ )); do
                ip_actual="${ip_base}.$((octeto + i))"

                # Ejecutamos ping de 1 solo paquete (-c 1) y con 1 segundo de tiempo de espera máximo (-W 1)
                if ping -c 1 -W 1 "$ip_actual" > /dev/null 2>&1; then
                    echo "$ip_actual está activa"
                else
                    echo "$ip_actual no está activa"
                fi
            done
            echo ""
            ;;

        0)
            exit 0
            ;;

        *)
            # Comportamiento para opciones inválidas
            echo "Error: Opción no válida."
            sleep 2
            clear
            ;;
    esac
done
