"""
This file is the entrypoint for the application. It is used to create the
application instance and run it.
"""
import os

from app import create_app

"""
APP_SETTINGS_MODULE es una variable de entorno que indica el fichero de configuración
que se usará para inicializar la aplicación. Los diferentes ficheros de configuración
están en el directorio config. Por ejemplo, si se ejecuta la aplicación con
APP_SETTINGS_MODULE=config.default, se usará el fichero config/default.py
"""
settings_module = os.getenv('APP_SETTINGS_MODULE')
# Debug
print(f'INFO: Inicializando con APP_SETTINGS_MODULE: {settings_module}')
app = create_app(settings_module)