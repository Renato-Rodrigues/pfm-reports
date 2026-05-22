"""Helpers for reading per-model flat-file exports."""

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

import pandas as pd


def _model_dir(exports_dir: str, model_id: str) -> Path:
    return Path(exports_dir) / model_id


# ---------------------------------------------------------------------------
# JSON artefacts
# ---------------------------------------------------------------------------

def load_manifest(exports_dir: str, model_id: str) -> dict:
    path = _model_dir(exports_dir, model_id) / "manifest.json"
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


def load_vif(exports_dir: str, model_id: str) -> dict:
    path = _model_dir(exports_dir, model_id) / "vif.json"
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Parquet artefacts
# ---------------------------------------------------------------------------

def load_coefficients(exports_dir: str, model_id: str) -> pd.DataFrame:
    return _read_parquet(_model_dir(exports_dir, model_id) / "coefficients.parquet")


def load_training_data(exports_dir: str, model_id: str) -> pd.DataFrame:
    return _read_parquet(_model_dir(exports_dir, model_id) / "training_data.parquet")


def load_fitted_values(exports_dir: str, model_id: str) -> pd.DataFrame:
    return _read_parquet(_model_dir(exports_dir, model_id) / "fitted_values.parquet")


def load_correlation(exports_dir: str, model_id: str, kind: str = "pearson") -> pd.DataFrame:
    filename = f"correlation_{kind}.parquet"
    return _read_parquet(_model_dir(exports_dir, model_id) / filename)


# ---------------------------------------------------------------------------
# Projections
# ---------------------------------------------------------------------------

def list_projection_files(exports_dir: str, model_id: str) -> list[str]:
    proj_dir = _model_dir(exports_dir, model_id) / "projections"
    if not proj_dir.exists():
        return []
    return [p.stem for p in proj_dir.glob("*.parquet")]


def load_projection(exports_dir: str, model_id: str, name: str) -> pd.DataFrame:
    path = _model_dir(exports_dir, model_id) / "projections" / f"{name}.parquet"
    return _read_parquet(path)


def load_projection_metadata(exports_dir: str, model_id: str) -> dict:
    path = _model_dir(exports_dir, model_id) / "projections" / "metadata.json"
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

def _read_parquet(path: Path) -> pd.DataFrame:
    if not path.exists():
        return pd.DataFrame()
    return pd.read_parquet(path)
