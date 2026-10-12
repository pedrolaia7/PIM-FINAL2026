import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .api.v1 import faces
from .config import get_settings
from .services.embedder import build_embedder
from .services.errors import FaceError
from .services.liveness import build_liveness

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("face-service")


@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    if s.is_production and s.api_key == "troque-esta-chave":
        raise RuntimeError("Defina API_KEY em produção")
    app.state.embedder = build_embedder(s.embedder, s.is_production)
    app.state.liveness = build_liveness(s.liveness_provider)
    log.info("Embedder=%s liveness=%s", app.state.embedder.model_version, app.state.liveness.name)
    yield


app = FastAPI(title="TicketFut Face Service", version="1.0.0", lifespan=lifespan)
app.include_router(faces.router)


@app.exception_handler(FaceError)
async def face_error_handler(_: Request, exc: FaceError):
    return JSONResponse(status_code=exc.http_status, content={"code": exc.code, "message": exc.message})


@app.get("/health")
def health():
    return {"status": "ok"}
