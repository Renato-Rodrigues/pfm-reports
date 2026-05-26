"""PFM Dashboard — multi-page Dash app for exploring PFMModel exports."""

import json
import subprocess
import time
from pathlib import Path

import dash
from dash import Dash, Input, Output, State, dcc, html

from components.sidebar import sidebar_layout

CONFIG_PATH      = Path(__file__).parent / "dashboard_config.json"
RSCRIPT_EXPORT   = Path(__file__).parent.parent / "src" / "r" / "exportForDashboard.R"
PFM_REPORTS_ROOT = Path(__file__).parent.parent


# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

def get_py_config(key: str, default: str = "") -> str:
    config_path = PFM_REPORTS_ROOT / "config.yml"
    example_path = PFM_REPORTS_ROOT / "config.yml.example"
    
    path = config_path if config_path.exists() else example_path
    if not path.exists():
        return default
        
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if ":" in line:
                    k, v = line.split(":", 1)
                    if k.strip() == key:
                        val = v.strip().strip("'\"")
                        return val
    except Exception:
        pass
    return default


def load_config() -> dict:
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            return json.load(f)
    
    fallback_dir = get_py_config("dashboardModelsDir", "")
    if fallback_dir:
        cfg = {"models_dir": fallback_dir}
        save_config(cfg)
        return cfg
        
    return {"models_dir": ""}


def save_config(cfg: dict) -> None:
    with open(CONFIG_PATH, "w") as f:
        json.dump(cfg, f, indent=2)


def exports_dir(models_dir: str) -> Path:
    return Path(models_dir) / "exports"


def exports_index(models_dir: str) -> Path:
    return exports_dir(models_dir) / "index.json"


def _abs(path: str) -> str:
    p = Path(path)
    return str(p if p.is_absolute() else PFM_REPORTS_ROOT / p)


def _needs_export(models_dir: str) -> tuple[bool, str]:
    r_idx_path = Path(models_dir) / "index.json"
    if not r_idx_path.exists():
        return False, "No index.json in models folder."

    with open(r_idx_path) as f:
        r_models = json.load(f)
    r_ids = {m["id"] for m in r_models}

    ex_idx = exports_index(models_dir)
    if not ex_idx.exists():
        return True, f"No exports — will export {len(r_ids)} model(s)."

    with open(ex_idx) as f:
        ex_models = json.load(f)
    exported_ok = {m["id"] for m in ex_models if m.get("export_status") == "ok"}

    missing = r_ids - exported_ok
    if missing:
        return True, f"{len(missing)} model(s) not yet exported."

    return False, f"{len(r_ids)} model(s) already loaded."


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = Dash(
    __name__,
    use_pages=True,
    suppress_callback_exceptions=True,
    external_stylesheets=["/assets/style.css"],
)

app.layout = html.Div(
    [
        # Stores — dropdown-model.value is the live active-model state (no store-active-model)
        dcc.Store(id="store-config",         storage_type="session"),
        dcc.Store(id="store-model-index",    storage_type="session"),
        dcc.Store(id="store-export-log",     storage_type="session"),
        dcc.Store(id="store-export-needed",  storage_type="memory"),
        dcc.Store(id="store-export-trigger", storage_type="memory"),
        dcc.Store(id="store-loading-state",  storage_type="memory"),

        dcc.Interval(id="interval-noop", interval=999_999_999, n_intervals=0),

        # Full-screen loading overlay — blocks all interaction while R export runs.
        # Shown/hidden via clientside callback for instant response (no server round-trip).
        html.Div(
            html.Div(
                [
                    html.Div(className="modal-spinner", id="modal-spinner"),
                    html.H3("Loading models…", id="modal-title", className="modal-title"),
                    html.P(
                        "Exporting from R — this may take a few minutes on first run.",
                        id="modal-subtitle",
                        className="modal-subtitle",
                    ),
                    html.Pre("", id="modal-log", className="modal-log"),
                    html.Button(
                        "Close", id="btn-close-modal", n_clicks=0,
                        className="btn-primary", style={"display": "none"},
                    ),
                ],
                className="modal-card",
            ),
            id="loading-overlay",
            className="loading-overlay",
            style={"display": "none"},
        ),

        html.Header(
            [
                html.Span("PFM Dashboard", className="topbar-brand"),
                html.Nav(
                    [
                        dcc.Link("Model List",  href="/",            className="topbar-link"),
                        dcc.Link("Data",        href="/data",        className="topbar-link"),
                        dcc.Link("Model",       href="/model",       className="topbar-link"),
                        dcc.Link("Results",     href="/results",     className="topbar-link"),
                        dcc.Link("Projections", href="/projections", className="topbar-link"),
                    ],
                    className="topbar-nav",
                ),
            ],
            className="topbar",
        ),

        html.Div(
            [
                html.Div(sidebar_layout(), id="sidebar", className="sidebar"),
                html.Div(dash.page_container, id="page-content", className="page-content"),
            ],
            className="app-shell",
        ),
    ]
)


