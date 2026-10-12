import numpy as np
from fastapi import APIRouter, Depends, Request

from ...config import Settings, get_settings
from ...schemas import (EnrollRequest, EnrollResponse, QualityInfo,
                        VerifyRequest, VerifyResponse)
from ...security import require_api_key
from ...services.errors import FaceError
from ...services.image_utils import decode_image, sharpness
from ...services.matcher import cosine_similarity

router = APIRouter(prefix="/v1/faces", dependencies=[Depends(require_api_key)])


def _analyze(request: Request, image_b64: str, settings: Settings):
    img = decode_image(image_b64, settings.max_image_bytes)
    sharp = sharpness(img)
    if sharp < settings.min_sharpness:
        raise FaceError("blurry", "Imagem muito borrada. Tente novamente com mais luz e o celular firme")
    face = request.app.state.embedder.embed(img)
    if face.face_size_px < settings.min_face_size_px:
        raise FaceError("face_too_small", "Rosto muito distante. Aproxime o rosto da câmera")
    quality = QualityInfo(face_detected=True, face_size_px=face.face_size_px, sharpness=round(sharp, 2))
    return img, face, quality


@router.post("/enroll", response_model=EnrollResponse)
def enroll(body: EnrollRequest, request: Request, settings: Settings = Depends(get_settings)):
    img, face, quality = _analyze(request, body.image_b64, settings)
    liveness = request.app.state.liveness.check(img)
    if liveness.checked and liveness.passed is False:
        raise FaceError("liveness_failed", "Não foi possível confirmar que é uma pessoa real")
    return EnrollResponse(
        embedding=[float(x) for x in face.embedding],
        model_version=request.app.state.embedder.model_version,
        quality=quality,
    )


@router.post("/verify", response_model=VerifyResponse)
def verify(body: VerifyRequest, request: Request, settings: Settings = Depends(get_settings)):
    img, face, quality = _analyze(request, body.image_b64, settings)
    liveness = request.app.state.liveness.check(img)
    try:
        sim = cosine_similarity(face.embedding, np.asarray(body.embedding, dtype=np.float32))
    except ValueError as e:
        raise FaceError("invalid_embedding", str(e), 400)
    threshold = settings.threshold_payment if body.purpose == "payment" else settings.threshold_login
    live_ok = not (liveness.checked and liveness.passed is False)
    return VerifyResponse(
        similarity=round(sim, 4),
        similarity_percent=round(max(0.0, sim) * 100, 1),
        is_match=bool(sim >= threshold and live_ok),
        threshold=threshold,
        liveness=liveness,
        quality=quality,
        model_version=request.app.state.embedder.model_version,
    )
