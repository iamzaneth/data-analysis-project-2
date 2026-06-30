# Olist Machine Learning Workflows

This folder contains the Machine Learning part of the Olist analysis project. The ML scripts read from the existing PostgreSQL DWH/Data Mart, train models, and export metrics/reports for presentation.

## Models

### 1. Random Forest: negative review prediction

Goal: predict whether an order/review is likely to become a negative review.

Current target definition:

```text
is_negative_review = 1 if review_score <= 2
is_negative_review = 0 if review_score >= 3
```

The model uses order-level features such as delivery delay, delivery duration, order status, order value, freight cost, payment type, product attributes, seller/customer state, and review month/year.

The feature set intentionally excludes overly noisy or misleading variables:

- `seller_city` and `customer_city` are excluded because they have too many distinct values.
- Redundant value features such as `total_item_value`, `avg_freight_value`, and `avg_payment_value` are excluded.
- Review-comment fields are excluded to avoid leakage or confusion.

### 2. K-Means: seller segmentation

Goal: group sellers by business scale, review quality, and operational health.

The main K-Means model tests `k = 2` to `k = 8` and selects the best `k` by silhouette score. Current main result uses `k = 2`:

- `High-Value Watchlist Sellers`
- `Emerging Sellers`

The script also exports an exploratory `k = 4` summary for richer business storytelling. This is not the main model because its silhouette score is lower than `k = 2`.

## Prerequisites

Install dependencies:

```powershell
pip install -r requirements.txt
```

Or use the project virtual environment if it already exists:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

The database must already contain the DWH/Data Mart tables used by the SQL files in `ml/sql/`.

Default database connection:

```text
host=localhost
port=5433
user=olist_user
password=olist_pass
dbname=olist_db
```

Override with environment variables when needed:

```powershell
$env:OLIST_DB_HOST = "localhost"
$env:OLIST_DB_PORT = "5433"
$env:OLIST_DB_USER = "olist_user"
$env:OLIST_DB_PASSWORD = "olist_pass"
$env:OLIST_DB_NAME = "olist_db"
```

## Run

From the project root:

```powershell
.\.venv\Scripts\python.exe ml\train_negative_review_random_forest.py
.\.venv\Scripts\python.exe ml\train_seller_segmentation_kmeans.py
.\.venv\Scripts\python.exe ml\generate_model_report.py
```

If you are not using the virtual environment:

```powershell
python ml\train_negative_review_random_forest.py
python ml\train_seller_segmentation_kmeans.py
python ml\generate_model_report.py
```

Recommended order:

1. Train Random Forest.
2. Train K-Means.
3. Generate report and charts.

## Outputs

Generated outputs:

```text
ml/outputs/negative_review_metrics.json
ml/outputs/negative_review_feature_importance.csv
ml/outputs/negative_review_predictions.csv
ml/outputs/seller_segmentation_metrics.json
ml/outputs/seller_segment_summary.csv
ml/outputs/seller_kmeans_k_scores.csv
ml/outputs/seller_kmeans_k4_exploratory_summary.csv
ml/outputs/seller_segments.csv
```

Generated reports and charts:

```text
ml/reports/ml_result_analysis.md
ml/reports/bao_cao_ml_tieng_viet.md
ml/reports/kich_ban_thuyet_trinh_mo_hinh_ml.md
ml/reports/negative_review_confusion_matrix.png
ml/reports/negative_review_feature_importance.png
ml/reports/seller_segment_gmv.png
ml/reports/seller_kmeans_silhouette.png
```

Saved model files:

```text
ml/models/negative_review_rf.joblib
ml/models/seller_kmeans.joblib
```

The model files and large row-level CSV outputs are ignored by Git. Summary metrics, reports, SQL files, and training scripts should be kept.

## Current Results

Random Forest with negative review defined as `review_score <= 2`:

```text
Accuracy: 84.72%
Precision: 48.30%
Recall: 57.05%
F1-score: 52.32%
ROC-AUC: 78.80%
```

K-Means:

```text
Selected k: 2
k=2 silhouette score: 0.3035
```

Main interpretation:

- Random Forest is suitable as a risk-scoring/early-warning model, not as an automatic final decision.
- K-Means `k=2` is the cleanest technical segmentation.
- K-Means `k=4` can be used only as an exploratory business view for richer seller personas.
