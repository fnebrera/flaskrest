# Ejemplo de proyecto python con Flask

Se trata de un servidor REST muy simple que accede a una base
de datos en Postgres con una tabla de peliculas y otra con los
actores que intervienen. Aún siendo un ejemplo muy sencillo,
incorpora varios módulos esternos tales como Flask, SqlAlchemy,
Marshmallow, pysycopg, etc. que nos ayudan a trabajar sobre
las caracteristicas CI/CD de nuestras librerias de DevOps.

Para ejecutar en cualquier ambiente, debemos previamente instalar python
en versión 3 o superior. Sobre ello prepararemos el entorno de ejecución
del siguiente modo:

    pip install virtualenv
    pip vevn env
    . env/bin/activate (Linux)
    env\Scripts\activate.bat (Windows)
    env/bin/activate (Linux)
    pip install -r requirements.txt

A continuacion, debemos editar el archivo _ctx_.py del directorio config
para adecuarlo a nuestra configuración de base de datos, donde _ctx_ es
el contexto de ejecucion, por ejemplo _dev_, _uat_ o _prod_.

Asimismo, debemos editar el archivo _run.sh_ o _run.bat_ para adecuarlo
a nuestra configuración.

Una vez instaladas las dependencias y preparada la configuración, podemos ejecutar el servidor con el
siguiente comando:

    ./run.sh (Linux)
    run.bat (Windows)


