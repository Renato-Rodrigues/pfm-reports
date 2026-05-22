"""Persistent sidebar: active model selector + model info card."""

from dash import dcc, html


def sidebar_layout() -> html.Div:
    return html.Div(
        [
            html.Label("Active model", className="sidebar-label"),
            dcc.Dropdown(
                id="dropdown-model",
                placeholder="Select a model…",
                clearable=False,
                className="sidebar-dropdown",
            ),
            html.Div(id="active-model-card"),
        ],
        className="sidebar-inner",
    )
