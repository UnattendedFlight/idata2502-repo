from app import app

def test_health_is_ok():
    response = app.test_client().get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"

def test_hello_greets_by_name():
    response = app.test_client().get("/hello/Ada")
    assert response.status_code == 200
    assert response.data == b"Hello, Ada!"

def test_reset_requires_api_key():
    response = app.test_client().post("/reset")
    assert response.status_code == 401

def test_metrics_exposed():
    client = app.test_client()
    client.get("/hello/Ada")
    response = client.get("/metrics")
    assert response.status_code == 200
    body = response.get_data(as_text=True)
    # labelled by route pattern, not by the raw URL
    assert 'http_requests_total{method="GET",path="/hello/<name>",service="app",status="200"}' in body
    assert "http_request_duration_seconds_bucket" in body
