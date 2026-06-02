# Ejercicio 3. Gestor de copias rotativas y auditoria de scripts

## Objetivo

Implementa un script en Bash que combine los patrones mas avanzados del bloque de administracion: configuracion oculta por proyecto, backups rotativos, restauracion, rollback, recursividad y auditoria de scripts con deteccion de posibles copias.

## Escenario

Cada proyecto tiene un fichero oculto `.repasoBackup.conf` con este formato:

```text
numeroCopias=2
contenidoCopia=documentos:codigo:README.md
```

El script debe trabajar sobre directorios locales y no sobre cuentas reales del sistema.

## Operaciones obligatorias

La sintaxis debe admitir una o varias de estas opciones:

- `-b` crear copias de todos los proyectos configurados
- `-r nombre_proyecto` restaurar la ultima copia del proyecto indicado
- `-a` auditar scripts de alumnos a partir de cabeceras obligatorias
- `-t` mostrar el arbol de copias existentes
- `-h` mostrar ayuda

## Parte de backup

Para cada proyecto valido el script debe:

- leer el fichero oculto de configuracion
- usar un valor por defecto si `numeroCopias` no existe o es invalido
- validar que los elementos de `contenidoCopia` existan dentro del proyecto
- crear una copia comprimida con fecha y hora
- hacer rollback si la compresion falla y no dejar archivos parciales
- mantener solo las `N` copias mas recientes

## Parte de restauracion

Al restaurar debe:

- localizar la copia mas reciente del proyecto
- extraerla a un directorio de restauracion local
- dejar trazabilidad en el log
- fallar con mensaje claro si no existen copias

## Parte de auditoria de scripts

Los scripts a auditar incluyen esta cabecera minima:

```text
#!/bin/bash
#Tema:7
#Ejercicio:3
#Autores:alumno1 alumno2
```

El script debe:

- recorrer recursivamente el arbol de entregas
- ignorar scripts sin cabeceras completas
- quedarse, para cada combinacion `autor|tema|ejercicio`, con el script mas reciente
- generar un informe resumen
- detectar posibles copias comparando el hash del contenido sin comentarios

## Restricciones

- uso obligatorio de funciones
- uso obligatorio de arrays asociativos en la deduplicacion
- debe existir un log con operaciones y errores
- el arbol de copias debe generarse mediante una funcion recursiva

## Criterios de correccion

- parseo correcto de la configuracion oculta
- rotacion correcta de copias
- rollback real al fallar un backup
- auditoria coherente y bien resumida
- recursion clara y sin depender del comando `tree`