# ---------------------------------------------------------------------------
# Clientside overlay toggle — runs instantly in browser, no server round-trip
# ---------------------------------------------------------------------------

app.clientside_callback(
    """
    function(state) {
        var hidden = {"display": "none"};
        var no_update = window.dash_clientside.no_update;
        if (!state) {
            return [hidden, no_update, no_update, no_update, hidden, no_update];
        }
        if (state === "running") {
            return [
                {"display": "flex"},
                "Loading models…",
                "Exporting from R — this may take a few minutes on first run.",
                "",
                hidden,
                {}
            ];
        }
        return [
            {"display": "flex"},
            "Export failed",
            state.message || "An unknown error occurred.",
            state.log || "",
            {"display": "inline-block"},
            hidden
        ];
    }
    """,
    Output("loading-overlay", "style"),
    Output("modal-title", "children"),
    Output("modal-subtitle", "children"),
    Output("modal-log", "children"),
    Output("btn-close-modal", "style"),
    Output("modal-spinner", "style"),
    Input("store-loading-state", "data"),
)


@app.callback(
    Output("store-loading-state", "data", allow_duplicate=True),
    Input("btn-close-modal", "n_clicks"),
    prevent_initial_call=True,
)
def close_modal(_):
    return None


# ---------------------------------------------------------------------------
# Bootstrap config
# ---------------------------------------------------------------------------

@app.callback(
    Output("store-config", "data"),
    Input("interval-noop", "n_intervals"),
    prevent_initial_call=False,
)
def init_config(_):
    return load_config()


# ---------------------------------------------------------------------------
# Check if export is needed (fast — reads index files only)
# ---------------------------------------------------------------------------

@app.callback(
    Output("store-export-needed", "data"),
    Input("store-config", "data"),
    Input("store-export-log", "data"),
    prevent_initial_call=False,
)
def check_export_needed(cfg, _log):
    if not cfg:
        return {"needed": False, "reason": ""}
    models_dir = cfg.get("models_dir", "")
    if not models_dir or not Path(models_dir).is_dir():
        return {"needed": False, "reason": ""}
    r_idx = Path(models_dir) / "index.json"
    if not r_idx.exists():
        return {"needed": False, "reason": "No index.json in selected folder."}
    needed, reason = _needs_export(models_dir)
    return {"needed": needed, "reason": reason}


# ---------------------------------------------------------------------------
# Run export when triggered (slow — blocks until Rscript finishes)
# ---------------------------------------------------------------------------

