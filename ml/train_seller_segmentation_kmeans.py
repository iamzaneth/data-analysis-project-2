from __future__ import annotations

import json

import joblib
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.impute import SimpleImputer
from sklearn.metrics import silhouette_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer, StandardScaler

from common import MODEL_DIR, OUTPUT_DIR, ensure_ml_dirs, load_dataframe


ID_COLUMNS = ["seller_id", "seller_state", "seller_city"]

FEATURES = [
    "total_orders",
    "total_items",
    "total_revenue",
    "gross_merchandise_value",
    "total_freight_value",
    "avg_item_price",
    "avg_freight_value",
    "avg_review_score",
    "low_review_count",
    "late_orders",
    "low_review_rate_pct",
    "late_rate_pct",
    "freight_to_gmv_pct",
    "category_count",
    "active_month_count",
]

LOG_FEATURES = [
    "total_orders",
    "total_items",
    "total_revenue",
    "gross_merchandise_value",
    "total_freight_value",
    "low_review_count",
    "late_orders",
]


def log_transform_selected(values: np.ndarray) -> np.ndarray:
    transformed = values.copy()
    log_indexes = [FEATURES.index(col) for col in LOG_FEATURES]
    transformed[:, log_indexes] = np.log1p(np.clip(transformed[:, log_indexes], 0, None))
    return transformed


def build_preprocessor() -> Pipeline:
    return Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
            ("log_transform", FunctionTransformer(log_transform_selected, feature_names_out="one-to-one")),
            ("scaler", StandardScaler()),
        ]
    )


def choose_k(X_scaled: np.ndarray) -> tuple[int, pd.DataFrame]:
    rows = []
    max_k = min(8, len(X_scaled) - 1)
    for k in range(2, max_k + 1):
        model = KMeans(n_clusters=k, random_state=42, n_init=20)
        labels = model.fit_predict(X_scaled)
        rows.append(
            {
                "k": k,
                "inertia": float(model.inertia_),
                "silhouette_score": float(silhouette_score(X_scaled, labels)),
            }
        )
    scores = pd.DataFrame(rows)
    if scores.empty:
        return 1, scores
    best_k = int(scores.sort_values(["silhouette_score", "k"], ascending=[False, True]).iloc[0]["k"])
    return best_k, scores


def label_segments(summary: pd.DataFrame) -> dict[int, str]:
    labels: dict[int, str] = {}
    gmv_median = summary["gross_merchandise_value_mean"].median()
    review_median = summary["avg_review_score_mean"].median()
    late_median = summary["late_rate_pct_mean"].median()

    for row in summary.itertuples(index=False):
        cluster_id = int(row.cluster_id)
        high_gmv = row.gross_merchandise_value_mean >= gmv_median
        good_review = row.avg_review_score_mean >= review_median
        high_late = row.late_rate_pct_mean >= late_median

        if high_gmv and good_review and not high_late:
            labels[cluster_id] = "Star Sellers"
        elif high_gmv and (high_late or not good_review):
            labels[cluster_id] = "High-Value Watchlist Sellers"
        elif (not high_gmv) and good_review and not high_late:
            labels[cluster_id] = "Emerging Sellers"
        else:
            labels[cluster_id] = "Low-Value Risk Sellers"
    return labels


