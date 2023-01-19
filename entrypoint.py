"""
Punto de entrada de la aplicación.
Se emplea para crear el objeto app e inicializarlo
con la configuración adecuada para el contexto de ejecución.
APP_SETTINGS_MODULE es una variable de entorno que indica el fichero de configuración
que se usará para inicializar la aplicación. Los diferentes ficheros de configuración
están en el directorio config. Por ejemplo, si se ejecuta la aplicación con
APP_SETTINGS_MODULE=config.default, se usará el fichero config/default.py
"""
import os

from app import create_app

settings_module = os.getenv('APP_SETTINGS_MODULE')
# Debug
print(f'INFO: Inicializando con APP_SETTINGS_MODULE: {settings_module}')
app = create_app(settings_module)
