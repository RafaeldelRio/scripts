# Ejercicio de repaso: "Herramienta Interactiva de Diagnóstico de Red (net_tool.sh)"

Vamos a cambiar ahora de ámbito con este ejercicio, mezclando para ello la parte de scripts y de redes. Además vamos a cambiar los argumentos de entrada por un menú.
Se requiere desarrollar un script en Bash llamado net_tool.sh diseñado para ayudar a los técnicos de soporte de Nivel 1. El script no recibirá argumentos al iniciarse, sino que se controlará enteramente a través de un menú interactivo.

1. Interfaz Principal (El Menú):

Al iniciar, el script debe mostrar un menú con las siguientes opciones:
1) Escaneo rápido de subred
2) Crear perfil seguro de equipo
3) Salir

El script debe quedarse en un bucle infinito mostrando el menú y ejecutando la opción elegida hasta que el usuario seleccione la opción 3. Si pulsa una tecla no válida, debe avisar y volver a mostrar el menú.

2. Opción 1: Escaneo rápido de subred:

El script pedirá al usuario que introduzca una dirección IPv4 por pantalla.

Validación: Debe comprobar que lo introducido tiene formato de IPv4 (cuatro bloques de números separados por puntos). Si no es válido, muestra un error y vuelve al menú principal.

Manipulación: Si es válida, el script debe "recortar" la IP para quedarse solo con la base de la red (los 3 primeros octetos). Por ejemplo, si el usuario introduce 192.168.100.45, el script debe extraer 192.168.100.

Acción: Utilizando un bucle, el script debe hacer un ping (de un solo paquete y con tiempo de espera de 1 segundo) a las 5 primeras direcciones de esa subred (es decir, desde la .1 hasta la .5).

Debe mostrar por pantalla un informe simple: 192.168.100.1 - ACTIVA o 192.168.100.2 - INACTIVA.

3. Opción 2: Crear perfil seguro de equipo:

Hostname: El script pedirá un nombre para el equipo. Este campo no puede estar vacío. El script debe insistir un máximo de 3 intentos. Si tras 3 intentos el usuario no escribe nada, mostrará un error y volverá al menú principal.

Contraseña: A continuación, pedirá una contraseña de administrador. Esta contraseña no debe verse en pantalla mientras se teclea. Además, debe pedirla una segunda vez para confirmar. Si no coinciden, muestra un error y vuelve al menú.

Manipulación y Salida: El script transformará el nombre del equipo introducido a MAYÚSCULAS. Finalmente, creará un archivo en el directorio actual llamado perfil_<HOSTNAME_EN_MAYUSCULAS>.conf que contenga una línea indicando el nombre del equipo y que el perfil se ha generado correctamente.