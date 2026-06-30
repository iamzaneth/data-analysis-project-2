from __future__ import annotations

import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import pandas as pd

from common import OUTPUT_DIR


REPORT_DIR = Path(__file__).resolve().parent / "reports"


def pct(value: float) -> str:
    return f"{value * 100:.2f}%"


def ensure_report_dir() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)


def plot_negative_review_feature_importance(feature_importance: pd.DataFrame) -> None:
    top_features = feature_importance.head(15).sort_values("importance")
    plt.figure(figsize=(10, 7))
    plt.barh(top_features["feature"], top_features["importance"], color="#2f6f73")
    plt.title("Top Random Forest Feature Importance")
    plt.xlabel("Importance")
    plt.tight_layout()
    plt.savefig(REPORT_DIR / "negative_review_feature_importance.png", dpi=160)
    plt.close()


def plot_confusion_matrix(confusion_matrix: list[list[int]]) -> None:
    cm = pd.DataFrame(
        confusion_matrix,
        index=["Actual non-negative", "Actual negative"],
        columns=["Predicted non-negative", "Predicted negative"],
    )
    plt.figure(figsize=(7, 5))
    plt.imshow(cm.values, cmap="Blues")
    plt.title("Negative Review Confusion Matrix")
    plt.xticks(range(len(cm.columns)), cm.columns, rotation=20, ha="right")
    plt.yticks(range(len(cm.index)), cm.index)
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            plt.text(j, i, f"{cm.iloc[i, j]:,}", ha="center", va="center", color="black")
    plt.tight_layout()
    plt.savefig(REPORT_DIR / "negative_review_confusion_matrix.png", dpi=160)
    plt.close()


def plot_seller_segment_summary(summary: pd.DataFrame) -> None:
    summary = summary.sort_values("gross_merchandise_value_sum", ascending=True)
    plt.figure(figsize=(9, 5))
    plt.barh(summary["segment_name"], summary["gross_merchandise_value_sum"], color="#7a5c2e")
    plt.title("Seller Segment GMV Contribution")
    plt.xlabel("Gross Merchandise Value")
    plt.tight_layout()
    plt.savefig(REPORT_DIR / "seller_segment_gmv.png", dpi=160)
    plt.close()


def plot_k_scores(k_scores: pd.DataFrame) -> None:
    plt.figure(figsize=(8, 5))
    plt.plot(k_scores["k"], k_scores["silhouette_score"], marker="o", color="#7b3f61")
    plt.title("K-Means Silhouette Score by k")
    plt.xlabel("k")
    plt.ylabel("Silhouette score")
    plt.xticks(k_scores["k"])
    plt.tight_layout()
    plt.savefig(REPORT_DIR / "seller_kmeans_silhouette.png", dpi=160)
    plt.close()


