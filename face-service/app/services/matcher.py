import numpy as np


def normalize(v: np.ndarray) -> np.ndarray:
    n = np.linalg.norm(v)
    if n == 0:
        raise ValueError("embedding nulo")
    return v / n


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    a = normalize(np.asarray(a, dtype=np.float32))
    b = normalize(np.asarray(b, dtype=np.float32))
    if a.shape != b.shape:
        raise ValueError("dimensões de embedding diferentes")
    return float(np.clip(np.dot(a, b), -1.0, 1.0))
