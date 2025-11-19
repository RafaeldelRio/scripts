# 1. Fundamentos: ¿Qué es la Shell y qué es Bash?

Antes de escribir el primer script, es crucial entender.
- **La Shell**: programa que actúa como intermediario entre el usuario y el sistema operativo. Permite interactuar con el sistema a través de comandos.
- **Bash**: existen diferentes tipos de shells y que Bash (Bourne-Again Shell) es una de las más comunes y potentes en sistemas Linux y macOS.
- **¿Qué es un script de Bash?**: archivo de texto plano que contiene una secuencia de comandos que la shell ejecuta de forma ordenada. Su principal ventaja es la automatización de tareas repetitivas.

## Creando el primer script
1. Elegir un editor de texto: minimalistas como nano o con más funciones como vscode.
2. Escribir el script:
   1. la primera línea de todo script de Bash debe ser #!/bin/bash. Esta línea, conocida como "shebang", le indica al sistema operativo qué intérprete debe usar para ejecutar el archivo.
   2. El comando echo para mostrar texto en la terminal.
   3. Para ejecutar:
      1. Usar el comando
         1. `bash ./ejemplo.sh`
      2. Guardar el archivo y dar permisos de ejecución.
         1. `chmod +x "./ejemplo.sh"`
         2. `./ejemplo.sh`



# 2. Problema con = y == 
- Para comparar textos
  - Dentro de un "if [ ]" se usa =
  - Dentro de un "if [[ ]]" se usa == para poder usar patrones, como A*
- Para comparar números
  - Se debe usar -eq, -lt o -gt
  - Dentro de un "if (( ))" se puede usar ==

# 3. Diferencia entre [ ] y [[ ]]
- [ ] es la forma antigua. 
  - Da más problemas. 
  - Hay que tener cuidado con poner las variables "$VAR"
  - Ojo con las && y ||. Se usa -a y -o en su lugar.
  - Usar =, no ==
- [[ ]] es la forma moderna que usa bash y zsh 
  - Aquí se pueden usar comparaciones modernas
  - Se puede usar ==
  - Se puede usar && y ||
  - Se comporta como esperas de los lenguajes de programación modernos