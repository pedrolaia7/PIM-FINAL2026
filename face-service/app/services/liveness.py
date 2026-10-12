"""Prova de vida (anti-spoofing).

IMPORTANTE: o provedor padrão ("none") NÃO verifica nada. Sem liveness, uma foto
impressa ou uma imagem na tela pode passar na verificação. Antes de ir para
produção, implemente um provedor real (ex.: Silent-Face-Anti-Spoofing, um serviço
de liveness ativo/passivo) e configure o backend C# com Face:RequireLiveness=true.
"""
from typing import Protocol

from PIL import Image

from ..schemas import LivenessInfo


class LivenessProvider(Protocol):
    name: str

    def check(self, img: Image.Image) -> LivenessInfo: ...


class NoLiveness:
    name = "none"

    def check(self, img: Image.Image) -> LivenessInfo:
        return LivenessInfo(checked=False, passed=None, provider=self.name)


def build_liveness(provider: str) -> LivenessProvider:
    if provider == "none":
        return NoLiveness()
    raise ValueError(f"Provedor de liveness desconhecido: {provider}. Implemente-o em liveness.py")
