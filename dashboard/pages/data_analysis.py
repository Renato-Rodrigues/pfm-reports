"""Data page — training data distributions and correlation matrices."""

from pathlib import Path

import dash
from dash import Input, Output, callback, dash_table, dcc, html

from components import data_loader, plots

dash.register_page(__name__, path="/data", name="Data", order=1)


def layout():
    return html.Div(
        [
            html.H1("Data"),
            html.Div(id="data-analysis-content"),
        ],
        className="page-body",
    )


@callback(
    Output("data-analysis-content", "children"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def render_data_analysis(model_id, cfg):
    if not model_id or not cfg:
        return html.P("No model selected.", className="empty-state")

    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    td_df       = data_loader.load_training_data(exports_dir, model_id)
    cor_pearson  = data_loader.load_correlation(exports_dir, model_id, "pearson")
    cor_spearman = data_loader.load_correlation(exports_dir, model_id, "spearman")

    if td_df.empty:
        return html.P(f"No training data found for model {model_id}.", className="empty-state")

    numeric_cols = td_df.select_dtypes("number").columns.tolist()
    summary = td_df[numeric_cols].describe().T.round(4).reset_index()
    summary.rename(columns={"index": "variable"}, inplace=True)

    summary_section = html.Div(
        [
            html.H3("Summary statistics"),
            dash_table.DataTable(
                data=summary.to_dict("records"),
                columns=[{"name": c, "id": c} for c in summary.columns],
                sort_action="native",
                style_table={"overflowX": "auto"},
                style_cell={"fontFamily": "var(--font-mono)", "fontSize": "0.82rem", "padding": "4px 8px"},
                style_header={"fontWeight": "bold", "backgroundColor": "#f4f4f4"},
            ),
        ],
        className="card",
    )

    hist_options = [{"label": c, "value": c} for c in numeric_cols]
    hist_section = html.Div(
        [
            html.H3("Variable distribution"),
            dcc.Dropdown(
                id="hist-col-select",
                options=hist_options,
                value=numeric_cols[0] if numeric_cols else None,
                clearable=False,
                className="inline-dropdown",
            ),
            dcc.Graph(id="hist-graph", config={"displayModeBar": False}),
        ],
        className="card",
    )

    cor_section = html.Div(
        [
            html.H3("Correlation matrices"),
            html.Div(
                [
                    html.Div(
                        dcc.Graph(figure=plots.correlation_heatmap(cor_pearson, "Pearson"),
                                  config={"displayModeBar": False})
                        if not cor_pearson.empty else html.P("No Pearson matrix."),
                        className="half-width",
                    ),
                    html.Div(
                        dcc.Graph(figure=plots.correlation_heatmap(cor_spearman, "Spearman"),
                                  config={"displayModeBar": False})
                        if not cor_spearman.empty else html.P("No Spearman matrix."),
                        className="half-width",
                    ),
                ],
                className="two-col",
            ),
        ],
        className="card",
    )

    return html.Div([summary_section, hist_section, cor_section])


@callback(
    Output("hist-graph", "figure"),
    Input("hist-col-select", "value"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def update_histogram(col, model_id, cfg):
    if not col or not model_id or not cfg:
        return {}
    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    td_df = data_loader.load_training_data(exports_dir, model_id)
    if td_df.empty or col not in td_df.columns:
        return {}
    return plots.variable_histogram(td_df, col)
