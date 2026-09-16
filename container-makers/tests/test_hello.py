def test_api_hello_retorna_hello_world(client):
    response = client.get("/api/hello")

    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}


def test_home_renderiza_hello_world(client):
    response = client.get("/")

    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Hello World" in response.text


def test_pagina_inexistente_renderiza_error_html(client):
    response = client.get("/nao-existe")

    assert response.status_code == 404
    assert "text/html" in response.headers["content-type"]


def test_api_inexistente_retorna_json(client):
    response = client.get("/api/nao-existe")

    assert response.status_code == 404
    assert response.json() == {"detail": "Not Found"}
