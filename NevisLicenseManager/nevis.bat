echo off
cd bin 
echo ------CODIFICO IL SERIAL NUMBER %1 CON LA CHIAVE PUBBLICA DI SS -----
java it.softstrategy.nevis.Manager -encrypt %1 ..\license ..\chiavi\ss.public.key
REM echo ------DECODIFICO IL SERIAL NUMBER %1 CON LA CHIAVE PRIVATA DI SS-----
REM java it.softstrategy.nevis.Manager -decrypt ..\license ..\chiavi\ss.private.key
echo ------CODIFICO IL SERIAL NUMBER %1 CON LA CHIAVE PRIVATA DI SS -----
java it.softstrategy.nevis.Manager -encrypt %1 ..\nevis.lic ..\chiavi\ss.private.key
echo ------DECODIFICO IL SERIAL NUMBER %1 CON LA CHIAVE PUBBLICA DI SS -----
java it.softstrategy.nevis.Manager -decrypt ..\nevis.lic ..\chiavi\ss.public.key
REM echo ------FIRMO LA LICENZA -----
REM java it.softstrategy.nevis.SignFile -s ..\nevis.lic ..\nevis.sig ..\chiavi\nevis.private.key
REM echo ------VERIFICO LA LICENZA -----
REM java it.softstrategy.nevis.SignFile -v ..\nevis.lic ..\nevis.sig ..\chiavi\nevis.public.key

cd ..