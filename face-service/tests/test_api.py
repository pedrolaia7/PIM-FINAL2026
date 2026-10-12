import base64
import io

import numpy as np
import pytest
from fastapi.testclient import TestClient
from PIL import Image

import app.config as cfg


@pytest.fixture()
def client(monkeypatch):
    monkeypatch.setenv("EMBEDDER", "mock")
    monkeypatch.setenv("API_KEY", "k")
    monkeypatch.setenv("MIN_SHARPNESS", "1")
    cfg.get_settings.cache_clear()
    from app.main import app

    with TestClient(app) as c:
        yield c
    cfg.get_settings.cache_clear()


H = {"X-API-Key": "k"}


def make_img(seed: int, size=160) -> str:
    rng = np.random.default_rng(seed)
    arr = (rng.random((size, size, 3)) * 255).astype("uint8")
    buf = io.BytesIO()
    Image.fromarray(arr).save(buf, format="JPEG", quality=95)
    return base64.b64encode(buf.getvalue()).decode()


def test_requires_api_key(client):
    r = client.post("/v1/faces/enroll", json={"image_b64": make_img(1)})
    assert r.status_code == 401


def test_enroll_then_verify_same_image_matches(client):
    img = make_img(1)
    e = client.post("/v1/faces/enroll", json={"image_b64": img}, headers=H)
    assert e.status_code == 200
    emb = e.json()["embedding"]
    v = client.post("/v1/faces/verify", json={"image_b64": img, "embedding": emb, "purpose": "payment"}, headers=H)
    assert v.status_code == 200
    body = v.json()
    assert body["is_match"] is True
    assert body["similarity"] > 0.99
    assert body["liveness"]["checked"] is False


def test_verify_different_image_does_not_match(client):
    emb = client.post("/v1/faces/enroll", json={"image_b64": make_img(1)}, headers=H).json()["embedding"]
    v = client.post("/v1/faces/verify", json={"image_b64": make_img(2), "embedding": emb}, headers=H).json()
    assert v["is_match"] is False


def test_invalid_base64(client):
    r = client.post("/v1/faces/enroll", json={"image_b64": "@@@"}, headers=H)
    assert r.status_code == 400
    assert r.json()["code"] == "invalid_image"


def test_blurry_image_rejected(client, monkeypatch):
    monkeypatch.setenv("MIN_SHARPNESS", "100000")
    cfg.get_settings.cache_clear()
    flat = Image.new("RGB", (160, 160), (120, 120, 120))
    buf = io.BytesIO()
    flat.save(buf, format="JPEG")
    r = client.post("/v1/faces/enroll", json={"image_b64": base64.b64encode(buf.getvalue()).decode()}, headers=H)
    assert r.status_code == 422
    assert r.json()["code"] == "blurry"


def test_embedding_dimension_mismatch(client):
    r = client.post("/v1/faces/verify", json={"image_b64": make_img(1), "embedding": [0.1, 0.2]}, headers=H)
    assert r.status_code == 400
    assert r.json()["code"] == "invalid_embedding"
