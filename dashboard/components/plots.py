"""Reusable Plotly figure builders for PFM dashboard pages."""

import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots


# ---------------------------------------------------------------------------
# Coefficients / forest plot
# ---------------------------------------------------------------------------

def forest_plot(coef_df: pd.DataFrame) -> go.Figure:
    """Horizontal error-bar chart for model coefficients (forest plot)."""
    df = coef_df.copy().sort_values("estimate")
    df["significant"] = df["p_value"] < 0.05
    df["color"] = df["significant"].map({True: "#1a6faf", False: "#aaaaaa"})

    # 95 % CI: ± 1.96 * std_error
    df["ci_low"]  = df["estimate"] - 1.96 * df["std_error"]
    df["ci_high"] = df["estimate"] + 1.96 * df["std_error"]

    fig = go.Figure()
    for _, row in df.iterrows():
        fig.add_trace(
            go.Scatter(
                x=[row["ci_low"], row["estimate"], row["ci_high"]],
                y=[row["term"]] * 3,
                mode="lines+markers",
                marker=dict(
                    size=[0, 10, 0],
                    color=row["color"],
                    symbol=["line-ew", "circle", "line-ew"],
                ),
                line=dict(color=row["color"], width=2),
                showlegend=False,
                hovertemplate=(
                    f"<b>{row['term']}</b><br>"
                    f"Estimate: {row['estimate']:.4f}<br>"
                    f"95% CI: [{row['ci_low']:.4f}, {row['ci_high']:.4f}]<br>"
                    f"p-value: {row['p_value']:.4f}<extra></extra>"
                ),
            )
        )

    fig.add_vline(x=0, line_dash="dash", line_color="#888888", line_width=1)
    fig.update_layout(
        title="Coefficient estimates (95% CI)",
        xaxis_title="Estimate",
        yaxis_title=None,
        margin=dict(l=20, r=20, t=40, b=20),
        height=max(300, 40 * len(df)),
        plot_bgcolor="white",
        paper_bgcolor="white",
    )
    return fig


# ---------------------------------------------------------------------------
# Fitted vs actual
# ---------------------------------------------------------------------------

def fitted_vs_actual(fv_df: pd.DataFrame, model_id: str = "") -> go.Figure:
    """Scatter of fitted vs actual values, coloured by region."""
    fig = px.scatter(
        fv_df,
        x="actual",
        y="fitted_value",
        color="region",
        hover_data=["region", "year"],
        labels={"actual": "Observed", "fitted_value": "Fitted"},
        title=f"Fitted vs observed{' — ' + model_id if model_id else ''}",
    )
    # 45° reference line
    lo = min(fv_df["actual"].min(), fv_df["fitted_value"].min())
    hi = max(fv_df["actual"].max(), fv_df["fitted_value"].max())
    fig.add_trace(
        go.Scatter(x=[lo, hi], y=[lo, hi], mode="lines",
                   line=dict(color="#888", dash="dash"), showlegend=False,
                   hoverinfo="skip")
    )
    fig.update_layout(margin=dict(l=20, r=20, t=40, b=20), plot_bgcolor="white")
    return fig


# ---------------------------------------------------------------------------
# Fitted values time series
# ---------------------------------------------------------------------------

def fitted_time_series(fv_df: pd.DataFrame, actual: bool = True) -> go.Figure:
    """Line chart of fitted (and optionally actual) values over time by region."""
    fig = go.Figure()
    for region, grp in fv_df.groupby("region"):
        grp = grp.sort_values("year")
        fig.add_trace(go.Scatter(
            x=grp["year"], y=grp["fitted_value"],
            mode="lines", name=region, legendgroup=region,
            line=dict(width=1.5),
            hovertemplate=f"{region}<br>Year: %{{x}}<br>Fitted: %{{y:.3f}}<extra></extra>",
        ))
        if actual and "actual" in grp.columns:
            fig.add_trace(go.Scatter(
                x=grp["year"], y=grp["actual"],
                mode="markers", name=f"{region} (obs)", legendgroup=region,
                marker=dict(size=5, opacity=0.6),
                showlegend=False,
                hovertemplate=f"{region}<br>Year: %{{x}}<br>Observed: %{{y:.3f}}<extra></extra>",
            ))
    fig.update_layout(
        title="Fitted values over time",
        xaxis_title="Year", yaxis_title="Value",
        margin=dict(l=20, r=20, t=40, b=20),
        plot_bgcolor="white",
    )
    return fig


# ---------------------------------------------------------------------------
# Correlation heatmap
# ---------------------------------------------------------------------------

def correlation_heatmap(cor_df: pd.DataFrame, title: str = "Correlation matrix") -> go.Figure:
    """Heatmap from wide-format correlation parquet (variable + predictor columns)."""
    labels = cor_df["variable"].tolist()
    matrix = cor_df.drop(columns=["variable"]).values.astype(float)
    fig = go.Figure(go.Heatmap(
        z=matrix, x=labels, y=labels,
        colorscale="RdBu", zmid=0, zmin=-1, zmax=1,
        colorbar=dict(title="r"),
        hovertemplate="Row: %{y}<br>Col: %{x}<br>r = %{z:.3f}<extra></extra>",
    ))
    fig.update_layout(
        title=title,
        margin=dict(l=20, r=20, t=40, b=20),
        height=max(350, 30 * len(labels)),
    )
    return fig


# ---------------------------------------------------------------------------
# Training data distributions
# ---------------------------------------------------------------------------

def variable_histogram(td_df: pd.DataFrame, column: str) -> go.Figure:
    fig = px.histogram(td_df, x=column, nbins=30, title=f"Distribution: {column}")
    fig.update_layout(margin=dict(l=20, r=20, t=40, b=20), plot_bgcolor="white")
    return fig


# ---------------------------------------------------------------------------
# Projection time series
# ---------------------------------------------------------------------------

def projection_time_series(
    proj_df: pd.DataFrame,
    y_col: str,
    title: str = "Projections",
    threshold: float | None = None,
) -> go.Figure:
    """Line chart for projection data; optional horizontal threshold line."""
    fig = go.Figure()
    group_col = "region" if "region" in proj_df.columns else None

    if group_col:
        for region, grp in proj_df.groupby(group_col):
            grp = grp.sort_values("year")
            fig.add_trace(go.Scatter(
                x=grp["year"], y=grp[y_col],
                mode="lines", name=region,
                hovertemplate=f"{region}<br>Year: %{{x}}<br>{y_col}: %{{y:.3f}}<extra></extra>",
            ))
    else:
        fig.add_trace(go.Scatter(
            x=proj_df["year"], y=proj_df[y_col],
            mode="lines", name=y_col,
        ))

    if threshold is not None:
        fig.add_hline(y=threshold, line_dash="dot", line_color="#e63946",
                      annotation_text=f"Threshold: {threshold:.2f}")

    fig.update_layout(
        title=title,
        xaxis_title="Year", yaxis_title=y_col,
        margin=dict(l=20, r=20, t=40, b=20),
        plot_bgcolor="white",
    )
    return fig
