#!/bin/bash

: <<"FIN"
Crea un script analizador_trafico.sh con las siguientes opciones:
- Resolución DNS Inversa: 
    Solicita una dirección IP pública (ej. 8.8.8.8) y devuelve el 
    nombre de dominio asociado a ella utilizando una consulta inversa.
- Monitor de Conexiones Activas: 
    Pide un número de puerto (ej. 443) y cuenta exactamente cuántas 
    conexiones están actualmente "ESTABLECIDAS" en ese puerto, mostrando solo el número total.
- Inspector de Errores de Interfaz: 
    Solicita el nombre de una tarjeta de red (ej. eth0). Debe comprobar si la interfaz existe; 
    si es así, mostrará sus estadísticas de tráfico.
- Conversor IPv4 a Binario (Subnetting): 
    Pide una dirección IPv4 en formato decimal (ej. 192.168.1.5) y la convierte a
    formato binario puro con relleno de ceros (ej. 11000000.10101000.00000001.00000101).
FIN


clear
echo "========================================="
echo "   ANALIZADOR DE TRÁFICO Y SUBREDES      "
echo "========================================="
echo "1. Resolución DNS Inversa (IP a Dominio)"
echo "2. Contar conexiones activas en un puerto"
echo "3. Inspeccionar errores en una interfaz"
echo "4. Convertir IPv4 a formato Binario"
echo "5. Salir"
echo "========================================="

read -p "Elige una opción (1-5): " opcion
echo ""

case $opcion in
    1)
        read -p "Introduce una IP pública (ej. 8.8.8.8): " ip_publica
        echo "[*] Realizando consulta DNS inversa..."
        
        # dig -x hace la consulta inversa. +short limpia la salida.
        resultado=$(dig -x "$ip_publica" +short)
        
        if [ -z "$resultado" ]; then
            echo "[-] No se encontró ningún dominio asociado a la IP $ip_publica."
        else
            echo "[+] El dominio asociado es:"
            echo "    $resultado"
        fi
        ;;
        
    2)
        read -p "Introduce el puerto a monitorizar (ej. 443, 80): " puerto
        echo "[*] Contando conexiones establecidas en el puerto $puerto..."
        
        # ss -tn: conexiones TCP numéricas. state established: solo las activas.
        # grep filtra el puerto específico. wc -l (word count -lines) cuenta las líneas de resultado.
        cantidad=$(ss -tn state established | grep -E ":$puerto\b" | wc -l)
        
        if [ "$cantidad" -eq 0 ]; then
            echo "[-] No hay ninguna conexión activa en el puerto $puerto ahora mismo."
        else
            echo "[+] Hay $cantidad conexión/es activa/s en el puerto $puerto."
        fi
        ;;
        
    3)
        read -p "Introduce el nombre de la interfaz (ej. eth0, lo): " interfaz
        echo "[*] Buscando estadísticas de $interfaz..."
        
        # Redirigimos la salida de error (2>) a /dev/null (el agujero negro de Linux)
        # Así, si la interfaz no existe, el usuario no ve un error feo del sistema.
        if ip link show "$interfaz" > /dev/null 2>&1; then
            echo "[+] Interfaz encontrada. Estadísticas de tráfico:"
            # ip -s link muestra estadísticas de red (RX/TX, dropped, errors).
            ip -s -h link show "$interfaz"
        else
            echo "[!] Error: La interfaz '$interfaz' no existe en este sistema."
        fi
        ;;
        
    4)
        read -p "Introduce una dirección IPv4 (ej. 192.168.1.5): " ipv4
        echo "[*] Calculando representación binaria..."
        
        # Dividimos la IP en un array usando el punto como separador
        IFS='.' read -r -a octetos <<< "$ipv4"
        
        # Usamos 'bc' (Basic Calculator) indicando obase=2 (Output Base = Binario)
        bin1=$(echo "obase=2; ${octetos[0]}" | bc)
        bin2=$(echo "obase=2; ${octetos[1]}" | bc)
        bin3=$(echo "obase=2; ${octetos[2]}" | bc)
        bin4=$(echo "obase=2; ${octetos[3]}" | bc)
        
        # printf con %08d formatea los números tratándolos como enteros (d)
        # y obligando a que tengan 8 dígitos, rellenando con ceros a la izquierda si es necesario.
        printf "[+] Resultado: %08d.%08d.%08d.%08d\n" "$bin1" "$bin2" "$bin3" "$bin4"
        ;;
        
    5)
        echo "Cerrando el analizador. ¡Hasta la próxima!"
        exit 0
        ;;
        
    *)
        echo "[!] Opción incorrecta. Por favor, selecciona del 1 al 5."
        ;;
esac