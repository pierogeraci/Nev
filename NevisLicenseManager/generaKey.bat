echo off
mkdir chiavi
cd bin
REM echo ------CREO LE CHIAVI PER NEVIS-----
java it.softstrategy.nevis.Manager -genkey ..\chiavi\nevis.public.key ..\chiavi\nevis.private.key
REM echo ------CREO LE CHIAVI PER ss-----
java it.softstrategy.nevis.Manager -genkey ..\chiavi\ss.public.key ..\chiavi\ss.private.key
cd ..