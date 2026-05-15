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

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
USUARIOS_FILE="$SCRIPT_DIR/usuarios.txt"
LOGIN_FILE="$PWD/loginServ.txt"

mostrar_menu() {
    # Muestra el menú principal del programa.
    echo "1- Generar login de usuarios"
    echo "2- Comprobación de red"
    echo "0- Salir"
}

pedir_opcion() {
    # Pide al usuario una opción y la devuelve por salida estándar.
    local opcion
    read -r -p "Elija su opción: " opcion
    echo "$opcion"
}

obtener_primera_letra() {
    local texto="$1"
    echo "${texto:0:1}"
}

obtener_tres_primeras() {
    local texto="$1"
    echo "${texto:0:3}"
}

obtener_dni_sin_letra() {
    local dni_completo="$1"
    echo "${dni_completo%[a-zA-Z]}"
}

obtener_tres_ultimos_digitos() {
    local numero="$1"
    echo "${numero: -3}"
}

generar_login_usuario() {
    local apellido1="$1"
    local apellido2="$2"
    local nombre="$3"
    local dni="$4"
    local primera_nombre
    local tres_apellido1
    local tres_apellido2
    local dni_numerico
    local tres_dni
    local login

    # 1. Cogemos la primera letra del nombre.
    primera_nombre=$(obtener_primera_letra "$nombre")

    # 2. Cogemos las tres primeras letras de cada apellido.
    tres_apellido1=$(obtener_tres_primeras "$apellido1")
    tres_apellido2=$(obtener_tres_primeras "$apellido2")

    # 3. Quitamos la letra del DNI y nos quedamos con sus tres últimos dígitos.
    dni_numerico=$(obtener_dni_sin_letra "$dni")
    tres_dni=$(obtener_tres_ultimos_digitos "$dni_numerico")

    # 4. Unimos todas las partes y lo pasamos a minúsculas.
    login="${primera_nombre}${tres_apellido1}${tres_apellido2}${tres_dni}"
    echo "${login,,}"
}

generar_logins() {
    local apellido1
    local apellido2
    local nombre
    local dni
    local login_generado

    # El enunciado dice que el resultado debe sobrescribirse.
    : > "$LOGIN_FILE"

    # Leemos el fichero de usuarios que está junto al script.
    while IFS=":" read -r apellido1 apellido2 nombre dni || [[ -n "$apellido1$apellido2$nombre$dni" ]]; do
        # Si alguna línea viniera vacía, la ignoramos.
        [[ -z "$apellido1" ]] && continue

        login_generado=$(generar_login_usuario "$apellido1" "$apellido2" "$nombre" "$dni")
        echo "$login_generado" >> "$LOGIN_FILE"
    done < "$USUARIOS_FILE"

    echo "Los logins se han generado y guardado en '$LOGIN_FILE' correctamente."
    echo ""
}

obtener_ip_base() {
    local ip="$1"
    # Para obtener la parte fija de la IP, podemos usar la expansión de parámetros para eliminar el último número.
    # Es decir, si la IP es 172.22.1.3, entonces ${ip%.*} nos dará "172.22.1".
    echo "${ip%.*}"
}

obtener_ultimo_octeto() {
    local ip="$1"
    # Para obtener el último octeto, podemos usar la expansión de parámetros para eliminar todo hasta el último punto.
    # Es decir, si la IP es 172.22.1.3, entonces ${ip##*.} nos dará "3".
    echo "${ip##*.}"
}

comprobar_ip() {
    local ip="$1"

    # Usamos ping con -c 1 para enviar un solo paquete y -W 1 para esperar solo 1 segundo por la respuesta.
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "$ip está activa"
    else
        echo "$ip no está activa"
    fi
}

comprobacion_red() {
    local ip_inicial
    local cantidad
    local ip_base
    local ultimo_octeto
    local contador=0
    local ip_actual

    read -r -p "Introduzca una IP: " ip_inicial
    read -r -p "Introduzca un número: " cantidad

    # Separamos la parte fija de la IP y el último número.
    ip_base=$(obtener_ip_base "$ip_inicial")
    ultimo_octeto=$(obtener_ultimo_octeto "$ip_inicial")

    # Recorremos tantas IP como indique la cantidad introducida.
    while (( contador < cantidad )); do
        ip_actual="${ip_base}.$((ultimo_octeto + contador))"
        comprobar_ip "$ip_actual"
        ((contador++))
    done

    echo ""
}

gestionar_opcion_invalida() {
    # Si la opción no es válida, se muestra error,
    # se espera 2 segundos y se limpia la pantalla.
    echo "Error: Opción no válida."
    sleep 2
    clear
}

main() {
    local opcion

    # Comprobación extra: si falta el fichero de entrada, avisamos claramente.
    if [[ ! -f "$USUARIOS_FILE" ]]; then
        echo "Error: No existe el fichero de usuarios en '$USUARIOS_FILE'."
        exit 1
    fi

    # Limpiamos la pantalla al arrancar el programa.
    clear

    while true; do
        mostrar_menu
        opcion=$(pedir_opcion)

        case "$opcion" in
            1)
                generar_logins
                ;;
            2)
                comprobacion_red
                ;;
            0)
                exit 0
                ;;
            *)
                gestionar_opcion_invalida
                ;;
        esac
    done
}

main
