#!/bin/bash
echo "[Compiler] Python File Name: ";
read buildFileName
	
cython --embed -o $buildFileName.c $buildFileName.pyx && gcc -Os -I /usr/include/python2.7 -o $buildFileName $buildFileName.c -lpython2.7 -lpthread -lm -lutil -ldl

echo "Operazione avvenuta con successo"