def write_report(
    negative_metrics: dict,
    feature_importance: pd.DataFrame,
    seller_metrics: dict,
    seller_summary: pd.DataFrame,
    k_scores: pd.DataFrame,
    k4_summary: pd.DataFrame,
) -> None:
    top_features = feature_importance.head(10)
    top_feature_lines = "\n".join(
        f"- `{row.feature}`: {row.importance:.4f}" for row in top_features.itertuples(index=False)
    )

    seller_lines = "\n".join(
        (
            f"- {row.segment_name}: {int(row.seller_count):,} sellers, "
            f"GMV {row.gross_merchandise_value_sum:,.2f}, "
            f"avg review {row.avg_review_score_mean:.2f}, "
            f"avg late rate {row.late_rate_pct_mean:.2f}%"
        )
        for row in seller_summary.itertuples(index=False)
    )
    k_score_lines = "\n".join(
        f"- k={int(row.k)}: silhouette {row.silhouette_score:.4f}, inertia {row.inertia:,.2f}"
        for row in k_scores.itertuples(index=False)
    )
    k4_lines = ""
    if not k4_summary.empty:
        k4_lines = "\n".join(
            (
                f"- {row.exploratory_segment_name}: {int(row.seller_count):,} sellers, "
                f"GMV {row.gross_merchandise_value_sum:,.2f}, "
                f"avg review {row.avg_review_score_mean:.2f}, "
                f"avg late rate {row.late_rate_pct_mean:.2f}%, "
                f"low review rate {row.low_review_rate_pct_mean:.2f}%"
            )
            for row in k4_summary.itertuples(index=False)
        )

    cm = negative_metrics["confusion_matrix"]
    true_negative, false_positive = cm[0]
    false_negative, true_positive = cm[1]

    report = f"""# ML Result Analysis

## 1. Random Forest: Negative Review Prediction

Model objective: predict whether an order/review is likely to become a negative review, defined as review score <= 2.

### Dataset

- Rows used: {negative_metrics["row_count"]:,}
- Negative review rate: {pct(negative_metrics["negative_review_rate"])}

### Model Performance

- Accuracy: {pct(negative_metrics["accuracy"])}
- Precision: {pct(negative_metrics["precision"])}
- Recall: {pct(negative_metrics["recall"])}
- F1-score: {pct(negative_metrics["f1"])}
- ROC-AUC: {pct(negative_metrics["roc_auc"])}

Confusion matrix:

| | Predicted non-negative | Predicted negative |
|---|---:|---:|
| Actual non-negative | {true_negative:,} | {false_positive:,} |
| Actual negative | {false_negative:,} | {true_positive:,} |

### Interpretation

The model has moderate discrimination power with ROC-AUC around {pct(negative_metrics["roc_auc"])}. Recall for negative reviews is {pct(negative_metrics["recall"])}, meaning it captures a meaningful but incomplete share of bad-review cases. Precision is still limited because negative reviews remain a minority class, so some predicted risky orders are false alarms.

For business use, this model is more suitable as an early warning/risk ranking tool than as a strict automatic decision system.

### Top Drivers

{top_feature_lines}

The strongest signals are related to delivery delay and order status. This supports the BSC narrative that customer dissatisfaction is closely connected to internal process and logistics performance.

Recommended actions:

- Prioritize orders with late delivery or high delay days for proactive support.
- Monitor sellers/categories that repeatedly produce delayed or high-risk orders.
- Use the prediction probability as a risk score, not just a binary label.

## 2. K-Means: Seller Segmentation

Model objective: group sellers by business value and operational health.

### Dataset

- Sellers used: {seller_metrics["row_count"]:,}
- Selected k: {seller_metrics["selected_k"]}

### k Selection

{k_score_lines}

k = {seller_metrics["selected_k"]} is used as the main model because it has the highest silhouette score. Higher k values reduce inertia, but their silhouette scores are lower, so the clusters become less clean.

### Segment Summary

{seller_lines}

### Interpretation

K-Means selected k = {seller_metrics["selected_k"]} based on silhouette score. The current result separates sellers mainly by scale/value. The high-GMV segment contributes most of the marketplace value, but its review and late-delivery signals should still be watched, so the segment should be treated as a management watchlist rather than a removal list.

Recommended actions:

- High-Value Watchlist Sellers: keep and prioritize because they drive high GMV, but monitor late delivery and low review signals.
- Emerging Sellers: lower GMV but relatively healthy profile; support them with exposure or seller development programs.
- For presentation, k = 4 can be used as an exploratory business view if the story needs more seller personas, but k = 2 is the cleanest separation according to the current silhouette score.

### Exploratory k = 4 View

{k4_lines if k4_lines else "- Not generated."}

This view is useful for business storytelling because it surfaces more seller personas, but it should be presented as exploratory because its silhouette score is lower than k = 2.

## Visuals

- `negative_review_feature_importance.png`
- `negative_review_confusion_matrix.png`
- `seller_segment_gmv.png`
- `seller_kmeans_silhouette.png`
"""
    (REPORT_DIR / "ml_result_analysis.md").write_text(report, encoding="utf-8")


def main() -> None:
    ensure_report_dir()

    negative_metrics = json.loads((OUTPUT_DIR / "negative_review_metrics.json").read_text(encoding="utf-8"))
    feature_importance = pd.read_csv(OUTPUT_DIR / "negative_review_feature_importance.csv")
    seller_metrics = json.loads((OUTPUT_DIR / "seller_segmentation_metrics.json").read_text(encoding="utf-8"))
    seller_summary = pd.read_csv(OUTPUT_DIR / "seller_segment_summary.csv")
    k_scores = pd.read_csv(OUTPUT_DIR / "seller_kmeans_k_scores.csv")

    plot_negative_review_feature_importance(feature_importance)
    plot_confusion_matrix(negative_metrics["confusion_matrix"])
    plot_seller_segment_summary(seller_summary)
    plot_k_scores(k_scores)
    k4_summary_path = OUTPUT_DIR / "seller_kmeans_k4_exploratory_summary.csv"
    k4_summary = pd.read_csv(k4_summary_path) if k4_summary_path.exists() else pd.DataFrame()
    write_report(negative_metrics, feature_importance, seller_metrics, seller_summary, k_scores, k4_summary)

    print(f"Wrote report files to {REPORT_DIR}")


if __name__ == "__main__":
    main()
