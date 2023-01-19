#!/bin/bash

# Variables especificas de la aplicacion
echo "Definiendo variables de entorno.."
export FLASK_APP="entrypoint"
export FLASK_DEBUG=0
export APP_SETTINGS_MODULE=config.uat
# Iniciar aplicacion flask
echo "Ejecutando la aplicacion.."
flask run --host 0.0.0.0 --port 5000
