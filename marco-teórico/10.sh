#!/bin/bash

echo "¿Qué quieres que te diga? (hola, adios, linux...)"
read accion

case $accion in
    "hola")
        echo "es hola"
        ;;

    "adios")
        echo "es adios"
        ;;

    "linux")
        echo "es linux"
        ;;

    *)
        echo "es otra cosa"
esac