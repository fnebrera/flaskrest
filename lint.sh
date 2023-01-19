#!/bin/bash
# Ejecutar pylint sobre los fuentes del proyecto
# Agregar --exit-zero para que no falle el build si pylint encuentra errores
echo "Ejecutando pylint..."
pylint --argument-naming-style=any --disable=no-member entrypoint app/