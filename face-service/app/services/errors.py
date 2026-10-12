class FaceError(Exception):
    """Erro de domínio do reconhecimento facial, mapeado para HTTP 422/400."""

    def __init__(self, code: str, message: str, http_status: int = 422):
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = http_status
