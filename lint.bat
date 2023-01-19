ECHO OFF
REM Ejecutar pylint sobre los fuentes del proyecto
REM Agregar --exit-zero para que no falle el build si pylint encuentra errores
echo Ejecutando pylint...
pylint --argument-naming-style=any --disable=no-member entrypoint app/