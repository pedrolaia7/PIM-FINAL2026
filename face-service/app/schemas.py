from typing import Literal, Optional

from pydantic import BaseModel, Field

Purpose = Literal["login", "payment"]


class EnrollRequest(BaseModel):
    image_b64: str = Field(..., description="Imagem JPEG/PNG em base64 (sem prefixo data:)")


class QualityInfo(BaseModel):
    face_detected: bool
    face_size_px: int
    sharpness: float


class LivenessInfo(BaseModel):
    checked: bool
    passed: Optional[bool] = None
    provider: str = "none"


class EnrollResponse(BaseModel):
    embedding: list[float]
    model_version: str
    quality: QualityInfo


class VerifyRequest(BaseModel):
    image_b64: str
    embedding: list[float] = Field(..., description="Embedding cadastrado do usuário")
    purpose: Purpose = "payment"


class VerifyResponse(BaseModel):
    similarity: float = Field(..., description="Similaridade de cosseno (-1..1)")
    similarity_percent: float = Field(..., description="max(0, cosseno) * 100. NÃO é probabilidade.")
    is_match: bool
    threshold: float
    liveness: LivenessInfo
    quality: QualityInfo
    model_version: str


class ErrorResponse(BaseModel):
    code: str
    message: str
