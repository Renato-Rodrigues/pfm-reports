"""Projections page — scenario projection time series with threshold slider."""

from pathlib import Path

import dash
from dash import Input, Output, callback, dcc, html

from components import data_loader, plots

dash.register_page(__name__, path="/projections", name="Projections", order=4)


def layout():
    return html.Div(
        [html.H1("Projections"), html.Div(id="projections-content")],
        className="page-body",
    )


@callback(
    Output("projections-content", "children"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def render_projections(model_id, cfg):
    if not model_id or not cfg:
        return html.P("No model selected.", className="empty-state")

    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    proj_names  = data_loader.list_projection_files(exports_dir, model_id)
    proj_meta   = data_loader.load_projection_metadata(exports_dir, model_id)

    if not proj_names:
        return html.Div(
            [
                html.P("No projections attached to this model. "
                       "Run addProjections() and re-export.", className="empty-state"),
                _meta_section(proj_meta) if proj_meta else html.Div(),
            ]
        )

    return html.Div(
        [
            _meta_section(proj_meta),
            html.Div(
                [
                    html.H3("Projection dataset"),
                    dcc.Dropdown(
                        id="proj-dataset-select",
                        options=[{"label": n, "value": n} for n in sorted(proj_names)],
                        value=proj_names[0],
                        clearable=False,
                        className="inline-dropdown",
                    ),
                ],
                className="card",
            ),
            html.Div(id="proj-plot-area"),
        ]
    )


@callback(
    Output("proj-plot-area", "children"),
    Input("proj-dataset-select", "value"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
    prevent_initial_call=True,
)
def render_proj_dataset(name, model_id, cfg):
    if not name or not model_id or not cfg:
        return html.Div()
    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    df = data_loader.load_projection(exports_dir, model_id, name)
    if df.empty:
        return html.P(f"No data in projection '{name}'.", className="empty-state")

    numeric_cols = [c for c in df.select_dtypes("number").columns if c != "year"]
    if not numeric_cols:
        return html.P("No numeric columns to plot.", className="empty-state")

    default_col = numeric_cols[0]
    y_max = float(df[default_col].max())
    slider_max = max(1.0, round(y_max * 1.2, 2))

    return html.Div(
        [
            html.Div(
                [
                    html.Label("Y variable", className="section-label"),
                    dcc.Dropdown(
                        id="proj-col-select",
                        options=[{"label": c, "value": c} for c in numeric_cols],
                        value=default_col,
                        clearable=False,
                        className="inline-dropdown",
                    ),
                    html.Label("Threshold", className="section-label",
                               style={"marginTop": "1rem"}),
                    dcc.Slider(
                        id="proj-threshold-slider",
                        min=0, max=slider_max, step=0.01, value=0,
                        marks={0: "off", slider_max: str(round(slider_max, 2))},
                        tooltip={"placement": "bottom", "always_visible": True},
                    ),
                ],
                className="card",
            ),
            dcc.Graph(id="proj-main-graph", config={"displayModeBar": False}),
        ]
    )


@callback(
    Output("proj-main-graph", "figure"),
    Input("proj-col-select", "value"),
    Input("proj-threshold-slider", "value"),
    Input("proj-dataset-select", "value"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def update_proj_graph(y_col, threshold, name, model_id, cfg):
    if not y_col or not name or not model_id or not cfg:
        return {}
    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    df = data_loader.load_projection(exports_dir, model_id, name)
    if df.empty or y_col not in df.columns:
        return {}
    thr = threshold if threshold and threshold > 0 else None
    return plots.projection_time_series(df, y_col, title=f"{name} — {y_col}", threshold=thr)


def _meta_section(meta: dict) -> html.Div:
    if not meta:
        return html.Div()
    return html.Div(
        [
            html.H3("Projection metadata"),
            html.Dl(
                [child for k, v in meta.items()
                 for child in [html.Dt(k), html.Dd(str(v))]],
                className="metadata-grid",
            ),
        ],
        className="card",
    )
