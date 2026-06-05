Aprovisionamiento Masivo de Empleados (bulk_users.sh)

Has sido encargado de automatizar la creación de cuentas para las nuevas incorporaciones de la empresa. El departamento de RRHH te proporcionará un fichero de texto plano (separado por dos puntos :) con los datos de los nuevos empleados.

Debes crear un script llamado bulk_users.sh que cumpla estrictamente con lo siguiente:

1. Control de Ejecución y Argumentos:

El script debe ejecutarse obligatoriamente con privilegios de root. Si no, debe abortar con un error.

Debe recibir exactamente un argumento posicional: la ruta al fichero de texto de RRHH.

Si el número de argumentos no es 1, debe mostrar cómo se usa el script y salir.

Debe comprobar que el fichero pasado como argumento existe y tiene permisos de lectura (-r). Si no existe o no se puede leer, mostrará un error y saldrá.

2. Formato del Fichero de Entrada:

El fichero de RRHH tendrá el siguiente formato por línea: nombre_usuario:Nombre Completo:departamento

Ejemplo de una línea: jgarcia:Juan Garcia Lopez:contabilidad

3. Procesamiento y Creación de Usuarios:

El script debe leer el fichero línea a línea.

Por cada línea, debe comprobar primero si el usuario ya existe en el sistema.

Si ya existe: Ignora la creación y añade una línea al fichero errores.log diciendo: [ERROR] El usuario <nombre_usuario> ya existe en el sistema.

Si NO existe, debe crear el usuario con las siguientes condiciones:

Su directorio personal (home) debe ser creado en una ruta personalizada basada en su departamento: /home/<departamento>/<nombre_usuario> (ej: /home/contabilidad/jgarcia). Ojo: asume que la carpeta del departamento podría no existir previamente.

Su nombre completo (GECOS) debe ser el que viene en el fichero.

Su shell por defecto debe ser /bin/bash.

Su contraseña debe establecerse por defecto a la palabra Temporal123, la cual debe ser cifrada correctamente antes de asignarla a la cuenta.

4. Registro de Éxito:

Si el usuario se crea correctamente, debe añadir una línea al fichero creados.log con el formato: [OK] Usuario <nombre_usuario> creado en el departamento de <departamento>.