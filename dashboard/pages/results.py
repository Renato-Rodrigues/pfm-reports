"""Results page — fitted vs actual scatter and time series."""

from pathlib import Path

import dash
from dash import Input, Output, callback, dcc, html

from components import data_loader, plots

dash.register_page(__name__, path="/results", name="Results", order=3)


def layout():
    return html.Div(
        [html.H1("Results"), html.Div(id="results-content")],
        className="page-body",
    )


@callback(
    Output("results-content", "children"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def render_results(model_id, cfg):
    if not model_id or not cfg:
        return html.P("No model selected.", className="empty-state")

    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    fv_df = data_loader.load_fitted_values(exports_dir, model_id)

    if fv_df.empty:
        return html.P(f"No fitted values found for model {model_id}.", className="empty-state")

    has_actual = fv_df["actual"].notna().any()
    regions = sorted(fv_df["region"].dropna().unique().tolist()) if "region" in fv_df.columns else []

    scatter = html.Div(
        [
            html.H3("Fitted vs observed"),
            dcc.Graph(figure=plots.fitted_vs_actual(fv_df, model_id),
                      config={"displayModeBar": False})
            if has_actual else html.P("Actual values not available."),
        ],
        className="card",
    )

    time_series = html.Div(
        [
            html.H3("Time series"),
            dcc.Graph(figure=plots.fitted_time_series(fv_df, actual=has_actual),
                      config={"displayModeBar": False}),
        ],
        className="card",
    )

    region_filter = html.Div(
        [
            html.H3("Filter by region"),
            dcc.Dropdown(
                id="results-region-filter",
                options=[{"label": r, "value": r} for r in regions],
                value=[],
                multi=True,
                placeholder="All regions",
                className="inline-dropdown",
            ),
            dcc.Graph(id="results-filtered-ts", config={"displayModeBar": False}),
        ],
        className="card",
    ) if regions else html.Div()

    return html.Div([scatter, time_series, region_filter])


@callback(
    Output("results-filtered-ts", "figure"),
    Input("results-region-filter", "value"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def update_filtered_ts(selected_regions, model_id, cfg):
    if not model_id or not cfg:
        return {}
    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    fv_df = data_loader.load_fitted_values(exports_dir, model_id)
    if fv_df.empty:
        return {}
    if selected_regions:
        fv_df = fv_df[fv_df["region"].isin(selected_regions)]
    return plots.fitted_time_series(fv_df, actual=fv_df["actual"].notna().any())
