#!/bin/bash
cmd="tar"
arg1="./salida.tgz"
arg2="./cosas-interesantes"

# cvfz = Create Verbose File Gzip
$cmd czvf "$arg1" "$arg2"