def label_k4_exploratory(summary: pd.DataFrame) -> dict[int, str]:
    labels: dict[int, str] = {}

    high_value_id = int(summary.sort_values("gross_merchandise_value_mean", ascending=False).iloc[0]["cluster_id"])
    problem_id = int(
        summary.assign(
            risk_score=summary["late_rate_pct_mean"] + summary["low_review_rate_pct_mean"] - summary["avg_review_score_mean"]
        )
        .sort_values("risk_score", ascending=False)
        .iloc[0]["cluster_id"]
    )
    healthy_id = int(
        summary.assign(
            health_score=summary["avg_review_score_mean"] - summary["late_rate_pct_mean"] - summary["low_review_rate_pct_mean"]
        )
        .sort_values("health_score", ascending=False)
        .iloc[0]["cluster_id"]
    )

    for cluster_id in summary["cluster_id"]:
        cluster_id = int(cluster_id)
        if cluster_id == high_value_id:
            labels[cluster_id] = "High-Value Core Sellers"
        elif cluster_id == problem_id:
            labels[cluster_id] = "Problem Sellers"
        elif cluster_id == healthy_id:
            labels[cluster_id] = "Healthy Emerging Sellers"
        else:
            labels[cluster_id] = "Growth Sellers"

    return labels


def summarize_clusters(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.groupby("cluster_id")
        .agg(
            seller_count=("seller_id", "count"),
            total_orders_sum=("total_orders", "sum"),
            gross_merchandise_value_sum=("gross_merchandise_value", "sum"),
            gross_merchandise_value_mean=("gross_merchandise_value", "mean"),
            avg_review_score_mean=("avg_review_score", "mean"),
            late_rate_pct_mean=("late_rate_pct", "mean"),
            low_review_rate_pct_mean=("low_review_rate_pct", "mean"),
            freight_to_gmv_pct_mean=("freight_to_gmv_pct", "mean"),
        )
        .reset_index()
    )


def main() -> None:
    ensure_ml_dirs()
    df = load_dataframe("seller_segmentation_features.sql")
    df = df.dropna(subset=["seller_id"]).copy()

    X = df[FEATURES].replace([np.inf, -np.inf], np.nan)
    preprocessor = build_preprocessor()
    X_scaled = preprocessor.fit_transform(X)

    best_k, k_scores = choose_k(X_scaled)
    if best_k < 2:
        raise ValueError("Need at least 2 eligible sellers for K-Means.")

    model = KMeans(n_clusters=best_k, random_state=42, n_init=20)
    df["cluster_id"] = model.fit_predict(X_scaled)

    summary = summarize_clusters(df)
    segment_labels = label_segments(summary)
    df["segment_name"] = df["cluster_id"].map(segment_labels)
    summary["segment_name"] = summary["cluster_id"].map(segment_labels)

    k4_summary = pd.DataFrame()
    if len(df) > 4:
        k4_df = df.drop(columns=["cluster_id", "segment_name"], errors="ignore").copy()
        k4_model = KMeans(n_clusters=4, random_state=42, n_init=20)
        k4_df["cluster_id"] = k4_model.fit_predict(X_scaled)
        k4_summary = summarize_clusters(k4_df)
        k4_summary["exploratory_segment_name"] = k4_summary["cluster_id"].map(label_k4_exploratory(k4_summary))

    metrics = {
        "row_count": int(len(df)),
        "selected_k": int(best_k),
        "k_scores": k_scores.to_dict(orient="records"),
        "segment_counts": df["segment_name"].value_counts().to_dict(),
    }

    joblib.dump({"preprocessor": preprocessor, "model": model, "features": FEATURES}, MODEL_DIR / "seller_kmeans.joblib")
    df[ID_COLUMNS + FEATURES + ["cluster_id", "segment_name"]].to_csv(
        OUTPUT_DIR / "seller_segments.csv", index=False
    )
    summary.to_csv(OUTPUT_DIR / "seller_segment_summary.csv", index=False)
    k_scores.to_csv(OUTPUT_DIR / "seller_kmeans_k_scores.csv", index=False)
    k4_summary.to_csv(OUTPUT_DIR / "seller_kmeans_k4_exploratory_summary.csv", index=False)
    (OUTPUT_DIR / "seller_segmentation_metrics.json").write_text(
        json.dumps(metrics, indent=2), encoding="utf-8"
    )

    print(json.dumps(metrics, indent=2))
    print("\nSegment summary:")
    print(summary.to_string(index=False))


if __name__ == "__main__":
    main()
