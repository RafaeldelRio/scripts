#!/bin/bash

: <<"FIN"
Crea un script en Bash llamado asistente_red.sh que muestre un menú interactivo por consola. 
El script debe solicitar información al usuario cuando sea necesario y cumplir con las siguientes tres funcionalidades:
- Diagnóstico rápido: 
    Debe preguntar al usuario por un nombre de dominio. 
    Luego, el script hará un ping (de solo 3 paquetes) a ese dominio 
    y utilizará dig para mostrar únicamente su dirección IP.
- Auditoría del sistema: Debe ejecutar los comandos modernos de Linux 
    para recopilar las direcciones IP del servidor y la tabla de enrutamiento,
    y guardar esa información automáticamente en un archivo llamado auditoria.txt.
- Calculadora 6to4: 
    Debe pedir al usuario que introduzca una dirección IPv4 pública 
    (por ejemplo, 198.51.100.14). El script debe calcular y mostrar por
    pantalla el prefijo IPv6 2002::/48 correspondiente.
FIN

# Limpiamos la pantalla para que el menú se vea limpio
clear

echo "========================================="
echo "       ASISTENTE DE RED DEBIAN           "
echo "========================================="
echo "1. Diagnosticar conectividad de un dominio"
echo "2. Generar archivo de auditoría local"
echo "3. Calcular prefijo IPv6 6to4"
echo "4. Salir"
echo "========================================="

# Solicitamos la opción al usuario
read -p "Elige una opción (1-4): " opcion

echo "" # Imprimimos una línea en blanco para separar

# Evaluamos la opción elegida
case $opcion in
    1)
        read -p "Introduce el nombre de dominio (ej. debian.org): " dominio
        echo "[*] Enviando 3 paquetes ICMP a $dominio..."
        ping -c 3 $dominio
        
        echo ""
        echo "[*] Resolviendo DNS de $dominio..."
        # Usamos +short para que dig solo devuelva la IP y quede más limpio
        dig +short $dominio
        ;;
        
    2)
        echo "[*] Recopilando información del sistema..."
        echo "--- DIRECCIONES IP ---" > auditoria.txt
        ip a >> auditoria.txt
        echo "--- TABLA DE RUTAS ---" >> auditoria.txt
        ip r >> auditoria.txt
        echo "[*] Información guardada en 'auditoria.txt'."
        ;;
        
    3)
        read -p "Introduce la IPv4 pública (ej. 198.51.100.14): " ipv4
        
        # Le decimos a Bash que separe la cadena de texto usando el punto como delimitador
        # y guarde los 4 trozos en un array llamado 'octetos'
        IFS='.' read -r -a octetos <<< "$ipv4"
        
        # Otra opción si no se quieren usar arrays:
        # octeto1=$(echo $ipv4 | cut -d. -f1)
        # octeto2=$(echo $ipv4 | cut -d. -f2)
        # octeto3=$(echo $ipv4 | cut -d. -f3)
        # octeto4=$(echo $ipv4 | cut -d. -f4)
        
        echo "[*] Convirtiendo la dirección $ipv4 a formato 6to4..."
        
        # La siguiente línea se parece al lenguaje C. Aprovecha printf para formatear la salida y mostrarla.
        # %02x convierte un número decimal a hexadecimal en minúsculas (2 dígitos)
        printf "El prefijo de red 6to4 asignado es: 2002:%02x%02x:%02x%02x::/48\n" "${octetos[0]}" "${octetos[1]}" "${octetos[2]}" "${octetos[3]}"
        ;;
        
    4)
        echo "Saliendo del programa."
        exit 0
        ;;
        
    *)
        echo "Debes elegir un número del 1 al 4."
        ;;
esac