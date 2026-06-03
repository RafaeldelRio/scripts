# Ejercicio de repaso: crear un script de auditoría.

Se pide desarrollar un script en Bash llamado sys_audit.sh que automatice ciertas tareas de auditoría y limpieza en un servidor Linux. 

Vamos a pedir una recopilación de distintos requisitos de los ejercicios que ya hemos visto a lo largo del curso.

- *Ejecución de root:* El script debe ejecutarse obligatoriamente con privilegios de administrador (root). Si lo ejecuta un usuario normal, debe mostrar un mensaje de error por la salida de error estándar (stderr) y salir con código de error 1.

- *Paso de Argumentos:* El script debe recibir parámetros, al menos la ruta de un directorio a auditar y opcionalmente un -u para activar la auditoría de usuarios.

Si no se pasan los argumentos correctamente o el directorio proporcionado no existe o no es un directorio válido, debe mostrar la sintaxis de uso (un echo "Uso: ./sys_audit.sh [-u] <directorio_logs>") y abortar la ejecución.

- *Limpieza y Compresión de Ficheros (Siempre se ejecuta):* Dentro del directorio proporcionado, el script debe buscar todos los ficheros que terminen en la extensión .log.

Si no encuentra ningún fichero .log, debe mostrar un mensaje informativo y continuar.

Si encuentra ficheros .log, debe crear un archivo comprimido llamado backup_logs_YYYYMMDD.tar.gz (donde YYYYMMDD es la fecha actual) en el directorio /tmp/.

Una vez comprimidos con éxito, los ficheros .log originales deben ser vaciados (su tamaño debe quedar a 0 bytes), pero no eliminados.

- *Auditoría de Usuarios (Solo si se pasa el flag -u):*

El script debe procesar el archivo /etc/passwd.

Debe buscar todos los usuarios del sistema que tengan un UID mayor o igual a 1000 y que tengan asignada una shell interactiva (por ejemplo, /bin/bash).

Para cada usuario encontrado que cumpla la condición, debe escribir en un fichero llamado informe_usuarios.txt (ubicado en el directorio actual) la siguiente línea:
[OK] - El usuario <nombre_usuario> tiene UID <uid> y su directorio personal es <home>



Además, y simulando las condiciones que os suelen poner en los exámenes de oposición vamos a evitar las salidas ruidosas (por ejemplo, los errores de permisos al usar find o tar no deben salir por pantalla), usar funciones (al menos dos funciones) y que el código sea robusto (usa el [[ ]] y el (( )) en los condicionales).