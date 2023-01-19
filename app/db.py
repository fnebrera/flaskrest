"""
Módulo para la conexión a la base de datos
"""
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class BaseModelMixin:
    """
    Clase base para los diferentes modelos de datos de la aplicación
    """

    def save(self):
        """ Guarda el objeto en la base de datos """
        db.session.add(self)
        db.session.commit()

    def delete(self):
        """ Elimina el objeto de la base de datos """
        db.session.delete(self)
        db.session.commit()

    @classmethod
    def get_all(cls):
        """ Devuelve todos los objetos de la base de datos """
        return cls.query.all()

    @classmethod
    def get_by_id(cls, identificador):
        """ Devuelve un objeto de la base de datos por su id """
        return cls.query.get(identificador)

    @classmethod
    def simple_filter(cls, **kwargs):
        """ Devuelve todos los objetos de la base de datos que cumplan con los filtros """
        return cls.query.filter_by(**kwargs).all()
