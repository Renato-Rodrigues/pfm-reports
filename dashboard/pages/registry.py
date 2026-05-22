"""Model List page — folder/export controls + model index table."""

import json
import time
import tkinter
import tkinter.filedialog
from pathlib import Path

import dash
from dash import Input, Output, State, callback, dash_table, dcc, html
from dash.dash_table import Format

dash.register_page(__name__, path="/", name="Model List", order=0)

_CONFIG_PATH = Path(__file__).parent.parent / "dashboard_config.json"
_PFM_REPORTS_ROOT = Path(__file__).parent.parent.parent


def _read_config() -> dict:
    if _CONFIG_PATH.exists():
        with open(_CONFIG_PATH) as f:
            return json.load(f)
    return {"models_dir": ""}


def _exports_dir(models_dir: str) -> str:
    return str(Path(models_dir) / "exports") if models_dir else ""


def _read_index(exports_dir: str) -> list:
    if not exports_dir:
        return []
    idx = Path(exports_dir) / "index.json"
    if not idx.exists():
        return []
    try:
        with open(idx) as f:
            return json.load(f)
    except Exception:
        return []


def _build_rows(index: list) -> list:
    return [
        {
            "id":            m.get("id"),
            "sector":        m.get("sector"),
            "stage":         m.get("stage"),
            "aic":           m.get("aic"),
            "pseudoR2":      m.get("pseudoR2"),
            "nObs":          m.get("nObs"),
            "nCountries":    m.get("nCountries"),
            "nSignificant":  m.get("nSignificant"),
            "exported_at":   m.get("exported_at"),
            "export_status": m.get("export_status"),
        }
        for m in index
    ]


_COLUMNS = [
    {"name": "Stage",         "id": "stage"},
    {"name": "Sector",        "id": "sector"},
    {"name": "AIC",           "id": "aic",          "type": "numeric", "format": Format.Format(precision=1, scheme=Format.Scheme.fixed)},
    {"name": "Pseudo-R²",     "id": "pseudoR2",     "type": "numeric", "format": Format.Format(precision=3, scheme=Format.Scheme.fixed)},
    {"name": "N obs",         "id": "nObs",         "type": "numeric"},
    {"name": "N countries",   "id": "nCountries",   "type": "numeric"},
    {"name": "N significant", "id": "nSignificant", "type": "numeric"},
    {"name": "Exported at",   "id": "exported_at"},
    {"name": "Export status", "id": "export_status"},
    {"name": "ID",            "id": "id"},
]


def layout():
    """Pre-populate at mount time so table is never blank on navigation."""
    cfg = _read_config()
    models_dir = cfg.get("models_dir", "")
    exports_dir = _exports_dir(models_dir)
    index = _read_index(exports_dir)
    initial_rows = _build_rows(index)

    return html.Div(
        [
            html.H1("Model List"),

            html.Div(
                [
                    html.Div(
                        [
                            html.Label("Models folder", className="section-label"),
                            html.Div(
                                [
                                    dcc.Input(
                                        id="input-models-dir",
                                        type="text",
                                        value=models_dir,
                                        placeholder="Path to models folder…",
                                        debounce=True,
                                        className="path-input",
                                    ),
                                    html.Button("…", id="btn-browse-models", n_clicks=0,
                                                className="btn-browse", title="Select models folder"),
                                ],
                                className="folder-row",
                            ),
                        ],
                        className="control-group",
                    ),
                    html.Div(
                        [
                            html.Label("​", className="section-label"),
                            html.Div(
                                [
                                    html.Button(
                                        "Load models",
                                        id="btn-export",
                                        n_clicks=0,
                                        className="btn-primary",
                                        disabled=True,
                                    ),
                                    html.Span(id="export-status-text", className="export-status"),
                                ],
                                className="export-row",
                            ),
                        ],
                        className="control-group",
                    ),
                ],
                className="card controls-card",
            ),

            html.Div(
                [
                    dash_table.DataTable(
                        id="registry-table",
                        columns=_COLUMNS,
                        data=initial_rows,
                        row_selectable="single",
                        selected_rows=[],
                        sort_action="native",
                        sort_mode="multi",
                        filter_action="native",
                        page_size=20,
                        style_table={"overflowX": "auto"},
                        style_cell={
                            "fontFamily": "var(--font-mono)",
                            "fontSize": "0.83rem",
                            "padding": "6px 10px",
                            "whiteSpace": "nowrap",
                        },
                        style_header={"fontWeight": "700", "backgroundColor": "#f4f4f4"},
                        style_data_conditional=[
                            {"if": {"filter_query": "{export_status} = 'ok'"},    "color": "#1a6faf"},
                            {"if": {"filter_query": "{export_status} = 'error'"}, "color": "#cc2200"},
                            {"if": {"row_index": "odd"}, "backgroundColor": "#fafafa"},
                        ],
                    ),
                ],
                className="card",
            ),
        ],
        className="page-body",
    )