@app.callback(
    Output("store-export-log", "data"),
    Output("store-loading-state", "data"),
    Input("store-export-trigger", "data"),
    State("store-config", "data"),
    prevent_initial_call=True,
)
def run_export(trigger, cfg):
    if not trigger or not cfg:
        return dash.no_update, None

    models_dir = cfg.get("models_dir", "")
    if not models_dir or not Path(models_dir).is_dir():
        return dash.no_update, {
            "status": "error", "message": "Models folder not found.", "log": "",
        }

    ex_dir = str(exports_dir(models_dir))
    cmd = ["Rscript", str(RSCRIPT_EXPORT), _abs(models_dir), ex_dir]
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=600,
            cwd=str(PFM_REPORTS_ROOT),
        )
        log = (result.stdout + result.stderr).strip()
        if result.returncode == 0:
            return {"log": log, "returncode": 0, "ts": time.time()}, None
        error_lines = [ln for ln in log.splitlines() if ln.strip()]
        last = error_lines[-1] if error_lines else f"exit {result.returncode}"
        return (
            {"log": log, "returncode": result.returncode, "ts": time.time()},
            {"status": "error", "message": f"Export failed: {last}", "log": log},
        )
    except subprocess.TimeoutExpired:
        return dash.no_update, {
            "status": "error", "message": "Export timed out (>10 min).", "log": "",
        }
    except FileNotFoundError:
        return dash.no_update, {
            "status": "error", "message": "Rscript not found — is R on PATH?", "log": "",
        }


# ---------------------------------------------------------------------------
# Refresh model index
# ---------------------------------------------------------------------------

@app.callback(
    Output("store-model-index", "data"),
    Input("store-export-log", "data"),
    Input("store-config", "data"),
    prevent_initial_call=False,
)
def refresh_model_index(export_log, cfg):
    if not cfg:
        return []
    models_dir = cfg.get("models_dir", "")
    if not models_dir:
        return []
    idx_path = exports_index(models_dir)
    if not idx_path.exists():
        return []
    with open(idx_path) as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Model dropdown — populated from index; preserves current selection when
# index reloads. dropdown-model.value IS the active-model state (no separate
# store needed — avoids the bidirectional-sync cycle).
# ---------------------------------------------------------------------------

@app.callback(
    Output("dropdown-model", "options"),
    Output("dropdown-model", "value"),
    Input("store-model-index", "data"),
    State("dropdown-model", "value"),
    prevent_initial_call=False,
)
def populate_model_dropdown(index, current_value):
    if not index:
        return [], None
    options = [
        {"label": f"{m['id']} — {m.get('sector','?')}/{m.get('stage','?')}", "value": m["id"]}
        for m in index
        if m.get("export_status") == "ok"
    ]
    value = current_value if any(o["value"] == current_value for o in options) else (
        options[0]["value"] if options else None
    )
    return options, value


# ---------------------------------------------------------------------------
# Active model info card (sidebar) — driven by dropdown value directly
# ---------------------------------------------------------------------------

@app.callback(
    Output("active-model-card", "children"),
    Input("dropdown-model", "value"),
    Input("store-model-index", "data"),
)
def update_active_model_card(model_id, index):
    if not model_id or not index:
        return html.P("No model selected.", className="no-model-text")
    m = next((m for m in index if m.get("id") == model_id), None)
    if not m:
        return html.P("Model not found.", className="no-model-text")

    def _v(val, fmt=".3f"):
        try:
            return format(float(val), fmt) if val is not None else "—"
        except (TypeError, ValueError):
            return str(val) if val is not None else "—"

    return html.Div(
        [
            html.Div(model_id, className="model-card-id"),
            html.Div(f"{m.get('sector', '?')}  ·  {m.get('stage', '?')}", className="model-card-meta"),
            html.Table(
                html.Tbody([
                    html.Tr([html.Td("AIC",   className="mc-key"), html.Td(_v(m.get("aic"),      ".1f"), className="mc-val")]),
                    html.Tr([html.Td("R²",    className="mc-key"), html.Td(_v(m.get("pseudoR2"), ".3f"), className="mc-val")]),
                    html.Tr([html.Td("N obs", className="mc-key"), html.Td(_v(m.get("nObs"),     ".0f"), className="mc-val")]),
                ]),
                className="model-card-stats",
            ),
        ],
        className="model-info-card",
    )


if __name__ == "__main__":
    app.run(debug=True, port=8050)
