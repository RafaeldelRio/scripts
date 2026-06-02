# Ejercicio 1. Auditoria segura de altas de usuarios

## Objetivo

Construye un script interactivo en Bash que simule el alta de usuarios de un servicio interno a partir de un fichero CSV, sin tocar usuarios reales del sistema.

El script debe repasar los patrones avanzados vistos en el proyecto:

- menu persistente con `while` y `case`
- lectura de ficheros con `IFS`
- validacion exhaustiva de campos
- generacion de logins mediante manipulacion de cadenas
- lectura silenciosa con `read -s`
- hash de credenciales
- deteccion de permisos peligrosos
- logging con marca temporal
- rollback si una alta falla a mitad del proceso

## Datos de entrada

Usa como entrada un CSV con este formato:

```text
nombre;apellido1;apellido2;dni;nivel;clave
```

Reglas:

- `dni` debe cumplir `NNNNNNNNL`
- `nivel` solo puede ser `admin`, `soporte` o `alumno`
- `clave` debe tener al menos 8 caracteres, una mayuscula, una minuscula y un digito
- el login se genera como `inicial(nombre) + 3 letras de apellido1 + 3 letras de apellido2 + ultimos 3 digitos del DNI`, todo en minusculas
- si el login ya existe, hay que resolver la colision anadiendo un sufijo numerico

## Operaciones obligatorias

El script debe mostrar este menu:

1. Importar usuarios validos desde el CSV
2. Consultar un usuario importado por login
3. Detectar permisos peligrosos en el entorno simulado
4. Generar informe final y salir
5. Salir sin generar informe

## Restricciones

- No se puede usar `useradd`, `passwd` ni modificar `/etc`
- Todo debe ejecutarse en un directorio de trabajo local
- Si una alta falla tras crear parte de la estructura, el script debe deshacer lo creado para ese usuario
- Debe existir un fichero de log con fecha y hora
- Si no se pasa un token por opcion, el script debe pedirlo con `read -s` y usarlo para firmar el informe final

## Salidas esperadas

Al importar usuarios validos, el script debe crear un entorno simulado con:

- un directorio personal por login
- una carpeta `.ssh`
- un fichero con la credencial hasheada
- un registro tabulado de usuarios importados
- un fichero de rechazados con el motivo del error

El informe final debe incluir, como minimo:

- total de usuarios validos y rechazados
- reparto por nivel
- usuarios con carpeta `.ssh`
- ficheros o directorios inseguros detectados
- firma del informe

## Casos limite a contemplar

- CSV inexistente o vacio
- lineas incompletas
- DNIs incorrectos
- claves inseguras
- colisiones de login
- ejecucion del menu sin haber importado datos antes

## Criterios de correccion

- uso correcto de funciones pequenas y reutilizables
- validaciones claras y mensajes de error utiles
- uso seguro de rutas y comillas
- estructura modular del menu
- consistencia del log y del rollback