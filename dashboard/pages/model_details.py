"""Model page — coefficients forest plot, condensed diagnostics, VIF, metadata."""

from pathlib import Path

import dash
from dash import Input, Output, callback, dash_table, dcc, html

from components import data_loader, plots

dash.register_page(__name__, path="/model", name="Model", order=2)


def layout():
    return html.Div(
        [html.H1("Model"), html.Div(id="model-details-content")],
        className="page-body",
    )


@callback(
    Output("model-details-content", "children"),
    Input("dropdown-model", "value"),
    Input("store-config", "data"),
)
def render_model_details(model_id, cfg):
    if not model_id or not cfg:
        return html.P("No model selected.", className="empty-state")

    exports_dir = str(Path(cfg.get("models_dir", "")) / "exports")
    manifest    = data_loader.load_manifest(exports_dir, model_id)
    vif         = data_loader.load_vif(exports_dir, model_id)
    coef_df     = data_loader.load_coefficients(exports_dir, model_id)

    if not manifest:
        return html.P(f"No exported data found for {model_id}.", className="empty-state")

    diag = manifest.get("diagnostics", {})

    return html.Div(
        [
            _coefficients_section(coef_df),
            _diagnostics_section(diag),
            _vif_section(vif),
            _metadata_section(manifest),
        ]
    )


# ---------------------------------------------------------------------------
# Coefficients
# ---------------------------------------------------------------------------

def _coefficients_section(coef_df) -> html.Div:
    if coef_df.empty:
        return html.Div()
    return html.Div(
        [
            html.H3("Coefficients"),
            dcc.Graph(figure=plots.forest_plot(coef_df), config={"displayModeBar": False}),
            html.Details(
                [
                    html.Summary("Coefficient table", style={"cursor": "pointer", "marginTop": "0.75rem"}),
                    dash_table.DataTable(
                        data=coef_df.round(6).to_dict("records"),
                        columns=[{"name": c, "id": c} for c in coef_df.columns],
                        sort_action="native",
                        style_table={"overflowX": "auto", "marginTop": "0.5rem"},
                        style_cell={"fontFamily": "var(--font-mono)", "fontSize": "0.82rem", "padding": "4px 8px"},
                        style_header={"fontWeight": "bold", "backgroundColor": "#f4f4f4"},
                    ),
                ]
            ),
        ],
        className="card",
    )


# ---------------------------------------------------------------------------
# Diagnostics — grouped compact tables
# ---------------------------------------------------------------------------

def _diagnostics_section(diag: dict) -> html.Div:
    def _row(label, val, flag_bad=None):
        formatted = _fmt(val)
        style = {}
        if flag_bad is not None and val is not None:
            try:
                is_bad = bool(val) if isinstance(val, bool) else flag_bad(val)
                if is_bad:
                    style = {"color": "#cc2200", "fontWeight": "600"}
            except Exception:
                pass
        return html.Tr([
            html.Td(label, className="diag-key"),
            html.Td(formatted, className="diag-val", style=style),
        ])

    def _table(rows):
        return html.Table(html.Tbody(rows), className="diag-table")

    fit_table = _table([
        _row("AIC",        diag.get("aic")),
        _row("AICc",       diag.get("aicc")),
        _row("BIC",        diag.get("bic")),
        _row("HQIC",       diag.get("hqic")),
        _row("Log-lik",    diag.get("loglik")),
        _row("Pseudo-R²",  diag.get("pseudoR2")),
    ])

    sample_table = _table([
        _row("N obs",         diag.get("nObs")),
        _row("N countries",   diag.get("nCountries")),
        _row("N predictors",  diag.get("nPredictors")),
        _row("N significant", diag.get("nSignificant")),
        _row("k / N",         diag.get("kOverN")),
    ])

    flag_table = _table([
        _row("Overfitting",   diag.get("overfitting"),   flag_bad=lambda v: v is True),
        _row("Separation",    diag.get("separation"),    flag_bad=lambda v: v is True),
        _row("High-Z",        diag.get("highZ"),         flag_bad=lambda v: v is True),
        _row("Max |Z|",       diag.get("maxAbsZ")),
        _row("Converged",     diag.get("converged")),
        _row("Maxit warning", diag.get("maxitWarning"),  flag_bad=lambda v: v is True),
        _row("Rejection",     diag.get("rejectionReason")),
    ])

    return html.Div(
        [
            html.H3("Diagnostics"),
            html.Div(
                [
                    html.Div([html.H4("Fit quality"), fit_table],   className="diag-group"),
                    html.Div([html.H4("Sample"),       sample_table], className="diag-group"),
                    html.Div([html.H4("Flags"),        flag_table],   className="diag-group"),
                ],
                className="diag-groups",
            ),
        ],
        className="card",
    )


# ---------------------------------------------------------------------------
# VIF
# ---------------------------------------------------------------------------

def _vif_section(vif: dict) -> html.Div:
    if not vif:
        return html.Div()
    values  = vif.get("values", {})
    flagged = vif.get("flagged", [])
    rows = [
        {"variable": k, "vif": round(v, 3), "flagged": "yes" if k in flagged else ""}
        for k, v in values.items()
    ]
    return html.Div(
        [
            html.H3("Variance Inflation Factors"),
            html.P(
                f"Max VIF: {vif.get('maxVIF', '—'):.3f}   "
                f"High-VIF: {'yes' if vif.get('highVIF') else 'no'}",
                className="vif-summary",
            ),
            dash_table.DataTable(
                data=rows,
                columns=[
                    {"name": "Variable", "id": "variable"},
                    {"name": "VIF",      "id": "vif", "type": "numeric"},
                    {"name": "Flagged",  "id": "flagged"},
                ],
                sort_action="native",
                style_table={"overflowX": "auto", "maxWidth": "420px"},
                style_cell={"fontFamily": "var(--font-mono)", "fontSize": "0.82rem", "padding": "4px 8px"},
                style_header={"fontWeight": "bold", "backgroundColor": "#f4f4f4"},
                style_data_conditional=[
                    {"if": {"filter_query": "{flagged} = 'yes'"}, "color": "#cc2200"},
                ],
            ),
        ],
        className="card",
    )


# ---------------------------------------------------------------------------
# Metadata (moved to end)
# ---------------------------------------------------------------------------

def _metadata_section(manifest: dict) -> html.Div:
    items = [
        ("ID (short)",     manifest.get("id")),
        ("ID (full)",      manifest.get("id_full")),
        ("Label",          manifest.get("label")),
        ("Sector",         manifest.get("sector")),
        ("Stage",          manifest.get("stage")),
        ("Family",         manifest.get("family")),
        ("Firth penalty",  manifest.get("useFirth")),
        ("Training years", f"{manifest.get('training_year_min')} – {manifest.get('training_year_max')}"),
        ("Formula",        manifest.get("formula")),
        ("pfm version",    manifest.get("pfm_version")),
        ("Created at",     manifest.get("created_at")),
        ("Exported at",    manifest.get("exported_at")),
        ("Data hash",      manifest.get("data_hash")),
    ]
    return html.Div(
        [
            html.H3("Metadata"),
            html.Dl(
                [child for k, v in items
                 for child in [html.Dt(k), html.Dd(str(v) if v is not None else "—")]],
                className="metadata-grid",
            ),
        ],
        className="card",
    )


def _fmt(v) -> str:
    if v is None or v == {}:
        return "—"
    if isinstance(v, bool):
        return "yes" if v else "no"
    if isinstance(v, float):
        return f"{v:.4f}"
    return str(v)
