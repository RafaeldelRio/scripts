#!/bin/bash

: << "FIN"
Diseñar un shell script para bash que ofrezca en la salida estándar el siguiente menú:
    1. Listar archivos.
    2. Ver directorio de trabajo.
    3. Crear directorio.
    4. Borrar directorio.
    5. Crear usuario.
    6. Borrar usuario.
    7. Salir.

Introducir opción: Si se solicita la opción:
    1. Se listan los archivos del directorio actual.
    2. Se muestra el nombre del directorio actual.
    3. Se solicita un nombre de directorio y se crea dentro del directorio 
        actual.
    4. Se solicita un nombre de directorio y se borra, suponiendo que está vacío
         y ubicado en el directorio actual.
    5. Se comprueba si el script lo está ejecutando el root, y si lo es, se 
        solicita un login de usuario y se añade al sistema, creando en ese 
        momento su directorio personal, que estará ubicado en /home y llevará 
        por nombre el del propio login de usuario. Si no se es root, se mostrará 
        una advertencia.
    6. Se comprueba si el script lo está ejecutando el root, y si lo es, se 
        solicita un login de usuario y se borra del sistema, eliminando también 
        su directorio personal. Si no se es root se mostrará una advertencia.
    7. Se finaliza la ejecución, mostrando el mensaje Fin de ejecución.

Si se introduce una opción no válida se indicará esta circunstancia en la 
salida estándar.

Tras ejecutar cualquiera de las opciones válidas, salvo en el caso de la 7, 
se imprimirá de nuevo el menú, en espera de recibir otra solicitud.

Diseñar el script empleando funciones shell para cada una de las opciones
1 a 6.
FIN

# Exit on error, treat unset variables as errors, and propagate pipe failures
set -euo pipefail

# ---------- Functions ----------
list_files() {
  echo "--- Lista de archivos en el directorio actual ---"
  ls -la
}

show_pwd() {
  echo "--- Directorio de trabajo actual ---"
  pwd
}

create_dir() {
  read -rp "Introduce el nombre del nuevo directorio: " dir_name
  if [[ -z "$dir_name" ]]; then
    echo "Nombre de directorio vacío. Operación cancelada."
    return
  fi
  if mkdir -p "${dir_name}"; then
    echo "Directorio '$dir_name' creado exitosamente."
  else
    echo "Error al crear el directorio '$dir_name'."
  fi
}

delete_dir() {
  read -rp "Introduce el nombre del directorio a borrar: " dir_name
  if [[ -z "$dir_name" ]]; then
    echo "Nombre de directorio vacío. Operación cancelada."
    return
  fi
  if [[ ! -d "$dir_name" ]]; then
    echo "El directorio '$dir_name' no existe."
    return
  fi
  if rmdir "${dir_name}" 2>/dev/null; then
    echo "Directorio '$dir_name' borrado exitosamente."
  else
    echo "No se pudo borrar '$dir_name'. Asegúrate de que esté vacío y sea un directorio en el directorio actual."
  fi
}

create_user() {
  if [[ $EUID -ne 0 ]]; then
    echo "Advertencia: Necesitas ser root para crear usuarios."
    return
  fi
  read -rp "Introduce el login del nuevo usuario: " login
  if [[ -z "$login" ]]; then
    echo "Login vacío. Operación cancelada."
    return
  fi
  if id "${login}" &>/dev/null; then
    echo "El usuario '$login' ya existe."
    return
  fi
  # Crear usuario sin contraseña y con home en /home
  if useradd -m -d "/home/${login}" "${login}"; then
    echo "Usuario '$login' creado exitosamente con directorio personal en /home/${login}."
  else
    echo "Error al crear el usuario '$login'."
  fi
}

delete_user() {
  if [[ $EUID -ne 0 ]]; then
    echo "Advertencia: Necesitas ser root para borrar usuarios."
    return
  fi
  read -rp "Introduce el login del usuario a borrar: " login
  if [[ -z "$login" ]]; then
    echo "Login vacío. Operación cancelada."
    return
  fi
  if ! id "${login}" &>/dev/null; then
    echo "El usuario '$login' no existe."
    return
  fi
  # Borrar usuario y su directorio home
  if userdel -r "${login}"; then
    echo "Usuario '$login' y su directorio personal borrados exitosamente."
  else
    echo "Error al borrar el usuario '$login'."
  fi
}

exit_script() {
  echo "Fin de ejecución."
  exit 0
}

# ---------- Menu ----------
while true; do
  cat <<'MENU'
=== Menú de opciones ===
1) Listar archivos.
2) Ver directorio de trabajo.
3) Crear directorio.
4) Borrar directorio.
5) Crear usuario.
6) Borrar usuario.
7) Salir.
MENU
  read -rp "Introduce opción: " opt
  case "$opt" in
    1) list_files ;;
    2) show_pwd ;;
    3) create_dir ;;
    4) delete_dir ;;
    5) create_user ;;
    6) delete_user ;;
    7) exit_script ;;
    *) echo "Opción no válida: $opt" ;;
  esac
  echo # línea en blanco para separar iteraciones
done