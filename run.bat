@ECHO OFF
REM Variables especificas de la aplicacion
@set FLASK_APP=entrypoint
@set FLASK_DEBUG=1
@set APP_SETTINGS_MODULE=config.default
REM Iniciar aplicacion flask
flask run --host 0.0.0.0 --port 5000
