import numpy as np
import pytest

from app.services.matcher import cosine_similarity


def test_identical_vectors():
    v = np.array([1.0, 2.0, 3.0])
    assert cosine_similarity(v, v) == pytest.approx(1.0)


def test_orthogonal_vectors():
    assert cosine_similarity(np.array([1.0, 0]), np.array([0, 1.0])) == pytest.approx(0.0)


def test_dimension_mismatch():
    with pytest.raises(ValueError):
        cosine_similarity(np.array([1.0, 0]), np.array([1.0, 0, 0]))


def test_zero_vector():
    with pytest.raises(ValueError):
        cosine_similarity(np.zeros(3), np.ones(3))
