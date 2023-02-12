"""
Definición de los recursor RESTful de la API
"""
from flask import request, Blueprint
from flask_restful import Api, Resource

from .schemas import FilmSchema
from ..models import Film, Actor

"""
Creamos un blueprint de Flask para agrupar los recursos de la API
"""
films_v1_0_bp = Blueprint('films_v1_0_bp', __name__)

"""
Creamos una instancia del esquema FilmSchema para poder usarlo en la
definicion de los recursos
"""
film_schema = FilmSchema()

"""
Creamos la api de Flask-RESTful sobre el blueprint films_v1_0_bp
"""
api = Api(films_v1_0_bp)

"""
Constantes
"""
NOT_FOUND = 'La película no existe'

"""
Definición del recurso FilmListResource.
Este recurso implementa los métodos GET y POST para la lista de películas:
GET devuelve la lista de películas.
POST crea una nueva película.
"""
class FilmListResource(Resource):
    def get(self):
        films = Film.get_all()
        result = film_schema.dump(films, many=True)
        return result
    def post(self):
        data = request.get_json()
        film_dict = film_schema.load(data)
        film = Film(title=film_dict['title'],
                length=film_dict['length'],
                year=film_dict['year'],
                director=film_dict['director']
        )
        for actor in film_dict['actors']:
            film.actors.append(Actor(actor['name']))
        film.save()
        resp = film_schema.dump(film)
        return resp, 201

"""
Definición del recurso FilmResource.
Este recurso implementa los métodos GET, PUT y DELETE para una película concreta.
GET devuelve la película con el id pasado como parámetro.
PUT actualiza la película con el id pasado como parámetro.
DELETE elimina la película con el id pasado como parámetro.
"""
class FilmResource(Resource):
    def get(self, film_id):
        film = Film.get_by_id(film_id)
        if film is None:
            raise ObjectNotFound(NOT_FOUND)
        resp = film_schema.dump(film)
        return resp
    def put(self, film_id):
        film = Film.get_by_id(film_id)
        if film is None:
            raise ObjectNotFound(NOT_FOUND)
        data = request.get_json()
        film_dict = film_schema.load(data)
        film.title = film_dict['title']
        film.length = film_dict['length']
        film.year = film_dict['year']
        film.director = film_dict['director']
        film.actors = []
        for actor in film_dict['actors']:
            film.actors.append(Actor(actor['name']))
        film.save()
        resp = film_schema.dump(film)
        return resp
    def delete(self, film_id):
        film = Film.get_by_id(film_id)
        if film is None:
            raise ObjectNotFound(NOT_FOUND)
        film.delete()
        return '', 204

"""
Añadimos los recursos a la api de Flask-RESTful
"""
api.add_resource(FilmListResource, '/api/v1/films/', endpoint='film_list_resource')
api.add_resource(FilmResource, '/api/v1/films/<int:film_id>', endpoint='film_resource')
