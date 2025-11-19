# Enunciados de Tareas - Scripts de Bash

Este documento contiene los enunciados de las tareas de programación en Bash que se encuentran en la carpeta `propios`.

---

## Tarea 1: Números Pares (`1.sh`)

Crea una función que reciba un número y muestre todos los números pares desde el 1 hasta ese número.

**Conceptos a practicar:**
- Funciones en Bash
- Bucles `for` con sintaxis aritmética
- Condicionales con doble paréntesis `(( ))`
- Uso de `printf` para salida formateada

---

## Tarea 2: Saludo con Fecha (`2.sh`)

Crea un script que salude al usuario y le muestre la fecha y hora actual. El script debe mostrar la fecha y hora en el formato `dd/mm/yyyy hh:mm:ss`.

**Conceptos a practicar:**
- Lectura de entrada del usuario con `read -p`
- Formateo de fechas con el comando `date`
- Variables y sustitución de comandos

---

## Tarea 3: Organizador de Archivos (`3.sh`)

Crea un script que organice automáticamente los archivos de una extensión específica (por ejemplo, `.jpg`) moviéndolos a una carpeta dedicada (por ejemplo, `Imagenes`). El script debe crear la carpeta si no existe e informar al usuario de las acciones realizadas.

**Conceptos a practicar:**
- Creación de directorios con `mkdir -p`
- Bucles `for` para iterar sobre archivos
- Condicionales con dobles corchetes `[[ ]]`
- Movimiento de archivos con `mv`
- Patrones glob para buscar archivos por extensión

---

## Tarea 4: Juego de Adivinar el Número (`4.sh`)

Crea un juego interactivo de "Adivina el Número" donde el script genere un número aleatorio entre 1 y 10, y el usuario deba adivinarlo recibiendo pistas (mayor/menor) y contando los intentos.

**Conceptos a practicar:**
- Generación de números aleatorios con `$RANDOM`
- Bucles `while` con condiciones aritméticas
- Validación de entrada con expresiones regulares
- Comparaciones numéricas
- Control de flujo con `continue`

---

## Tarea 5: Copia de Seguridad de Archivos (`5.sh`)

Crea un script que solicite al usuario la ruta de un archivo y genere automáticamente una copia de seguridad del mismo añadiendo la extensión `.bak` al nombre original.

**Conceptos a practicar:**
- Verificación de existencia de archivos con `[[ -f ]]`
- Manipulación de rutas y nombres de archivos
- Copia de archivos con `cp`
- Manejo de errores con `exit`
- Condicionales para verificar éxito de comandos

---

## Tarea 6: Contador de Archivos (`6.sh`)

Crea un script que cuente y muestre el número total de archivos regulares (no directorios) que existen en el directorio actual.

**Conceptos a practicar:**
- Iteración sobre elementos del directorio con `*`
- Verificación de tipo de archivo con `[[ -f ]]`
- Contadores y operaciones aritméticas
- Bucles `for`

---

## Tarea 7: Menú Interactivo de Utilidades (`7.sh`)

Crea un menú interactivo que permita al usuario elegir entre listar el contenido del directorio actual, mostrar la fecha y hora, o salir del programa.

**Conceptos a practicar:**
- Funciones en Bash
- Bucles `while` con condiciones aritméticas
- Estructura `case` para menús
- Comandos del sistema (`ls`, `date`)
- Pausas interactivas con `read`

---

## Tarea 8: Generador de Archivos Secuenciales (`8.sh`)

Crea un script que genere automáticamente 10 archivos vacíos con nombres secuenciales (`archivo1.txt`, `archivo2.txt`, ..., `archivo10.txt`) utilizando un bucle.

**Conceptos a practicar:**
- Bucles `for` con sintaxis estilo C
- Creación de archivos con `touch`
- Concatenación de cadenas para nombres de archivos
- Operaciones aritméticas en Bash

---

## Notas para el Alumnado

Todos estos scripts están diseñados para practicar conceptos fundamentales de programación en Bash. Se recomienda:

1. **Leer el código cuidadosamente** antes de ejecutarlo
2. **Experimentar** modificando valores y parámetros
3. **Probar casos límite** para entender el comportamiento
4. **Aplicar buenas prácticas** como:
   - Usar `[[ ]]` en lugar de `[ ]` para condiciones
   - Usar `(( ))` para operaciones aritméticas
   - Entrecomillar variables: `"$variable"`
   - Usar `read -p` para prompts interactivos
   - Usar `printf` en lugar de `echo` cuando sea posible

---