: <<"FIN"
tr es un comando de Unix/Linux que se utiliza para traducir o eliminar
caracteres de la entrada estándar y escribir el resultado en la salida
estándar.
FIN

echo "----- Traducir caracteres (sustituir) -----"
echo "hola" | tr 'a-z' 'A-Z'
echo
# Salida: HOLA

echo "----- Eliminar caracteres (opción -d) -----"
echo "HOLA" | tr 'A-Z' 'a-z'
echo
# Salida: hola

echo "hola123mundo" | tr -d '0-9'
echo
# Salida: holamundo

echo "hola mundo" | tr -d ' '
echo
# Salida: holamundo

echo "----- Comprimir caracteres repetidos (opción -s) -----"
echo "hoooola    mundo" | tr -s 'o'
echo
# Salida: hola    mundo

echo "hola    mundo" | tr -s ' '
echo
# Salida: hola mundo

echo "----- Complementar (opción -c) -----"
echo "hola123" | tr -cd '0-9'
echo
# Salida: 123 (elimina todo excepto números)


echo "----- Reemplazar caracteres -----"
lista="hola:mundo"
echo "$lista" | tr ":" "\n"
echo


echo "----- Eliminar todos los espacios -----"
echo "hola mundo" | tr -d ' '
echo
# Salida: holamundo

echo "----- Reemplazar espacios por guiones -----"
echo "hola mundo" | tr ' ' '-'
echo
# Salida: hola-mundo

echo "----- Eliminar saltos de línea -----" 
cat archivo.txt | tr -d '\n'
echo

echo "----- Convertir espacios múltiples en uno solo -----"
echo "hola    mundo" | tr -s ' '
echo
# Salida: hola mundo
FIN