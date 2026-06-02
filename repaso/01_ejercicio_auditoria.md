# Ejercicio especial. Auditoria segura de altas de usuarios

Construye un script interactivo en Bash que simule el alta de usuarios de un servicio interno a partir de un fichero CSV, sin tocar usuarios reales del sistema (esto lo hacemos para evitar desastres en vuestro PC, pero si queréis lo podéis hacer practicando en real, simplemente usando las funciones de useradd).

El CSV de entrada tiene el siguiente formato:

```text
nombre;apellido1;apellido2;dni;nivel;clave
```

Qué espero que tenga el csv
- `dni` debe cumplir `NNNNNNNNL`
- `nivel` solo puede ser `admin`, `soporte` o `alumno`
- `clave` debe tener al menos 8 caracteres, una mayuscula, una minuscula y un digito
- el login se genera como `inicial(nombre) + 3 letras de apellido1 + 3 letras de apellido2 + ultimos 3 digitos del DNI`, todo en minusculas
- si el login ya existe, hay que resolver la colision anadiendo un sufijo numerico

Esto debería validarse de alguna manera a lo largo del script.

El script debe mostrar este menu:

1. Importar usuarios validos desde el CSV
2. Consultar un usuario importado por login
3. Detectar permisos peligrosos en el entorno simulado
4. Generar informe final y salir
5. Salir sin generar informe



Para evitar destrozos, vamos a hacer uo de las siguientes restricciones:

- No se puede usar `useradd`, `passwd` ni modificar `/etc`
- Todo debe ejecutarse en un directorio de trabajo local
- Si una alta falla tras crear parte de la estructura, el script debe deshacer lo creado para ese usuario
- Debe existir un fichero de log con fecha y hora
- Si no se pasa un token por opcion, el script debe pedirlo con `read -s` y usarlo para firmar el informe final

Qué esperamos que pase al importar los usuarios:
- Crear un directorio personal por login
- Crear una carpeta `.ssh`
- Crear un fichero con la credencial hasheada
- Crear un registro tabulado de usuarios importados
- Crear un fichero de rechazados con el motivo del error

Tras efectuarse todo el proceso se debe generar un informe final con la siguiente información:

- total de usuarios validos y rechazados
- reparto por nivel
- usuarios con carpeta `.ssh`
- ficheros o directorios inseguros detectados
- firma del informe

Se pueden dar posibles errores, que en ese caso debemos salirnos del script con un `exit` adecuado:
- CSV inexistente o vacio
- lineas incompletas
- DNIs incorrectos
- claves inseguras
- colisiones de login
- ejecucion del menu sin haber importado datos antes


Como sé que es un ejercicio un poco largo, os pongo algunas pistas por aquí:
- menu persistente con `while` y `case`
- lectura de ficheros con `IFS`
- validacion exhaustiva de campos
- generacion de logins mediante manipulacion de cadenas
- lectura silenciosa con `read -s`
- hash de credenciales
- deteccion de permisos peligrosos
- logging con marca temporal
- rollback si una alta falla a mitad del proceso


Un ejemplo de CSV es el siguiente. La pongo en código para que sea fácilmente copiable:
```
nombre;apellido1;apellido2;dni;nivel;clave
Lucia;Martinez;Ortega;12345678Z;admin;ClaveSegura1
Pablo;Navarro;Sanz;87654321X;soporte;S0porteSeguro
Ines;Delgado;Ruiz;11223344A;alumno;Alumno2025
Laura;Martinez;Ortega;99345678C;admin;ClaveSegura9
Ana;Li;Xu;22334455B;alumno;corta
Rosa;Serrano;Lopez;ABC;admin;BuenaClave7
Mario;Vega;;44556677D;soporte;OtraClave8
```