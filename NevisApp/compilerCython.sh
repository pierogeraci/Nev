#Compilo www
clear
cd /nevis_app/nevis_app_1.7.0/src
#for file in *.py; do
#    mv "$file" "$(basename "$file" .py).pyx"
#done
python setup.py build_ext --inplace
find /nevis_app/nevis_app_1.7.0/src -name '*.so' -exec mv '{}' /nevis_app/nevis_app_1.7.0/www \;
find /nevis_app/nevis_app_1.7.0/src -name "*.c" -type f -delete
rm -rf ./build

#Compilo Moduli
cd /nevis_app/nevis_app_1.7.0/src/module
python setup.py build_ext --inplace
find /nevis_app/nevis_app_1.7.0/src/module -name '*.so' -exec mv '{}' /nevis_app/nevis_app_1.7.0/www/module \;
find /nevis_app/nevis_app_1.7.0/src/module -name "*.c" -type f -delete
rm -rf ./build
#rm -rf ./module
