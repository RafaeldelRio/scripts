# Enunciados de Tareas - Scripts de Bash (B1)

Este documento contiene los enunciados de las tareas de programación en Bash que se encuentran en la carpeta `b1`.

---

## Tarea 1: Consulta de Procesos de Usuario (`1.sh`)

Crea un script que pregunte por un nombre de usuario y a continuación muestre sus procesos en curso.

**Conceptos a practicar:**
- Lectura de entrada con `read -p`
- Validación de entrada vacía con `[[ -z ]]`
- Uso del comando `ps` para listar procesos
- Manejo de errores con `exit`

---

## Tarea 2: Listar Directorio Home de Usuario (`2.sh`)

Crea un script que solicite el nombre de un usuario y muestre el contenido de su directorio home (`/home/usuario`).

**Conceptos a practicar:**
- Construcción de rutas dinámicas
- Verificación de existencia de directorios con `[[ -d ]]`
- Validación de entrada vacía
- Uso del comando `ls -l`
- Manejo de múltiples condiciones de error

---

## Tarea 3: Clasificador de Edad (`3.sh`)

Crea un script que pregunte la edad del usuario y responda según el rango:
- Si es menor que 10: "eres muy joven"
- Entre 10 y 30: "que mala edad tienes"
- Mayor de 30: "que bien te veo"

**Conceptos a practicar:**
- Validación de entrada numérica con expresiones regulares
- Condicionales con dobles paréntesis `(( ))`
- Estructura `if-elif-else`
- Comparaciones numéricas

---

## Tarea 4: Meses por Letra Inicial (`4.sh`)

Crea un script que solicite una letra por teclado y liste todos los meses que empiezan por esa letra. Si no coincide con ningún mes, debe mostrar un mensaje de error.

**Conceptos a practicar:**
- Extracción de subcadenas con `${variable:posicion:longitud}`
- Estructura `case` con patrones
- Patrones que aceptan mayúsculas y minúsculas `[Aa]`
- Manejo de múltiples coincidencias
- Caso por defecto con `*`

---

## Tarea 5: Calculadora Básica (`5.sh`)

Crea un script que solicite dos números por teclado y realice las siguientes operaciones: suma, resta, multiplicación, división y módulo (resto). Después debe mostrar el resultado de cada operación.

**Conceptos a practicar:**
- Lectura de múltiples valores en una sola línea
- Validación de que ambos parámetros existan con `[[ -n ]]`
- Operaciones aritméticas con `$(( ))`
- Operadores: `+`, `-`, `*`, `/`, `%`

---

## Tarea 6: Pregunta de Cultura General (`6.sh`)

Crea un script que pregunte "¿Quién descubrió América?" y compruebe si la respuesta es correcta o falsa.

**Conceptos a practicar:**
- Conversión de texto a minúsculas con `${variable,,}`
- Estructura `case` para validación de respuestas
- Patrones con caracteres especiales (ó, o)
- Manejo de respuestas con variaciones ortográficas

---

## Tarea 7: Clasificador de Carnets de Conducir (`7.sh`)

Crea un script que reciba como parámetro un tipo de carnet de conducir y muestre a qué categoría corresponde:
- E: remolques
- D: autobuses
- C1-C5: camiones
- B1-B2: automóviles
- A: motocicletas
- Cualquier otro: "Categoría no contemplada"

**Conceptos a practicar:**
- Validación del número de parámetros con `$#`
- Conversión a mayúsculas con `${variable^^}`
- Estructura `case` con rangos `[1-5]`
- Uso de parámetros posicionales `$1`

---

## Tarea 8: Comparador de Tres Palabras (`8.sh`)

Crea un script que admita tres palabras como entrada y muestre un mensaje informando de las relaciones de igualdad y desigualdad entre esas palabras (cuáles son iguales entre sí).

**Conceptos a practicar:**
- Bucle infinito con `while true`
- Lectura de múltiples valores
- Comparación de cadenas con `==`
- Condicionales anidados
- Lógica de comparación múltiple

---

## Tarea 9: Invertir Palabra (`9.sh`)

Crea un script que solicite una palabra y la escriba al revés.

**Conceptos a practicar:**
- Obtención de longitud de cadena con `${#variable}`
- Bucles `for` con decremento `i--`
- Extracción de caracteres individuales con `${variable:i:1}`
- Concatenación de cadenas
- Bucles inversos

---

## Tarea 10: Calculadora con Menú y Funciones (`10.sh`)

Crea una calculadora interactiva con un menú que ofrezca las siguientes opciones:
1. SUMA
2. RESTA
3. DIVISIÓN
4. MULTIPLICACIÓN
5. SALIR

**Conceptos a practicar:**
- Definición y uso de funciones
- Paso de argumentos a funciones con `$1`, `$2`
- Bucle infinito con `while true`
- Estructura `case` para menús
- Validación de división por cero
- Uso de `break` para salir de bucles
- Reutilización de código con funciones

---

## Tarea 11: Agenda Electrónica (`11.sh`)

Crea un script que implemente una agenda electrónica con las siguientes opciones:
1. Añadir contacto
2. Listar contactos
3. Borrar toda la agenda
4. Eliminar un registro específico
5. Salir

**Conceptos a practicar:**
- Escritura en archivos con `>>` (append)
- Lectura de archivos
- Formateo de texto con `column`
- Verificación de archivo con contenido `[[ -s ]]`
- Búsqueda en archivos con `grep`
- Eliminación de líneas con `grep -v`
- Uso de archivos temporales con `mktemp`
- Confirmación de acciones destructivas
- Operador lógico `&&` en condicionales
- Here documents con `cat << EOF`

---

## Tarea 12: Gestor de Directorios (`12.sh`)

Crea un script con un menú que permita realizar las siguientes operaciones:
1. Crear directorio
2. Borrar directorio
3. Copiar archivo a directorio
4. Salir

**Conceptos a practicar:**
- Creación de directorios con `mkdir -p`
- Verificación de existencia de directorios con `[ -d ]`
- Eliminación recursiva con `rm -R`
- Copia de archivos con `cp`
- Validación de existencia de archivos con `[[ -f ]]`
- Confirmaciones de seguridad para operaciones destructivas
- Manejo de errores en operaciones de archivos
- Control de flujo del éxito de comandos

---

## Notas

Estos scripts representan un nivel intermedio de programación en Bash. Se recomienda:

1. **Practicar la validación de entrada**: Siempre verificar que los datos introducidos sean válidos antes de procesarlos
2. **Usar funciones**: Ayudan a organizar el código y evitar repetición
3. **Implementar confirmaciones**: Para operaciones destructivas (borrar, sobrescribir)
4. **Manejar errores**: Anticipar qué puede salir mal y mostrar mensajes útiles
5. **Aplicar buenas prácticas**:
   - Usar `[[ ]]` en lugar de `[ ]` para condiciones
   - Entrecomillar variables: `"$variable"`
   - Usar nombres descriptivos para variables
   - Comentar el código para explicar la lógica
   - Validar parámetros y entradas del usuario

---
