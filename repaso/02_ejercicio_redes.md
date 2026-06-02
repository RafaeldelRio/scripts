# Ejercicio 2. Analizador de red y subredes sin dependencias externas

## Objetivo

Desarrolla un script en Bash que permita practicar la parte mas tecnica del temario de redes y shell script sin depender de la red real del equipo.

El script debe trabajar con capturas locales y repasar estos conceptos:

- validacion robusta de IPv4 y mascaras
- notacion CIDR y mascara decimal
- conversion IPv4 a entero y entero a IPv4
- calculo de direccion de red, broadcast y rango util
- conversion IPv4 a binario puro y a hexadecimal
- generacion de IPv6 en formato 6to4 y en formato IPv4 mapeado
- resolucion DNS inversa a partir de una tabla local
- conteo exacto de conexiones TCP establecidas en un puerto
- consulta de vecinos ARP e interfaces desde ficheros de prueba

## Datos de entrada

El script usara estos ficheros locales:

- `dns_reverso.tsv`: `ip<TAB>nombre`
- `conexiones_tcp.tsv`: `estado<TAB>local<TAB>remoto`
- `vecinos_arp.tsv`: `ip<TAB>mac<TAB>interfaz<TAB>estado`
- `interfaces.tsv`: `interfaz<TAB>rx_bytes<TAB>tx_bytes<TAB>rx_err<TAB>tx_err<TAB>dropped`

## Operaciones obligatorias

El script debe mostrar un menu persistente con estas opciones:

1. Calcular datos de red a partir de `IP/CIDR`, de `IP mascara` o solo de `IP` usando mascara por defecto de clase
2. Resolver DNS inversa en la tabla local
3. Contar conexiones `ESTAB` de un puerto concreto en la captura local
4. Consultar vecino ARP e interfaz y mostrar estadisticas
5. Exportar un informe con el ultimo estado calculado y salir
6. Salir sin exportar

## Restricciones

- No puede llamar a `ping`, `dig`, `ss` ni `ip` sobre la maquina real
- Debe validar octetos, prefijos CIDR, puertos e interfaces
- El calculo binario debe producir siempre octetos de 8 bits
- Debe existir un fichero de log
- Si no se ha ejecutado una operacion, el informe debe indicar `sin datos`

## Salidas esperadas

La opcion de calculo de subred debe mostrar al menos:

- IP introducida
- mascara decimal
- prefijo CIDR
- direccion de red
- broadcast
- primer y ultimo host util
- numero de hosts utiles
- IPv4 en binario
- IPv4 en hexadecimal
- IPv6 6to4
- IPv6 mapeada

El informe final debe incluir tambien los ultimos resultados de DNS, conexiones y vecinos/interfaz.

## Casos limite a contemplar

- octetos fuera de rango
- CIDR fuera de `0..32`
- mascara decimal invalida o no contigua
- puertos no numericos
- IP sin entrada en la tabla DNS
- interfaz o vecino inexistente en los ficheros de prueba

## Criterios de correccion

- funciones de conversion bien separadas
- operaciones bit a bit correctas
- menu robusto y repetible
- parseo correcto de tablas TSV
- informe claro y consistente