from dataclasses import dataclass
from typing import Protocol

import numpy as np
from PIL import Image

from .errors import FaceError


@dataclass
class FaceResult:
    embedding: np.ndarray
    face_size_px: int


class Embedder(Protocol):
    model_version: str

    def embed(self, img: Image.Image) -> FaceResult:
        """Retorna o embedding do ÚNICO rosto da imagem. Lança FaceError se não houver 1 rosto."""
        ...


class InsightFaceEmbedder:
    """ArcFace (buffalo_l) via InsightFace. Embedding de 512 dimensões."""

    model_version = "insightface-buffalo_l"

    def __init__(self) -> None:
        from insightface.app import FaceAnalysis  # import tardio: pesado

        self._app = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
        self._app.prepare(ctx_id=-1, det_size=(640, 640))

    def embed(self, img: Image.Image) -> FaceResult:
        bgr = np.asarray(img)[:, :, ::-1]  # RGB -> BGR (OpenCV)
        faces = self._app.get(bgr)
        if len(faces) == 0:
            raise FaceError("no_face", "Nenhum rosto detectado na imagem")
        if len(faces) > 1:
            raise FaceError("multiple_faces", "Mais de um rosto detectado. Envie uma selfie só sua")
        f = faces[0]
        x1, y1, x2, y2 = f.bbox
        return FaceResult(np.asarray(f.normed_embedding, dtype=np.float32), int(min(x2 - x1, y2 - y1)))


class MockEmbedder:
    """SOMENTE dev/testes. Vetor a partir de uma miniatura 8x8 em cinza. Não reconhece rostos."""

    model_version = "mock-8x8"

    def embed(self, img: Image.Image) -> FaceResult:
        small = np.asarray(img.convert("L").resize((8, 8)), dtype=np.float32).flatten()
        small = small - small.mean()
        if np.linalg.norm(small) == 0:
            raise FaceError("no_face", "Nenhum rosto detectado na imagem")
        return FaceResult(small / np.linalg.norm(small), min(img.size))


def build_embedder(kind: str, is_production: bool) -> Embedder:
    if kind == "mock":
        if is_production:
            raise RuntimeError("EMBEDDER=mock é proibido em produção")
        return MockEmbedder()
    if kind == "insightface":
        return InsightFaceEmbedder()
    raise ValueError(f"EMBEDDER desconhecido: {kind}")