# ---- Persist models_dir when input changes ----

@callback(
    Output("store-config", "data", allow_duplicate=True),
    Input("input-models-dir", "value"),
    State("store-config", "data"),
    prevent_initial_call=True,
)
def update_models_dir(new_dir, cfg):
    if not new_dir or not cfg:
        return dash.no_update
    cfg = dict(cfg)
    cfg["models_dir"] = str(Path(new_dir))
    with open(_CONFIG_PATH, "w") as f:
        json.dump(cfg, f, indent=2)
    return cfg


# ---- Browse for models folder ----

@callback(
    Output("input-models-dir", "value"),
    Input("btn-browse-models", "n_clicks"),
    State("input-models-dir", "value"),
    prevent_initial_call=True,
)
def browse_models_folder(n_clicks, current_value):
    root = tkinter.Tk()
    root.withdraw()
    root.wm_attributes("-topmost", True)
    p = Path(current_value) if current_value else Path.cwd()
    initial = str(p if p.is_dir() else p.parent)
    chosen = tkinter.filedialog.askdirectory(
        parent=root, title="Select models folder", initialdir=initial,
    )
    root.destroy()
    return chosen if chosen else dash.no_update


# ---- Enable/disable Load models button ----

@callback(
    Output("btn-export", "disabled"),
    Output("export-status-text", "children"),
    Input("store-export-needed", "data"),
    prevent_initial_call=False,
)
def update_btn_state(export_needed):
    if not export_needed:
        return True, ""
    needed = export_needed.get("needed", False)
    reason = export_needed.get("reason", "")
    return not needed, reason


# ---- Trigger export on button click → shows overlay immediately via clientside ----

@callback(
    Output("store-export-trigger", "data"),
    Output("store-loading-state", "data", allow_duplicate=True),
    Input("btn-export", "n_clicks"),
    prevent_initial_call=True,
)
def trigger_export(_):
    return {"ts": time.time()}, "running"


# ---- Reactive table update when model index changes ----

@callback(
    Output("registry-table", "data"),
    Output("registry-table", "selected_rows"),
    Input("store-model-index", "data"),
    State("dropdown-model", "value"),
)
def populate_table(index, active_id):
    if not index:
        return dash.no_update, dash.no_update
    rows = _build_rows(index)
    selected = []
    if active_id:
        ids = [r["id"] for r in rows]
        if active_id in ids:
            selected = [ids.index(active_id)]
    return rows, selected


# ---- Row click → update dropdown directly (dropdown-model.value IS the active model) ----

@callback(
    Output("dropdown-model", "value", allow_duplicate=True),
    Input("registry-table", "selected_rows"),
    State("registry-table", "data"),
    prevent_initial_call=True,
)
def select_from_table(selected_rows, data):
    if not selected_rows or not data:
        return dash.no_update
    return data[selected_rows[0]]["id"]
