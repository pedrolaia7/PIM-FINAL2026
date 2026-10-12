import base64
import binascii
import io

import numpy as np
from PIL import Image, UnidentifiedImageError

from .errors import FaceError


def decode_image(image_b64: str, max_bytes: int) -> Image.Image:
    """Decodifica base64 -> PIL RGB, validando tamanho e formato."""
    if "," in image_b64[:64]:  # tolera prefixo data:image/jpeg;base64,
        image_b64 = image_b64.split(",", 1)[1]
    try:
        raw = base64.b64decode(image_b64, validate=True)
    except (binascii.Error, ValueError):
        raise FaceError("invalid_image", "Imagem em base64 inválida", 400)
    if len(raw) > max_bytes:
        raise FaceError("image_too_large", "Imagem excede o tamanho máximo permitido", 413)
    try:
        img = Image.open(io.BytesIO(raw))
        img.load()
    except (UnidentifiedImageError, OSError):
        raise FaceError("invalid_image", "Arquivo não é uma imagem válida", 400)
    return img.convert("RGB")


def sharpness(img: Image.Image) -> float:
    """Variância do Laplaciano em escala de cinza: baixo = borrado."""
    gray = np.asarray(img.convert("L"), dtype=np.float32)
    if min(gray.shape) < 3:
        return 0.0
    lap = (
        -4 * gray[1:-1, 1:-1]
        + gray[:-2, 1:-1]
        + gray[2:, 1:-1]
        + gray[1:-1, :-2]
        + gray[1:-1, 2:]
    )
    return float(lap.var())
