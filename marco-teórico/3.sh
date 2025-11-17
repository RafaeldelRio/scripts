#!/bin/bash

# ----------------------- Ejemplo sencillo ----------------------- 
# Cojo texto y lo pinto
str="hola qué tal yo me llamo Pedro"
echo $str


# ----------------------- Ejemplo concatenando ----------------------- 
# Para imprimir
nombre="Juan"
echo "Hola, $nombre. Bienvenido."


# ----------------------- Ejemplo para guardar en variable ----------------------- 
ruta="/var/log"
archivo="syslog"

# Simplemente las pegas
completo="$ruta/$archivo"



# ----------------------- Ejemplo unir de forma segura ----------------------- 
# Para usar las cadenas de forma segura
backup="archivo"

# MAL: Bash busca una variable llamada $backup_old (que no existe)
comando="$backup" "$backup_old"  

# BIEN: Delimitas la variable
comando="$backup" "${backup}_old"



# ----------------------- La forma sumando ----------------------- 
mensaje="Error detectado:"
mensaje+=" Falta memoria."
mensaje+=" Reiniciando..."

echo "$mensaje"
# Salida: Error detectado: Falta memoria. Reiniciando...



# ----------------------- La forma PRO (que no la voy a enseñar) ----------------------- 
user="Ana"
id=501
# %s = string, %d = número (formatea automáticamente)
printf "Usuario: %s | ID: %04d\n" "$user" "$id"
# Salida: Usuario: Ana | ID: 0501

# ----------------------- Otro ejemplo PRO (que no la voy a enseñar) ----------------------- 
printf -v log_final "[%s] %s" "$(date)" "Todo OK"
echo "$log_final"