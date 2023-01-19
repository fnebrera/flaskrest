"""
Tests funcionales de la aplicación
"""
from app import create_app

def test_list_films():
    """
    Test de listado de películas
    """
    test_app = create_app('config.default')
    test_app.testing = True
    with test_app.test_client() as client:
        response = client.get('/api/v1/films')
        assert response.status_code == 200
        assert response.content_type == 'application/json'
