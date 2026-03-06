#!/bin/bash

: << "FIN"
EJERCICIO 6.
Tomando toda la casuística del supuesto anterior, use el fichero “claves” del siguiente modo:
La contraseña siempre se almacenará cifrada (con lo que puede prescindir del análisis del parámetro c).
Si el fichero ya existe, se pide el usuario mostrando el que había almacenado y, si el
usuario lo deja en blanco, se conserva el usuario antiguo.
Si la contraseña se deja en blanco y el usuario no cambió, la contraseña tampoco varía.
Si el usuario cambió, entonces no se conserva la contraseña, aunque se deje en blanco.
Se actualiza el fichero para que almacene exclusivamente el nuevo usuario y contraseña.
FIN


FICHERO="$HOME/proyecto/scripts/b3/claves"

verificar_existencia_archivo() {
    # Si existe y su contenido no está vacío, se lee el usuario y hash almacenados.
    if [[ -f "$FICHERO" ]] && [[ -s "$FICHERO" ]]; then
        # Leo la primera línea del fichero, asumiendo formato usuario:hash.
        IFS=':' read -r usuario_anterior hash_anterior < "$FICHERO"
    else
        usuario_anterior=""
        hash_anterior=""
    fi
}

actualizacion_usuario() {
    # Se pide el nuevo usuario, mostrando el anterior entre corchetes.
    read -r -p "Nombre de usuario [${usuario_anterior}]: " usuario
    # Si el usuario se deja en blanco, se conserva el anterior.
    if [[ -z "$usuario" ]]; then
        usuario="$usuario_anterior"
    fi
}   


actualizacion_password() {
    # Si el usuario no cambió y hay un hash anterior, se ofrece conservar la contraseña.
    if [[ "$usuario" == "$usuario_anterior" ]] && [[ -n "$hash_anterior" ]]; then
        read -r -p "Cambiar contraseña s/N: " cambio
        if [[ "$cambio" == "s" || "$cambio" == "S" ]]; then
            solicitud_password
        fi

        # Se conserva el hash anterior.
        password_stored="$hash_anterior"
    else
        # Si el usuario cambió o no hay hash anterior, se solicita una nueva contraseña.
        solicitud_password
    fi
}

# Función para cifrar la contraseña.
cifrar() {
    openssl passwd -1 -salt a "$1"
}

solicitud_password() {
    # Si no se conserva la contraseña, se pide una nueva (confirmada) y se cifra.
    while true; do
        read -r -s -p "Nueva contraseña: " password
        echo
        read -r -s -p "Repita la nueva contraseña: " password2
        echo

        if [[ -z "$password" || -z "$password2" ]]; then
            echo "La contraseña no puede estar vacía. Inténtelo de nuevo."
        elif [[ "$password" != "$password2" ]]; then
            echo "Las contraseñas no coinciden. Inténtelo de nuevo."
        else
            password_stored=$(cifrar "$password")
            break
        fi
    done
}


almacenar_datos() {
    printf '%s:%s\n' "$usuario" "$password_stored" > "$FICHERO"
    echo "Usuario guardado en $FICHERO"
}


verificar_existencia_archivo
actualizacion_usuario
actualizacion_password
almacenar_datos



