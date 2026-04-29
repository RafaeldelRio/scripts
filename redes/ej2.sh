#!/bin/bash


: <<"FIN"
Crea un script llamado auditor_red.sh que presente un menú con las siguientes opciones. 
El script debe tomar decisiones basadas en la entrada del usuario:
- Comprobador de Puertos: 
    Solicita un número de puerto y dice claramente si está ABIERTO o CERRADO en el servidor local.
- Verificador de Páginas Web: 
    Pide una URL y extrae únicamente la primera línea de la respuesta HTTP 
    (para ver si devuelve un código 200 OK, 404 Not Found, etc.).
- Buscador de MAC (Caché ARP): 
    Pide una IP de la red local y busca en la tabla de vecinos su dirección MAC correspondiente.
- Calculadora IPv6 Mapeada: 
    Pide una IPv4 y la convierte automáticamente al formato IPv6 mapeado en hexadecimal (::ffff:hex:hex).
FIN


clear
echo "========================================="
echo "   AUDITOR DE SERVICIOS Y DIAGNÓSTICO    "
echo "========================================="
echo "1. Comprobar si un puerto local está abierto"
echo "2. Verificar el estado de una web externa"
echo "3. Buscar la dirección MAC de una IP local"
echo "4. Calcular dirección IPv6 Mapeada"
echo "5. Salir"
echo "========================================="

read -p "Elige una opción (1-5): " opcion
echo ""

case $opcion in
    1)
        read -p "Introduce el número de puerto a comprobar (ej. 22, 80): " puerto
        echo "[*] Buscando el puerto $puerto en los servicios activos..."
        
        # ss -tuln muestra puertos. grep -q lo busca silenciosamente.
        # Si grep lo encuentra, devuelve verdadero y entra en el 'then'
        if ss -tuln | grep -q ":$puerto "; then
            echo "[+] El puerto $puerto está ABIERTO y escuchando"
        else
            echo "[-] El puerto $puerto está CERRADO o no hay servicios usándolo."
        fi
        ;;
        
    2)
        read -p "Introduce la URL completa (ej. http://localhost): " url
        echo "[*] Obteniendo la cabecera HTTP..."
        
        # curl -I coge las cabeceras, -s lo hace silencioso
        # head -n 1 recorta el texto para mostrar solo la primera línea
        estado=$(curl -I -s "$url" | head -n 1)
        
        # Comprobamos si la variable está vacía (-z)
        if [ -z "$estado" ]; then
            echo "[!] Error: No se pudo conectar a la URL proporcionada."
        else
            echo "[+] Respuesta del servidor: $estado"
        fi
        ;;
        
    3)
        read -p "Introduce la IP de la red local (ej. 192.168.1.50): " ip_local
        echo "[*] Consultando la tabla de vecinos (ARP)..."
        
        # ip neigh show busca un registro específico
        resultado=$(ip neigh show "$ip_local")
        
        if [ -z "$resultado" ]; then
            # La forma más fácil de añadirlo es haciendo un ping.
            echo "[-] No hay registros en la caché para esa IP."
        else
            echo "[+] Registro encontrado en la caché:"
            echo "    $resultado"
        fi
        ;;
        
    4)
        read -p "Introduce una dirección IPv4 (ej. 192.168.250.15): " ipv4
        echo "[*] Generando dirección IPv6 mapeada en IPv4..."
        
        # Partimos la IPv4 usando el punto como separador
        IFS='.' read -r -a octetos <<< "$ipv4"
        
        # El formato mapeado es ::ffff: seguido de dos hextetos
        # %02x convierte cada octeto a hexadecimal en minúsculas
        printf "[+] Resultado: ::ffff:%02x%02x:%02x%02x\n" "${octetos[0]}" "${octetos[1]}" "${octetos[2]}" "${octetos[3]}"
        ;;
        
    5)
        echo "Saliendo del programa."
        exit 0
        ;;
        
    *)
        echo "Por favor, selecciona del 1 al 5."
        ;;
esac