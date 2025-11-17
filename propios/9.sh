#!/bin/bash
echo "Introduce el nombre de un archivo o directorio:"
read nombre

if [ -e "$nombre" ]; then
  echo "El archivo o directorio '$nombre' existe."
else
  echo "El archivo o directorio '$nombre' no existe."
fi```
* **Nota:** `[ -e "$nombre" ]` comprueba si la ruta `$nombre` existe.

**3. Contador de Números**
Pide al usuario un número y utiliza un bucle `for` para contar desde 1 hasta ese número.

```bash
#!/bin/bash
echo "Introduce un número:"
read limite

echo "Contando hasta $limite:"
for i in $(seq 1 $limite); do
  echo $i
done